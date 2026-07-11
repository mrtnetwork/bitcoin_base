import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:http/http.dart';

class BitcoindServiceProvider with BitcoinServiceProvider {
  final String url;
  final BasicAuth? auth;
  BitcoindServiceProvider(this.url, {this.auth});
  @override
  Future<BaseServiceResponse> doRequest(BitcoinRequestDetails params,
      {Duration? timeout}) async {
    final client = Client();
    final result = switch (params.requestMethod.isGet) {
      false => await client
          .post(params.encodeUrl(url),
              body: params.encodeBody(), headers: auth?.toHeaders())
          .timeout(timeout ?? const Duration(seconds: 60)),
      true => await client
          .get(params.encodeUrl(url), headers: auth?.toHeaders())
          .timeout(timeout ?? const Duration(seconds: 60)),
    };
    return params.toResponse(result.bodyBytes, statusCode: result.statusCode);
  }
}

class BasicAuth {
  final String user;
  final String password;
  BasicAuth({required this.user, required this.password});

  Map<String, String> toHeaders() {
    final credentials = StringUtils.decode(
        StringUtils.encode("$user:$password"),
        encoding: StringEncoding.base64);
    return {"Authorization": "Basic $credentials"};
  }
}
