import 'package:bitcoin_base/src/bitcoin/address/legacy_address.dart';
import 'package:bitcoin_base/src/bitcoin/script/op_code/constant_lib.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';

import 'package:bitcoin_base/src/bytes_utils/dynamic_byte.dart';
import 'package:blockchain_utils/binary/binary_operation.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/numbers/int_utils.dart';

/// ignore: constant_identifier_names
enum ScriptType { P2PKH, P2SH, P2WPKH, P2WSH, P2PK }

/// A Script contains just a list of OP_CODES and also knows how to serialize into bytes
///
/// [script] the list with all the script OP_CODES and data
class Script {
  Script({required List<dynamic> script}) : script = List.unmodifiable(script);
  final List<dynamic> script;

  List<int> toTapleafTaggedHash() {
    final leafVarBytes = [
      BitcoinOpCodeConst.LEAF_VERSION_TAPSCRIPT,
      ...IntUtils.prependVarint(toBytes())
    ];
    return taggedHash(leafVarBytes, "TapLeaf");
  }

  /// create p2psh script wit current script
  Script toP2shScriptPubKey() {
    final address = P2shAddress.fromScript(script: this);
    return Script(script: ['OP_HASH160', address.getH160, 'OP_EQUAL']);
  }

  static Script fromRaw({required String hexData, bool hasSegwit = false}) {
    List<String> commands = [];
    int index = 0;
    final scriptraw = BytesUtils.fromHexString(hexData);
    while (index < scriptraw.length) {
      int byte = scriptraw[index];
      if (BitcoinOpCodeConst.CODE_OPS.containsKey(byte)) {
        commands.add(BitcoinOpCodeConst.CODE_OPS[byte]!);
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
        int bytesToRead = readUint16LE(scriptraw, index + 1);

        index = index + 3;
        commands.add(scriptraw
            .sublist(index, index + bytesToRead)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join());
        index = index + bytesToRead;
      } else if (!hasSegwit && byte == 0x4e) {
        int bytesToRead = readUint32LE(scriptraw, index + 1);

        index = index + 5;
        commands.add(scriptraw
            .sublist(index, index + bytesToRead)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join());
        index = index + bytesToRead;
      } else {
        final viAndSize =
            IntUtils.decodeVarint(scriptraw.sublist(index, index + 9));
        int dataSize = viAndSize.item1;
        int size = viAndSize.item2;
        final lastIndex = (index + size + dataSize) > scriptraw.length
            ? scriptraw.length
            : (index + size + dataSize);
        commands.add(
            BytesUtils.toHexString(scriptraw.sublist(index + size, lastIndex)));
        index = index + dataSize + size;
      }
    }
    return Script(script: commands);
  }

  static ScriptType? getType(
      {required String hexData, bool hasSegwit = false}) {
    final Script s = fromRaw(hexData: hexData, hasSegwit: hasSegwit);
    if (s.script.isEmpty) return null;

    dynamic findScriptParam(int index) {
      if (index < s.script.length) {
        return s.script[index];
      }
      return null;
    }

    final first = findScriptParam(0);
    final sec = findScriptParam(1);
    final th = findScriptParam(2);
    final four = findScriptParam(3);
    final five = findScriptParam(4);
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
  List<int> toBytes() {
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

  /// returns a serialized version of the script in hex
  String toHex() {
    final bytes = toBytes();
    return BytesUtils.toHexString(bytes);
  }

  @override
  String toString() {
    return script.join(",");
  }
}
