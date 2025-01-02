import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// A list of the witness items required to satisfy the locking conditions of a segwit input (aka witness stack).
///
/// [stack] the witness items (hex str) list
class TxWitnessInput {
  TxWitnessInput({required List<String> stack}) : stack = stack.immutable;
  final List<String> stack;

  /// creates a copy of the object (classmethod)
  TxWitnessInput copy() {
    return TxWitnessInput(stack: stack);
  }

  /// returns a serialized byte version of the witness items list
  List<int> toBytes() {
    var stackBytes = <int>[];

    for (final item in stack) {
      final itemBytes = IntUtils.prependVarint(BytesUtils.fromHexString(item));
      stackBytes = [...stackBytes, ...itemBytes];
    }

    return stackBytes;
  }

  Map<String, dynamic> toJson() {
    return {'stack': stack};
  }

  @override
  String toString() {
    return "TxWitnessInput{stack: ${stack.join(", ")}}";
  }
}
