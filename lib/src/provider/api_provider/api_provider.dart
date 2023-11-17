import 'dart:convert';
import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:bitcoin_base/src/provider/service/service.dart';
import 'package:bitcoin_base/src/models/network.dart';

class ApiProvider {
  ApiProvider(
      {required this.api, Map<String, String>? header, required this.service})
      : _header = header ?? {"Content-Type": "application/json"};
  factory ApiProvider.fromMempool(
      BitcoinNetwork networkInfo, ApiService service,
      {Map<String, String>? header}) {
    final api = APIConfig.mempool(networkInfo);
    return ApiProvider(api: api, header: header, service: service);
  }
  factory ApiProvider.fromBlocCypher(
      BitcoinNetwork networkInfo, ApiService service,
      {Map<String, String>? header}) {
    final api = APIConfig.fromBlockCypher(networkInfo);
    return ApiProvider(api: api, header: header, service: service);
  }
  final APIConfig api;
  final ApiService service;
  // final http.Client client;
  final Map<String, String> _header;

  // void _getException(int status, List<int> data) {
  //   if (data.isEmpty) throw ApiProviderException(status: status);
  //   String message = utf8.decode(data);
  //   Map<String, dynamic>? error;
  //   try {
  //     error = json.decode(message);

  //     /// ignore: empty_catches
  //   } catch (e) {}
  //   throw ApiProviderException(
  //       status: status, message: error != null ? null : message, data: error);
  // }

  Future<T> _getRequest<T>(String url) async {
    final response = await service.get<T>(url);
    return response;
    // if (response.statusCode != 200) {
    //   _getException(response.statusCode, response.bodyBytes);
    // }
    // switch (T) {
    //   case String:
    //     return utf8.decode(response.bodyBytes) as T;
    //   default:
    //     return json.decode(utf8.decode(response.bodyBytes)) as T;
    // }
  }

  Future<T> _postReqiest<T>(String url, Object? data) async {
    final response = await service.post<T>(url, body: data, headers: _header);
    return response;
    // if (response.statusCode != 200) {
    //   _getException(response.statusCode, response.bodyBytes);
    // }
    // switch (T) {
    //   case String:
    //     return utf8.decode(response.bodyBytes) as T;
    //   default:
    //     return json.decode(utf8.decode(response.bodyBytes)) as T;
    // }
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
