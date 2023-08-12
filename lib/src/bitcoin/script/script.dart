import 'dart:typed_data';

import 'package:bitcoin/src/bitcoin/address/address.dart';
import 'package:bitcoin/src/bitcoin/constant/constant.dart';
import 'package:bitcoin/src/bitcoin/tools/tools.dart';
import 'package:bitcoin/src/crypto/crypto.dart';
import 'package:bitcoin/src/formating/bytes_num_formating.dart';

import 'package:bitcoin/src/formating/bytes_tracker.dart';

class Script {
  const Script({required this.script});
  final List<dynamic> script;

  Uint8List toTapleafTaggedHash() {
    final leafVarBytes = Uint8List.fromList([
      ...Uint8List.fromList([LEAF_VERSION_TAPSCRIPT]),
      ...prependVarint(toBytes())
    ]);
    return taggedHash(leafVarBytes, "TapLeaf");
  }

  Script toP2shScriptPubKey() {
    final address = P2shAddress(script: this);
    return Script(script: ['OP_HASH160', address.getH160, 'OP_EQUAL']);
  }

  static Script fromRaw({required String hexData, bool hasSegwit = false}) {
    List<String> commands = [];
    int index = 0;
    final scriptraw = hexToBytes(hexData);

    while (index < scriptraw.length) {
      int byte = scriptraw[index];

      if (CODE_OPS.containsKey(byte)) {
        commands.add(CODE_OPS[byte]!);
        index = index + 1;
      } else if (!hasSegwit && byte == 0x4c) {
        int bytesToRead = scriptraw[index + 1];
        index = index + 1;
        commands.add(scriptraw
            .sublist(index, index + bytesToRead)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join());
        index = index + bytesToRead;
      } else if (!hasSegwit && byte == 0x4d) {
        int bytesToRead = ByteData.sublistView(scriptraw, index + 1, index + 3)
            .getUint16(0, Endian.little);
        index = index + 3;
        commands.add(scriptraw
            .sublist(index, index + bytesToRead)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join());
        index = index + bytesToRead;
      } else if (!hasSegwit && byte == 0x4e) {
        int bytesToRead = ByteData.sublistView(scriptraw, index + 1, index + 5)
            .getUint32(0, Endian.little);
        index = index + 5;
        commands.add(scriptraw
            .sublist(index, index + bytesToRead)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join());
        index = index + bytesToRead;
      } else {
        final viAndSize = viToInt(scriptraw.sublist(index, index + 9));
        int dataSize = viAndSize.$1;
        int size = viAndSize.$2;
        commands.add(scriptraw
            .sublist(index + size, index + size + dataSize)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join());
        index = index + dataSize + size;
      }
    }
    return Script(script: commands);
  }

  Uint8List toBytes() {
    DynamicByteTracker scriptBytes = DynamicByteTracker();
    for (var token in script) {
      if (OP_CODES.containsKey(token)) {
        scriptBytes.add(OP_CODES[token]!);
      } else if (token is int && token >= 0 && token <= 16) {
        scriptBytes.add(OP_CODES['OP_$token']!);
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
    final bytes = toBytes();
    return bytesToHex(bytes);
  }

  @override
  String toString() {
    return script.join(",");
  }
}
