import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

/// Return a concatenated chunk of block headers from the main chain.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumBlockHeaders
    extends ElectrumRequest<Map<String, dynamic>, Map<String, dynamic>> {
  ElectrumBlockHeaders(
      {required this.startHeight, required this.count, required this.cpHeight});

  /// The height of the first header requested, a non-negative integer.
  final int startHeight;

  /// The number of headers requested, a non-negative integer.
  final int count;

  /// Checkpoint height, a non-negative integer. Ignored if zero
  final int cpHeight;

  /// blockchain.block.headers
  @override
  String get method => ElectrumRequestMethods.blockHeaders.method;

  @override
  List toJson() {
    return [startHeight, count, cpHeight];
  }

  /// A dictionary
  @override
  Map<String, dynamic> onResonse(result) {
    return result;
  }
}
