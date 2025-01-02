import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Return a transaction hash and optionally a merkle proof, given a block height and a position in the block.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestIdFromPos extends ElectrumRequest<dynamic, dynamic> {
  ElectrumRequestIdFromPos(
      {required this.height, required this.txPos, this.merkle = false});

  /// The main chain block height, a non-negative integer.
  final int height;

  /// A zero-based index of the transaction in the given block, an integer.
  final int txPos;

  /// Whether a merkle proof should also be returned, a boolean.
  final bool merkle;

  /// blockchain.transaction.id_from_pos
  @override
  String get method => ElectrumRequestMethods.idFromPos.method;

  @override
  List toJson() {
    return [height, txPos, merkle];
  }

  /// If merkle is false, the transaction hash as a hexadecimal string. If true, a dictionary
  @override
  dynamic onResonse(result) {
    return result;
  }
}
