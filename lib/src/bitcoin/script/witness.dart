import 'package:blockchain_utils/blockchain_utils.dart';

/// A list of the witness items required to satisfy the locking conditions of a segwit input (aka witness stack).
///
/// [stack] the witness items (hex str) list
class TxWitnessInput {
  TxWitnessInput({required List<String> stack}) : stack = stack.immutable;
  final List<String> stack;

  /// creates a copy of the object (classmethod)
  TxWitnessInput clone() {
    return TxWitnessInput(stack: stack);
  }

  factory TxWitnessInput.deserialize(List<int> bytes) {
    final length = IntUtils.decodeVarint(bytes);
    int offset = length.$2;
    final List<String> stack = [];
    for (int n = 0; n < length.$1; n++) {
      List<int> witness = [];
      final itemLen = IntUtils.decodeVarint(bytes.sublist(offset));
      offset += itemLen.$2;
      if (itemLen.$1 != 0) {
        witness = bytes.sublist(offset, offset + itemLen.$1);
      }
      offset += itemLen.$1;
      stack.add(BytesUtils.toHexString(witness));
    }

    return TxWitnessInput(stack: stack);
  }

  /// returns a serialized byte version of the witness items list
  BuBytes toBytes() {
    final bytes = BuBytes.empty();
    final length = IntUtils.encodeVarint(stack.length);
    bytes.addAll(length);
    for (final item in stack) {
      final itemBytes = BytesUtils.fromHexString(item);
      final varint = IntUtils.prependVarint(itemBytes);
      bytes.addAll(varint);
    }

    return bytes;
  }

  Map<String, dynamic> toJson() {
    return {'stack': stack};
  }

  @override
  String toString() {
    return "TxWitnessInput{stack: ${stack.join(", ")}}";
  }
}
