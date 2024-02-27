import 'package:bitcoin_base/src/provider/api_provider.dart';
import 'dart:async';

import 'package:blockchain_utils/exception/exceptions.dart';

class ElectrumApiProvider {
  final BitcoinBaseElectrumRPCService rpc;
  ElectrumApiProvider(this.rpc);
  int _id = 0;

  /// Sends a request to the Electrum server using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  Future<T> request<T>(ElectrumRequest<T, dynamic> request,
      [Duration? timeout]) async {
    final id = ++_id;
    final params = request.toRequest(id);
    final data = await rpc.call(params, timeout);
    return request.onResonse(_findResult(data, params));
  }

  dynamic _findResult(
      Map<String, dynamic> data, ElectrumRequestDetails request) {
    if (data["error"] != null) {
      final code =
          int.tryParse(((data["error"]?['code']?.toString()) ?? "0")) ?? 0;
      final message = data["error"]?['message'] ?? "";
      throw RPCError(
        errorCode: code,
        message: message,
        data: data["error"]?["data"],
        request: data["request"] ?? request.params,
      );
    }

    return data["result"];
  }
}
