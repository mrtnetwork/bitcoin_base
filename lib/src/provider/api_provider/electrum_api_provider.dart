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
    final error = data["error"];
    if (error != null) {
      final code = int.tryParse(error["code"]?.toString() ?? "");
      final message = error['message'] ?? "";
      throw RPCError(
          errorCode: code,
          message: message,
          request: data["request"] ?? request.params,
          details: error);
    }

    return data["result"];
  }
}
