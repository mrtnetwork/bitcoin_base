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

  static Script deserialize(
      {required List<int> bytes, bool hasSegwit = false}) {
    List<String> commands = [];
    int index = 0;
    // final scriptBytes = BytesUtils.fromHexString(hexData);
    while (index < bytes.length) {
      int byte = bytes[index];
      if (BitcoinOpCodeConst.CODE_OPS.containsKey(byte)) {
        if (!BitcoinOpCodeConst.isOpPushData(byte)) {
          commands.add(BitcoinOpCodeConst.CODE_OPS[byte]!);
        }

        /// skip op
        index = index + 1;
        if (byte == BitcoinOpCodeConst.opPushData1) {
          // get len
          int bytesToRead = bytes[index];
          // skip len
          index = index + 1;
          commands.add(BytesUtils.toHexString(
              bytes.sublist(index, index + bytesToRead)));

          /// add length
          index = index + bytesToRead;
        } else if (byte == BitcoinOpCodeConst.opPushData2) {
          /// get len
          int bytesToRead = readUint16LE(bytes, index);
          index = index + 2;
          commands.add(BytesUtils.toHexString(
              bytes.sublist(index, index + bytesToRead)));
          index = index + bytesToRead;
        } else if (byte == BitcoinOpCodeConst.opPushData4) {
          int bytesToRead = readUint32LE(bytes, index);

          index = index + 4;
          commands.add(BytesUtils.toHexString(
              bytes.sublist(index, index + bytesToRead)));
          index = index + bytesToRead;
        }
      } else {
        final viAndSize = IntUtils.decodeVarint(bytes.sublist(index));
        int dataSize = viAndSize.item1;
        int size = viAndSize.item2;
        final lastIndex = (index + size + dataSize) > bytes.length
            ? bytes.length
            : (index + size + dataSize);
        commands.add(
            BytesUtils.toHexString(bytes.sublist(index + size, lastIndex)));
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
