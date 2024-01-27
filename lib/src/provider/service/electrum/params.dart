import 'package:blockchain_utils/blockchain_utils.dart';

/// Abstract class representing parameters for Electrum requests.
abstract class ElectrumRequestParams {
  abstract final String method;
  List<dynamic> toJson();
}

/// Represents details of an Electrum request, including id, method, and parameters.
class ElectrumRequestDetails {
  const ElectrumRequestDetails({
    required this.id,
    required this.method,
    required this.params,
  });

  final int id;

  final String method;

  final Map<String, dynamic> params;

  List<int> toTCPParams() {
    final param = "${StringUtils.fromJson(params)}\n";
    return StringUtils.encode(param);
  }

  List<int> toWebSocketParams() {
    return StringUtils.encode(StringUtils.fromJson(params));
  }
}

/// Abstract class representing an Electrum request with generic result and response types.
abstract class ElectrumRequest<RESULT, RESPONSE>
    implements ElectrumRequestParams {
  String? get validate => null;

  RESULT onResonse(RESPONSE result) {
    return result as RESULT;
  }

  ElectrumRequestDetails toRequest(int requestId) {
    List<dynamic> inJson = toJson();
    inJson.removeWhere((v) => v == null);
    final params = {
      "jsonrpc": "2.0",
      "method": method,
      "params": inJson,
      "id": requestId,
    };
    return ElectrumRequestDetails(
        id: requestId, params: params, method: method);
  }
}
