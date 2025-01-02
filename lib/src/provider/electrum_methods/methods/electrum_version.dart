import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Identify the client to the server and negotiate the protocol version. Only the first server.version() message is accepted.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestVersion
    extends ElectrumRequest<List<String>, List<dynamic>> {
  ElectrumRequestVersion(
      {required this.clientName, required this.protocolVersion});

  /// A string identifying the connecting client software.
  final String clientName;

  /// An array [protocol_min, protocol_max], each of which is a string.
  final List<String> protocolVersion;

  /// blockchain.version
  @override
  String get method => ElectrumRequestMethods.version.method;

  @override
  List toJson() {
    return [clientName, protocolVersion];
  }

  /// identifying the server and the protocol version that will be used for future communication.
  @override
  List<String> onResonse(result) {
    return List<String>.from(result);
  }
}
