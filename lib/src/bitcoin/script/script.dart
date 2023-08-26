import 'dart:typed_data';

import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/constant/constant.dart';
import 'package:bitcoin_base/src/bitcoin/tools/tools.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';

import 'package:bitcoin_base/src/formating/bytes_tracker.dart';

// ignore: constant_identifier_names
enum ScriptType { P2PKH, P2SH, P2WPKH, P2WSH, P2PK }

/// A Script contains just a list of OP_CODES and also knows how to serialize into bytes
///
/// [script] the list with all the script OP_CODES and data
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

  /// create p2psh script wit current script
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
        final lastIndex = (index + size + dataSize) > scriptraw.length
            ? scriptraw.length
            : (index + size + dataSize);
        commands.add(bytesToHex(scriptraw.sublist(index + size, lastIndex)));
        index = index + dataSize + size;
      }
    }
    return Script(script: commands);
  }

  static ScriptType? getType(
      {required String hexData, bool hasSegwit = false}) {
    final Script s = fromRaw(hexData: hexData, hasSegwit: hasSegwit);
    if (s.script.isEmpty) return null;
    final first = s.script.elementAtOrNull(0);
    final sec = s.script.elementAtOrNull(1);
    final th = s.script.elementAtOrNull(2);
    final four = s.script.elementAtOrNull(3);
    final five = s.script.elementAtOrNull(4);
    if (first == "OP_0") {
      if (sec is String?) {
        if (sec?.length == 40) {
          return ScriptType.P2WPKH;
        } else if (sec?.length == 64) {
          return ScriptType.P2WSH;
        }
      }
    } else if (first == "OP_DUP") {
      if (sec == "OP_HASH160" &&
          four == "OP_EQUALVERIFY" &&
          five == "OP_CHECKSIG") {
        return ScriptType.P2PKH;
      }
    } else if (first == "OP_HASH160" && th == "OP_EQUAL") {
      return ScriptType.P2SH;
    } else if (sec == "OP_CHECKSIG" && first is String) {
      if (first.length == 66) {
        return ScriptType.P2PK;
      }
    }
    return null;
  }

  /// returns a serialized byte version of the script
  Uint8List toBytes() {
    DynamicByteTracker scriptBytes = DynamicByteTracker();
    try {
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
    } finally {
      scriptBytes.close();
    }
  }

  /// returns a serialized version of the script in hex
  String toHex() {
    final bytes = toBytes();
    return bytesToHex(bytes);
  }

  @override
  String toString() {
    return script.join(",");
  }
}
