import 'dart:convert';
import 'dart:typed_data';

import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/provider/block_cypher_models.dart';
import 'package:bitcoin_base/src/provider/fee_rate.dart';
import 'package:bitcoin_base/src/provider/mempol_models.dart';
import 'package:bitcoin_base/src/provider/provider.dart';
import 'package:bitcoin_base/src/provider/utxo_details.dart';
import 'package:http/http.dart' as http;

class ApiProviderException implements Exception {
  ApiProviderException({required this.status, this.message, this.data});
  final Map<String, dynamic>? data;
  final int status;
  final String? message;

  @override
  String toString() {
    return data?.toString() ?? message ?? "statusCode: $status";
  }
}

class ApiProvider {
  ApiProvider(
      {required this.api, Map<String, String>? header, http.Client? client})
      : _header = header ?? {"Content-Type": "application/json"},
        client = client ?? http.Client();
  factory ApiProvider.fromMempl(NetworkInfo networkInfo,
      {Map<String, String>? header, http.Client? client}) {
    final api = APIConfig.mempool(networkInfo);
    return ApiProvider(api: api, header: header, client: client);
  }
  factory ApiProvider.fromBlocCypher(NetworkInfo networkInfo,
      {Map<String, String>? header, http.Client? client}) {
    final api = APIConfig.fromBlockCypher(networkInfo);
    return ApiProvider(api: api, header: header, client: client);
  }
  final APIConfig api;
  final http.Client client;
  final Map<String, String> _header;

  void _getException(int status, Uint8List data) {
    if (data.isEmpty) throw ApiProviderException(status: status);
    String message = utf8.decode(data);
    Map<String, dynamic>? error;
    try {
      error = json.decode(message);
      // ignore: empty_catches
    } catch (e) {}
    throw ApiProviderException(
        status: status, message: error != null ? null : message, data: error);
  }

  Future<T> _getRequest<T>(String url) async {
    final response = await client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      _getException(response.statusCode, response.bodyBytes);
    }
    switch (T) {
      case String:
        return utf8.decode(response.bodyBytes) as T;
      default:
        return json.decode(utf8.decode(response.bodyBytes)) as T;
    }
  }

  Future<T> _postReqiest<T>(String url, Object? data) async {
    final response =
        await client.post(Uri.parse(url), body: data, headers: _header);
    if (response.statusCode != 200) {
      _getException(response.statusCode, response.bodyBytes);
    }
    switch (T) {
      case String:
        return utf8.decode(response.bodyBytes) as T;
      default:
        return json.decode(utf8.decode(response.bodyBytes)) as T;
    }
  }

  Future<Map<String, dynamic>> testmempool(List<dynamic> params) async {
    final Map<String, dynamic> data = {
      "jsonrpc": "2.0",
      "method": "testmempoolaccept",
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "params": params
    };
    final response = await _postReqiest<Map<String, dynamic>>(
        "https://btc.getblock.io/786c97b8-f53f-427b-80f7-9af7bd5bdb84/testnet/",
        json.encode(data));
    return response;
  }

  Future<List<UtxoWithOwner>> getAccountUtxo(UtxoOwnerDetails owner,
      {String Function(String)? tokenize}) async {
    final apiUrl = api.getUtxoUrl(owner.address.toAddress(api.network));
    final url = tokenize?.call(apiUrl) ?? apiUrl;
    final response = await _getRequest(url);
    switch (api.apiType) {
      case APIType.MempoolApi:
        final utxos =
            (response as List).map((e) => MempolUtxo.fromJson(e)).toList();
        return utxos.toUtxoWithOwnerList(owner);
      default:
        final blockCypherUtxo = BlockCypherUtxo.fromJson(response);
        return blockCypherUtxo.toUtxoWithOwner(owner);
    }
  }

  Future<String> sendRawTransaction(String txDigest,
      {String Function(String)? tokenize}) async {
    final apiUrl = api.sendTransaction;
    final url = tokenize?.call(apiUrl) ?? apiUrl;

    switch (api.apiType) {
      case APIType.MempoolApi:
        final response = await _postReqiest<String>(url, txDigest);
        return response;
      default:
        final Map<String, dynamic> digestData = {"tx": txDigest};
        final response = await _postReqiest<Map<String, dynamic>>(
            url, json.encode(digestData));
        final blockCypherUtxo = BlockCypherTransaction.fromJson(response);
        return blockCypherUtxo.hash;
    }
  }

  Future<BitcoinFeeRate> getNetworkFeeRate(
      {String Function(String)? tokenize}) async {
    final apiUrl = api.getFeeApiUrl();
    final url = tokenize?.call(apiUrl) ?? apiUrl;
    final response = await _getRequest<Map<String, dynamic>>(url);
    switch (api.apiType) {
      case APIType.MempoolApi:
        return BitcoinFeeRate.fromMempool(response);
      default:
        return BitcoinFeeRate.fromBlockCypher(response);
    }
  }

  Future<T> getTransaction<T>(String transactionId,
      {String Function(String)? tokenize}) async {
    final apiUrl = api.getTransactionUrl(transactionId);
    final url = tokenize?.call(apiUrl) ?? apiUrl;
    final response = await _getRequest<Map<String, dynamic>>(url);
    switch (api.apiType) {
      case APIType.MempoolApi:
        return MempoolTransaction.fromJson(response) as T;
      default:
        return BlockCypherTransaction.fromJson(response) as T;
    }
  }

  Future<List<T>> getAccountTransactions<T>(String address,
      {String Function(String)? tokenize}) async {
    final apiUrl = api.getTransactionsUrl(address);
    final url = tokenize?.call(apiUrl) ?? apiUrl;
    final response = await _getRequest(url);
    switch (api.apiType) {
      case APIType.MempoolApi:
        final transactions = (response as List)
            .map((e) => MempoolTransaction.fromJson(e) as T)
            .toList();
        return transactions;
      default:
        final transactions = (response as List)
            .map((e) => BlockCypherTransaction.fromJson(e) as T)
            .toList();
        return transactions;
    }
  }
}
