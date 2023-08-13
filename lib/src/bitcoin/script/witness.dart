import 'dart:typed_data';
import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';

/// A list of the witness items required to satisfy the locking conditions of a segwit input (aka witness stack).
///
/// [stack] the witness items (hex str) list
class TxWitnessInput {
  TxWitnessInput({required this.stack});
  final List<String> stack;

  /// creates a copy of the object (classmethod)
  TxWitnessInput copy() {
    return TxWitnessInput(stack: List.from(stack, growable: false));
  }

  /// returns a serialized byte version of the witness items list
  Uint8List toBytes() {
    Uint8List stackBytes = Uint8List(0);

    for (String item in stack) {
      Uint8List itemBytes = prependVarint(hexToBytes(item));
      stackBytes = Uint8List.fromList([...stackBytes, ...itemBytes]);
    }

    return stackBytes;
  }
}
