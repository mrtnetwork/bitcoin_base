import 'dart:convert';

import 'package:bitcoin_base/bitcoin_base.dart' show ApiService;
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:http/http.dart' as http;

class ApiProviderException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? responseData;
  const ApiProviderException(this.message,
      [this.statusCode, this.responseData]);
  @override
  String toString() {
    return "status: $statusCode $message ${responseData ?? ""}";
  }
}

class BitcoinApiService implements ApiService {
  BitcoinApiService([http.Client? client]) : _client = client ?? http.Client();
  final http.Client _client;
  @override
  Future<T> get<T>(String url) async {
    final response = await _client.get(Uri.parse(url));
    return _readResponse<T>(response);
  }

  @override
  Future<T> post<T>(String url,
      {Map<String, String> headers = const {"Content-Type": "application/json"},
      Object? body}) async {
    final response =
        await _client.post(Uri.parse(url), headers: headers, body: body);
    return _readResponse<T>(response);
  }

  T _readResponse<T>(http.Response response) {
    final String toString = _readBody(response);
    switch (T) {
      case String:
        return toString as T;
      case List:
      case Map:
        return jsonDecode(toString) as T;
      default:
        try {
          return jsonDecode(toString) as T;
        } catch (e) {
          throw const ApiProviderException("invalid request");
        }
    }
  }

  String _readBody(http.Response response) {
    _readErr(response);
    return StringUtils.decode(response.bodyBytes);
  }

  void _readErr(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) return;
    String toString = StringUtils.decode(response.bodyBytes);
    Map<String, dynamic>? errorResult;
    try {
      if (toString.isNotEmpty) {
        errorResult = StringUtils.toJson(toString);
      }
      // ignore: empty_catches
    } catch (e) {}
    toString = toString.isEmpty ? "request_error" : toString;
    throw ApiProviderException(toString, response.statusCode, errorResult);
  }
}
