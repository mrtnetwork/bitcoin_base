import 'dart:typed_data';

import 'package:bitcoin_base/src/bitcoin/constant/constant.dart';

/// Helps setting up appropriate sequence. Used to provide the sequence to transaction inputs and to scripts.
///
/// [value] The value of the block height or the 512 seconds increments
/// [seqType] Specifies the type of sequence (TYPE_RELATIVE_TIMELOCK | TYPE_ABSOLUTE_TIMELOCK | TYPE_REPLACE_BY_FEE
/// [isTypeBlock] If type is TYPE_RELATIVE_TIMELOCK then this specifies its type (block height or 512 secs increments)
class Sequence {
  Sequence(
      {required this.seqType, required this.value, this.isTypeBlock = true}) {
    if (seqType == TYPE_RELATIVE_TIMELOCK && (value < 1 || value > 0xffff)) {
      throw ArgumentError('Sequence should be between 1 and 65535');
    }
  }
  final int seqType;
  final int value;
  final bool isTypeBlock;

  /// Serializes the relative sequence as required in a transaction
  Uint8List forInputSequence() {
    if (seqType == TYPE_ABSOLUTE_TIMELOCK) {
      return Uint8List.fromList(ABSOLUTE_TIMELOCK_SEQUENCE);
    }

    if (seqType == TYPE_REPLACE_BY_FEE) {
      return Uint8List.fromList(REPLACE_BY_FEE_SEQUENCE);
    }
    if (seqType == TYPE_RELATIVE_TIMELOCK) {
      int seq = 0;
      if (!isTypeBlock) {
        seq |= 1 << 22;
      }
      seq |= value;
      return Uint8List.fromList([
        seq & 0xFF,
        (seq >> 8) & 0xFF,
        (seq >> 16) & 0xFF,
        (seq >> 24) & 0xFF,
      ]);
    }

    throw ArgumentError("Invalid seqType");
  }

  /// Returns the appropriate integer for a script; e.g. for relative timelocks
  int forScript() {
    if (seqType == TYPE_REPLACE_BY_FEE) {
      throw const FormatException("RBF is not to be included in a script.");
    }
    int scriptIntiger = value;
    if (seqType == TYPE_RELATIVE_TIMELOCK && !isTypeBlock) {
      scriptIntiger |= 1 << 22;
    }
    return scriptIntiger;
  }
}
