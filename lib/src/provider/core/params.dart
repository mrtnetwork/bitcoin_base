import 'package:blockchain_utils/blockchain_utils.dart';

/// Represents details of an Electrum request, including id, method, and parameters.
class ElectrumRequestDetails extends BaseServiceRequestParams {
  const ElectrumRequestDetails(
      {required super.requestID,
      this.path,
      required this.method,
      required this.params,
      required super.type,
      super.headers = ServiceConst.defaultPostHeaders});

  final String? path;
  final String method;
  final Map<String, dynamic> params;

  List<int> toTCPParams() {
    final param = '${StringUtils.fromJson(params)}\n';
    return StringUtils.encode(param);
  }

  List<int> toWebSocketParams() {
    return StringUtils.encode(StringUtils.fromJson(params));
  }

  @override
  List<int>? body() {
    return toWebSocketParams();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'body': params,
    };
  }

  @override
  Uri toUri(String uri) {
    return Uri.parse(uri);
  }
}

/// Abstract class representing an Electrum request with generic result and response types.
abstract class ElectrumRequest<RESULT, RESPONSE>
    extends BaseServiceRequest<RESULT, RESPONSE, ElectrumRequestDetails> {
  abstract final String method;
  List<dynamic> toJson();

  @override
  ElectrumRequestDetails buildRequest(int requestID) {
    final inJson = toJson();
    inJson.removeWhere((v) => v == null);
    final params = ServiceProviderUtils.buildJsonRPCParams(
        requestId: requestID, method: method, params: inJson);
    return ElectrumRequestDetails(
        requestID: requestID,
        params: params,
        method: method,
        type: RequestServiceType.post);
  }

  @override
  RequestServiceType get requestType => RequestServiceType.post;
}
