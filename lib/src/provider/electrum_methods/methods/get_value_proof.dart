import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Returns a name resolution proof, suitable for low-latency (single round-trip) resolution.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestGetValueProof
    extends ElectrumRequest<Map<String, dynamic>, dynamic> {
  ElectrumRequestGetValueProof(
      {required this.scriptHash, required this.cpHeight});

  /// Script hash of the name being resolved.
  final String scriptHash;

  /// Checkpoint height.
  final int cpHeight;

  /// blockchain.name.get_value_proof
  @override
  String get method => ElectrumRequestMethods.getValueProof.method;

  @override
  List toJson() {
    return [scriptHash, cpHeight];
  }

  /// A dictionary with transaction and proof data for each transaction associated with the name,
  /// from the most recent update back to either the registration transaction or a
  /// checkpointed transaction (whichever is later).
  @override
  Map<String, dynamic> onResonse(result) {
    return Map<String, dynamic>.from(result);
  }
}
