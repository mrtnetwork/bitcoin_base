import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Return the block header at the given height.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestBlockHeader extends ElectrumRequest<dynamic, dynamic> {
  ElectrumRequestBlockHeader(
      {required this.startHeight, required this.cpHeight});
  final int startHeight;
  final int cpHeight;

  /// blockchain.block.header
  @override
  String get method => ElectrumRequestMethods.blockHeader.method;

  @override
  List toJson() {
    return [startHeight, cpHeight];
  }

  /// If cp_height is zero, the raw block header as a hexadecimal string.

  /// Otherwise a dictionary with the following keys.
  /// This provides a proof that the given header is present in the blockchain;
  /// presumably the client has the merkle root hard-coded as a checkpoint.
  @override
  dynamic onResonse(result) {
    return result;
  }
}
