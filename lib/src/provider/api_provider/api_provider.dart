import 'dart:convert';
import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:bitcoin_base/src/provider/service/http/http_service.dart';
import 'package:bitcoin_base/src/models/network.dart';

class ApiProvider {
  ApiProvider(
      {required this.api, Map<String, String>? header, required this.service})
      : _header = header ?? {"Content-Type": "application/json"};
  factory ApiProvider.fromMempool(BasedUtxoNetwork network, ApiService service,
      {Map<String, String>? header}) {
    final api = APIConfig.mempool(network);
    return ApiProvider(api: api, header: header, service: service);
  }
  factory ApiProvider.fromBlocCypher(
      BasedUtxoNetwork network, ApiService service,
      {Map<String, String>? header}) {
    final api = APIConfig.fromBlockCypher(network);
    return ApiProvider(api: api, header: header, service: service);
  }
  final APIConfig api;
  final ApiService service;

  final Map<String, String> _header;

  Future<T> _getRequest<T>(String url) async {
    final response = await service.get<T>(url);
    return response;
  }

  Future<T> _postReqiest<T>(String url, Object? data) async {
    final response = await service.post<T>(url, body: data, headers: _header);
    return response;
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

  Future<List<UtxoWithAddress>> getAccountUtxo(UtxoAddressDetails owner,
      {String Function(String)? tokenize}) async {
    final apiUrl = api.getUtxoUrl(owner.address.toAddress(api.network));
    final url = tokenize?.call(apiUrl) ?? apiUrl;
    final response = await _getRequest(url);
    switch (api.apiType) {
      case APIType.mempool:
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
      case APIType.mempool:
        final response = await _postReqiest<String>(url, txDigest);
        return response;
      default:
        final Map<String, dynamic> digestData = {"tx": txDigest};
        final response = await _postReqiest<Map<String, dynamic>>(
            url, json.encode(digestData));
        BlockCypherTransaction? tr;
        if (response["tx"] != null) {
          tr = BlockCypherTransaction.fromJson(response["tx"]);
        }

        tr ??= BlockCypherTransaction.fromJson(response);
        return tr.hash;
    }
  }

  Future<BitcoinFeeRate> getNetworkFeeRate(
      {String Function(String)? tokenize}) async {
    final apiUrl = api.getFeeApiUrl();
    final url = tokenize?.call(apiUrl) ?? apiUrl;
    final response = await _getRequest<Map<String, dynamic>>(url);
    switch (api.apiType) {
      case APIType.mempool:
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
      case APIType.mempool:
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
      case APIType.mempool:
        final transactions = (response as List)
            .map((e) => MempoolTransaction.fromJson(e) as T)
            .toList();
        return transactions;
      default:
        if (response is Map) {
          if (response.containsKey("txs")) {
            final transactions = (response["txs"] as List)
                .map((e) => BlockCypherTransaction.fromJson(e) as T)
                .toList();
            return transactions;
          }
          return [];
        }
        final transactions = (response as List)
            .map((e) => BlockCypherTransaction.fromJson(e) as T)
            .toList();
        return transactions;
    }
  }
}
