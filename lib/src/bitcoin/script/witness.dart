import 'dart:typed_data';
import 'package:bitcoin/src/formating/bytes_num_formating.dart';

class TxWitnessInput {
  TxWitnessInput({required this.stack});
  final List<String> stack;

  TxWitnessInput copy() {
    return TxWitnessInput(stack: List.from(stack, growable: false));
  }

  Uint8List toBytes() {
    Uint8List stackBytes = Uint8List(0);

    for (String item in stack) {
      Uint8List itemBytes = prependVarint(hexToBytes(item));
      stackBytes = Uint8List.fromList([...stackBytes, ...itemBytes]);
    }

    return stackBytes;
  }
}
