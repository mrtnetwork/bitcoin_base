import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// Helps setting up appropriate sequence. Used to provide the sequence to transaction inputs and to scripts.
///
/// [value] The value of the block height or the 512 seconds increments
/// [seqType] Specifies the type of sequence (.typeRelativeTimelock | .typeAbsoluteTimelock | .typeReplaceByFee
/// [isTypeBlock] If type is .typeRelativeTimelock then this specifies its type (block height or 512 secs increments)
class Sequence {
  Sequence({
    required this.seqType,
    required this.value,
    this.isTypeBlock = true,
  }) {
    if (seqType == BitcoinOpCodeConst.typeRelativeTimelock &&
        (value < 1 || value > BinaryOps.mask16)) {
      throw const DartBitcoinPluginException(
        'Sequence should be between 1 and 65535',
      );
    }
  }
  final int seqType;
  final int value;
  final bool isTypeBlock;

  /// Serializes the relative sequence as required in a transaction
  List<int> forInputSequence() {
    if (seqType == BitcoinOpCodeConst.typeAbsoluteTimelock) {
      return List<int>.from(BitcoinOpCodeConst.absoluteTimelockSequence);
    }

    if (seqType == BitcoinOpCodeConst.typeReplaceByFee) {
      return List<int>.from(BitcoinOpCodeConst.replaceByFeeSequence);
    }
    if (seqType == BitcoinOpCodeConst.typeRelativeTimelock) {
      int seq = 0;
      if (!isTypeBlock) {
        seq |= 1 << 22;
      }
      seq |= value;
      return seq.toU32LeBytes();
    }

    throw const DartBitcoinPluginException('Invalid seqType');
  }

  /// Returns the appropriate integer for a script; e.g. for relative timelocks
  int forScript() {
    if (seqType == BitcoinOpCodeConst.typeReplaceByFee) {
      throw const DartBitcoinPluginException(
        'RBF is not to be included in a script.',
      );
    }
    var scriptIntiger = value;
    if (seqType == BitcoinOpCodeConst.typeRelativeTimelock && !isTypeBlock) {
      scriptIntiger |= 1 << 22;
    }
    return scriptIntiger;
  }

  @override
  String toString() {
    return 'Sequence{seqType: $seqType, value: $value, isTypeBlock: $isTypeBlock}';
  }
}
