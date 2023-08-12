import 'dart:convert';
import 'utxo.dart';
import 'package:http/http.dart' as http;

class RPCError implements Exception {
  const RPCError(this.errorCode, this.message, this.data,
      {required this.request});

  final int errorCode;
  final String message;
  final dynamic data;
  final Map<String, dynamic> request;

  @override
  String toString() {
    return 'RPCError: got code $errorCode with msg "$message".';
  }
}

Map<String, dynamic> parseError(
    Map<String, dynamic> data, Map<String, dynamic> request) {
  final error = data['error'];
  if (error == null) return data;
  final code = (error['code'] ?? 0);
  final message = error['message'];
  final errorData = error['data'];
  throw RPCError(code, message, errorData, request: request);
}

class BTCRpcHelper {
  BTCRpcHelper(

      ///The link is for testing, it might not work, please use your RPC service
      {this.url =
          "https://serene-wild-dew.btc-testnet.discover.quiknode.pro/33a88cd7b9e1515949682b452f10c134ae4c2959/",
      Map<String, String>? header})
      : _header = header ??
            {
              'Content-Type': 'application/json',
              'x-api-key': "0fd2f4ca-25ac-4e19-a6c2-e66696ba4c8b"
            };
  final String url;
  final Map<String, String> _header;

  int _currentRequestId = 1;

  Future<T?> call<T>(
    String function, [
    List<dynamic>? params,
  ]) async {
    http.Client client = http.Client();
    try {
      params ??= [];
      final payload = {
        'jsonrpc': '2.0',
        'method': function,
        'params': params,
        'id': _currentRequestId++,
      };

      final response = await client
          .post(
            Uri.parse(url),
            headers: _header,
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 30));
      final data = parseError(json.decode(response.body), payload);

      final result = data['result'];

      return result;
    } finally {
      client.close();
    }
  }

  Future<BigInt> getSmartEstimate() async {
    final data = await call("estimatesmartfee", [2, "CONSERVATIVE"]);
    return priceToBtcUnit(data['feerate']);
  }

  Future<String> sendRawTransaction(String txDigit) async {
    final data = await call<String>("sendrawtransaction", [txDigit]);
    return data!;
  }

  ///This method is for testing, it may not work, please use your RPC service
  Future<List<UTXO>> getUtxo(String address,
      {String? url,
      Map<String, String> header = const {
        'Content-Type': 'application/json',
        'api-key': "dc0cdbc2-d3fc-4ae8-ae45-0a44bc28b5f9"
      }}) async {
    http.Client client = http.Client();
    try {
      String u =
          url ?? "https://btcbook-testnet.nownodes.io/api/v2/utxo/$address";

      final response = await client
          .get(
            Uri.parse(u),
            headers: header,
          )
          .timeout(const Duration(seconds: 30));
      final data = json.decode(response.body) as List<dynamic>;
      return data.map((e) => UTXO.fromJson(e)).toList();
    } finally {
      client.close();
    }
  }
}

/// This converter is not accurate
BigInt priceToBtcUnit(double price, {double decimal = 1e8}) {
  final dec = price * decimal;
  return BigInt.from(dec);
}
