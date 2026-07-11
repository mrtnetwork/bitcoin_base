/// Simple example how to send request to electurm  with tcp

import 'dart:async';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:http/http.dart';

class HttpServiceProvider with BitcoinServiceProvider {
  final String url;
  const HttpServiceProvider(this.url);
  HttpServiceProvider.mempoolTestnet() : url = BtcApiConst.mempoolBaseURL;
  @override
  Future<BaseServiceResponse> doRequest(BitcoinRequestDetails params,
      {Duration? timeout}) async {
    final client = Client();
    try {
      final uri = params.encodeUrl(url);
      final result = await switch (params.requestMethod.isGet) {
        false =>
          client.post(uri, body: params.encodeBody(), headers: params.headers),
        true => client.get(uri, headers: params.headers),
      };
      return params.toResponse(result.bodyBytes, statusCode: result.statusCode);
    } finally {
      client.close();
    }
  }
}
