import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// A Script contains just a list of OP_CODES and also knows how to serialize into bytes
///
/// [script] the list with all the script OP_CODES and data
class Script {
  Script({required List<dynamic> script})
      : assert(() {
          for (final i in script) {
            if (i is! String && i is! int) return false;
          }
          return true;
        }(),
            "A valid script is a composition of opcodes, hexadecimal strings, and integers arranged in a structured list."),
        script = List.unmodifiable(script);
  final List<dynamic> script;

  static Script fromRaw({required String hexData, bool hasSegwit = false}) {
    List<String> commands = [];
    int index = 0;
    final scriptBytes = BytesUtils.fromHexString(hexData);
    while (index < scriptBytes.length) {
      int byte = scriptBytes[index];
      if (BitcoinOpCodeConst.CODE_OPS.containsKey(byte)) {
        commands.add(BitcoinOpCodeConst.CODE_OPS[byte]!);
        index = index + 1;
      } else if (!hasSegwit && byte == 0x4c) {
        int bytesToRead = scriptBytes[index + 1];
        index = index + 1;
        commands.add(BytesUtils.toHexString(
            scriptBytes.sublist(index, index + bytesToRead)));
        index = index + bytesToRead;
      } else if (!hasSegwit && byte == 0x4d) {
        int bytesToRead = readUint16LE(scriptBytes, index + 1);

        index = index + 3;
        commands.add(BytesUtils.toHexString(
            scriptBytes.sublist(index, index + bytesToRead)));
        index = index + bytesToRead;
      } else if (!hasSegwit && byte == 0x4e) {
        int bytesToRead = readUint32LE(scriptBytes, index + 1);

        index = index + 5;
        commands.add(BytesUtils.toHexString(
            scriptBytes.sublist(index, index + bytesToRead)));
        index = index + bytesToRead;
      } else {
        final viAndSize =
            IntUtils.decodeVarint(scriptBytes.sublist(index, index + 9));
        int dataSize = viAndSize.item1;
        int size = viAndSize.item2;
        final lastIndex = (index + size + dataSize) > scriptBytes.length
            ? scriptBytes.length
            : (index + size + dataSize);
        commands.add(BytesUtils.toHexString(
            scriptBytes.sublist(index + size, lastIndex)));
        index = index + dataSize + size;
      }
    }
    return Script(script: commands);
  }

  List<int> toBytes() {
    if (script.isEmpty) return <int>[];
    DynamicByteTracker scriptBytes = DynamicByteTracker();
    for (var token in script) {
      if (BitcoinOpCodeConst.OP_CODES.containsKey(token)) {
        scriptBytes.add(BitcoinOpCodeConst.OP_CODES[token]!);
      } else if (token is int && token >= 0 && token <= 16) {
        scriptBytes.add(BitcoinOpCodeConst.OP_CODES['OP_$token']!);
      } else {
        if (token is int) {
          scriptBytes.add(pushInteger(token));
        } else {
          scriptBytes.add(opPushData(token));
        }
      }
    }

    return scriptBytes.toBytes();
  }

  String toHex() {
    return BytesUtils.toHexString(toBytes());
  }

  @override
  String toString() {
    return "Script{script: ${script.join(", ")}}";
  }
}
