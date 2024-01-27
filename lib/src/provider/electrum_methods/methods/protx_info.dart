import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

/// Returns detailed information about a deterministic masternode.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumProtXInfo extends ElectrumRequest<Map<String, dynamic>, dynamic> {
  ElectrumProtXInfo({required this.protxHash});

  /// The hash of the initial ProRegTx
  final String protxHash;

  /// protx.info
  @override
  String get method => ElectrumRequestMethods.protxInfo.method;

  @override
  List toJson() {
    return [protxHash];
  }

  /// A dictionary with detailed deterministic masternode data
  @override
  Map<String, dynamic> onResonse(result) {
    return Map<String, dynamic>.from(result);
  }
}
