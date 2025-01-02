import 'package:bitcoin_base/src/provider/core/params.dart';
import 'package:bitcoin_base/src/provider/services/electrum.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'dart:async';

class ElectrumProvider extends BaseProvider<ElectrumRequestDetails> {
  final ElectrumServiceProvider rpc;
  ElectrumProvider(this.rpc);

  /// The unique identifier for each JSON-RPC request.
  int _id = 0;

  /// Sends a request to the Electrum server using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  @override
  Future<RESULT> request<RESULT, SERVICERESPONSE>(
      BaseServiceRequest<RESULT, SERVICERESPONSE, ElectrumRequestDetails>
          request,
      {Duration? timeout}) async {
    final r = await requestDynamic(request, timeout: timeout);
    return request.onResonse(r);
  }

  /// Sends a request to the Electrum server using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  @override
  Future<SERVICERESPONSE> requestDynamic<RESULT, SERVICERESPONSE>(
      BaseServiceRequest<RESULT, SERVICERESPONSE, ElectrumRequestDetails>
          request,
      {Duration? timeout}) async {
    final params = request.buildRequest(_id++);
    final response =
        await rpc.doRequest<Map<String, dynamic>>(params, timeout: timeout);
    return _findResult(params: params, response: response);
  }

  SERVICERESPONSE _findResult<SERVICERESPONSE>(
      {required BaseServiceResponse<Map<String, dynamic>> response,
      required ElectrumRequestDetails params}) {
    final data = response.getResult(params);
    final error = data['error'];
    if (error != null) {
      final errorJson = StringUtils.tryToJson<Map<String, dynamic>>(error);
      final code = IntUtils.tryParse(errorJson?['code']);
      final message = errorJson?['message']?.toString();
      throw RPCError(
          errorCode: code,
          message: message ?? error.toString(),
          request: params.toJson(),
          details: errorJson);
    }
    return ServiceProviderUtils.parseResponse(
        object: data['result'], params: params);
  }
}
