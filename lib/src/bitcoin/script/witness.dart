import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/numbers/int_utils.dart';

/// A list of the witness items required to satisfy the locking conditions of a segwit input (aka witness stack).
///
/// [stack] the witness items (hex str) list
class TxWitnessInput {
  TxWitnessInput({required List<String> stack})
      : stack = List.unmodifiable(stack);
  final List<String> stack;

  /// creates a copy of the object (classmethod)
  TxWitnessInput copy() {
    return TxWitnessInput(stack: stack);
  }

  /// returns a serialized byte version of the witness items list
  List<int> toBytes() {
    List<int> stackBytes = [];

    for (String item in stack) {
      List<int> itemBytes =
          IntUtils.prependVarint(BytesUtils.fromHexString(item));
      stackBytes = [...stackBytes, ...itemBytes];
    }

    return stackBytes;
  }
}
