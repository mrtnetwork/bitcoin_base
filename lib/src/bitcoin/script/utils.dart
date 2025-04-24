import 'dart:typed_data';
import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

enum ScriptPubKeyType {
  p2pk("P2PK"),
  p2pkh("P2PKH"),
  p2sh("P2SH"),
  p2sh32("P2SH32"),
  p2wpkh("P2WPKH"),
  p2tr("P2TR"),
  p2wsh("P2WSH");

  final String name;
  const ScriptPubKeyType(this.name);
  bool get isSegwit =>
      this == ScriptPubKeyType.p2wpkh ||
      this == ScriptPubKeyType.p2wsh ||
      this == ScriptPubKeyType.p2tr;
  bool get isP2tr => this == ScriptPubKeyType.p2tr;
  bool get isP2sh => isP2sh32 || this == ScriptPubKeyType.p2sh;
  bool get isP2sh32 => this == ScriptPubKeyType.p2sh32;
}

class BitcoinScriptUtils {
  static Script buildOpReturn(List<List<int>> data) {
    return Script(script: [
      BitcoinOpcode.opReturn,
      ...data.map((e) => BytesUtils.toHexString(e))
    ]);
  }

  static bool scriptContains(
      {required Script script, required List<dynamic> elements}) {
    if (elements.length != script.script.length) return false;
    for (int i = 0; i < script.script.length; i++) {
      final element = elements[i];
      if (element != null) {
        if (element is BitcoinOpcode) {
          if (script.script[i] != element.name) {
            return false;
          }
        } else if (script.script[i] != element) {
          return false;
        }
      }
    }
    return true;
  }

  static bool isP2pkh(Script script) {
    if (scriptContains(script: script, elements: [
      BitcoinOpcode.opDup,
      BitcoinOpcode.opHash160,
      null,
      BitcoinOpcode.opEqualVerify,
      BitcoinOpcode.opCheckSig
    ])) {
      final addressProgram = script.script[2];
      return (addressProgram is String && addressProgram.length == 40);
    }
    return false;
  }

  static bool isP2sh(Script script) {
    if (scriptContains(
        script: script,
        elements: [BitcoinOpcode.opHash160, null, BitcoinOpcode.opEqual])) {
      final pubKeyBytes = BytesUtils.tryFromHexString(script.script[1]);
      return pubKeyBytes?.length == P2shAddressType.p2pkInP2sh.hashLength;
    }
    return false;
  }

  static bool isP2sh32(Script script) {
    if (scriptContains(
        script: script,
        elements: [BitcoinOpcode.opHash256, null, BitcoinOpcode.opEqual])) {
      final pubKeyBytes = BytesUtils.tryFromHexString(script.script[1]);
      return pubKeyBytes?.length == P2shAddressType.p2pkhInP2sh32.hashLength;
    }
    return false;
  }

  static bool isP2pk(Script script) {
    if (scriptContains(
        script: script, elements: [null, BitcoinOpcode.opCheckSig])) {
      final pubKeyBytes = BytesUtils.tryFromHexString(script.script[0]);
      return pubKeyBytes?.length == EcdsaKeysConst.pubKeyCompressedByteLen ||
          pubKeyBytes?.length == EcdsaKeysConst.pubKeyUncompressedByteLen;
    }
    return false;
  }

  static bool isP2tr(Script script) {
    if (scriptContains(script: script, elements: [BitcoinOpcode.op1, null])) {
      final pubKeyBytes = BytesUtils.tryFromHexString(script.script[1]);
      return pubKeyBytes?.length == SegwitAddressType.p2tr.hashLength;
    }
    return false;
  }

  static bool isP2wpkh(Script script) {
    if (scriptContains(script: script, elements: [BitcoinOpcode.op0, null])) {
      final pubKeyBytes = BytesUtils.tryFromHexString(script.script[1]);
      return pubKeyBytes?.length == SegwitAddressType.p2wpkh.hashLength;
    }
    return false;
  }

  static bool isRipemd160(Script script) {
    if (scriptContains(
        script: script,
        elements: [BitcoinOpcode.opRipemd160, null, BitcoinOpcode.opEqual])) {
      final toBytes = BytesUtils.tryFromHexString(script.script[1]);
      return toBytes?.length == QuickCrypto.hash160DigestSize;
    }
    return false;
  }

  static bool isSha256(Script script) {
    if (scriptContains(
        script: script,
        elements: [BitcoinOpcode.opSha256, null, BitcoinOpcode.opEqual])) {
      final toBytes = BytesUtils.tryFromHexString(script.script[1]);
      return toBytes?.length == QuickCrypto.sha256DigestSize;
    }
    return false;
  }

  static bool isHash256(Script script) {
    if (scriptContains(
        script: script,
        elements: [BitcoinOpcode.opHash256, null, BitcoinOpcode.opEqual])) {
      final toBytes = BytesUtils.tryFromHexString(script.script[1]);
      return toBytes?.length == QuickCrypto.sha256DigestSize;
    }
    return false;
  }

  static bool isHash160(Script script) {
    if (scriptContains(
        script: script,
        elements: [BitcoinOpcode.opHash160, null, BitcoinOpcode.opEqual])) {
      final toBytes = BytesUtils.tryFromHexString(script.script[1]);
      return toBytes?.length == QuickCrypto.hash160DigestSize;
    }
    return false;
  }

  static bool isP2wsh(Script script) {
    if (scriptContains(script: script, elements: [BitcoinOpcode.op0, null])) {
      final pubKeyBytes = BytesUtils.tryFromHexString(script.script[1]);
      return pubKeyBytes?.length == SegwitAddressType.p2wsh.hashLength;
    }
    return false;
  }

  static bool isXOnlyOpChecksig(Script script) {
    if (scriptContains(
        script: script, elements: [null, BitcoinOpcode.opCheckSig])) {
      final xOnlyKey = BytesUtils.tryFromHexString(script.script[0]);
      return xOnlyKey?.length == EcdsaKeysConst.pointCoordByteLen;
    }
    return false;
  }

  static ScriptPubKeyType? findScriptType(Script script) {
    if (isP2pkh(script)) {
      return ScriptPubKeyType.p2pkh;
    } else if (isP2sh(script)) {
      return ScriptPubKeyType.p2sh;
    } else if (isP2sh32(script)) {
      return ScriptPubKeyType.p2sh32;
    } else if (isP2pk(script)) {
      return ScriptPubKeyType.p2pk;
    } else if (isP2tr(script)) {
      return ScriptPubKeyType.p2tr;
    } else if (isP2wsh(script)) {
      return ScriptPubKeyType.p2wsh;
    } else if (isP2wpkh(script)) {
      return ScriptPubKeyType.p2wpkh;
    }
    return null;
  }

  static bool isOpReturn(Script script) {
    return script.script.isNotEmpty &&
        script.script[0] == BitcoinOpCodeConst.opReturn;
  }

  static bool isOpTrue(Script script) {
    return script.script.length == 1 &&
        BitcoinOpcode.findByName(script.script[0])?.value ==
            BitcoinOpcode.opTrue.value;
  }

  static bool isPubKeyOpCheckSig(Script script) {
    if (scriptContains(
        script: script, elements: [null, BitcoinOpcode.opCheckSig])) {
      final pubKeyBytes = BytesUtils.tryFromHexString(script.script[0]);
      return pubKeyBytes?.length == EcdsaKeysConst.pubKeyCompressedByteLen ||
          pubKeyBytes?.length == EcdsaKeysConst.pubKeyUncompressedByteLen;
    }
    return false;
  }

  static bool hasOpCheckSig(Script script) {
    return script.script.contains(BitcoinOpcode.opCheckSig.name);
  }

  static bool hasOpCheckSigAdd(Script script) {
    return script.script.contains(BitcoinOpcode.opCheckSigAdd.name);
  }

  static bool hasOpCheckMultisig(Script script) {
    return script.script.contains(BitcoinOpcode.opCheckMultiSig.name);
  }

  static bool hasOpCheckMultiSigVerify(Script scriot) {
    return scriot.script.contains(BitcoinOpcode.opCheckMultiSigVerify.name);
  }

  static bool hasAnyOpCheckSig(Script script) {
    if (hasOpCheckSig(script) ||
        hasOpCheckMultisig(script) ||
        hasOpCheckSigAdd(script) ||
        hasOpCheckMultiSigVerify(script)) {
      return true;
    }
    return false;
  }

  static int? decodeOpN(String opcode) {
    if (!opcode.startsWith("OP_")) return null;
    int n = int.tryParse(opcode.replaceFirst("OP_", '')) ?? -1;
    if (n < 0 || n > 16) return null;
    return n;
  }

  static bool isMultisigScript(Script script) {
    final opCodes = script.script;
    if (opCodes.length < 4) return false;
    if (opCodes.last != BitcoinOpcode.opCheckMultiSig.name &&
        opCodes.last != BitcoinOpcode.opCheckMultiSigVerify.name) {
      return false;
    }
    final int? threshold = decodeOpN(opCodes.first.toString());
    final int? total = decodeOpN(opCodes[opCodes.length - 2].toString());
    if (threshold == null || total == null) {
      return false;
    }
    if (threshold > total) return false;
    int pubkeyCount = opCodes.length - 3;
    if (pubkeyCount != total) return false;

    return true;
  }

  static MultiSignatureAddress? parseMultisigScript(Script script) {
    final opCodes = script.script;
    if (opCodes.length < 4) return null;
    if (opCodes.last != BitcoinOpcode.opCheckMultiSig.name &&
        opCodes.last != BitcoinOpcode.opCheckMultiSigVerify.name) {
      return null;
    }
    final int? threshold = decodeOpN(opCodes.first.toString());
    final int? total = decodeOpN(opCodes[opCodes.length - 2].toString());
    if (threshold == null || total == null) {
      return null;
    }
    try {
      List<MultiSignatureSigner> signers = [];
      final pubKeys = opCodes.sublist(1, opCodes.length - 2);
      int i = 0;
      while (i < pubKeys.length) {
        int weight = 1;
        final pubkey = pubKeys[i];
        for (int j = i + 1; j < pubKeys.length; j++) {
          if (pubKeys[j] == pubkey) {
            weight++;
            continue;
          }
          break;
        }
        i += weight;
        signers.add(MultiSignatureSigner(publicKey: pubkey, weight: weight));
      }
      final sumWeight = signers.fold<int>(0, (p, c) => p + c.weight);
      if (sumWeight != total) {
        return null;
      }
      if (sumWeight < threshold) return null;
      return MultiSignatureAddress(threshold: threshold, signers: signers);
    } catch (_) {
      return null;
    }
  }

  static P2trMultiSignatureAddress? isP2trMultiScript(Script script) {
    final opCodes = script.script;
    if (opCodes.length < 4) return null;
    if (opCodes.last != 'OP_NUMEQUAL') return null;
    final int? threshold = decodeOpN(opCodes[opCodes.length - 2].toString());
    if (threshold == null || threshold > 15) {
      return null;
    }
    try {
      List<P2trMultiSignatureSigner> signers = [];
      final xOnlyKeys = opCodes.sublist(0, opCodes.length - 2).cast<String>();
      int i = 0;
      while (i < xOnlyKeys.length) {
        int weight = 1;
        final xOnly = xOnlyKeys[i];
        for (int j = i + 2; j < xOnlyKeys.length; j += 2) {
          if (xOnlyKeys[j] == xOnly) {
            weight++;
            continue;
          }
          break;
        }
        i += weight * 2;
        signers.add(P2trMultiSignatureSigner(xOnly: xOnly, weight: weight));
      }
      final sumWeight = signers.fold<int>(0, (p, c) => p + c.weight);

      if (sumWeight < threshold) return null;
      return P2trMultiSignatureAddress(threshold: threshold, signers: signers);
    } catch (_) {
      return null;
    }
  }

  static BitcoinBaseAddress generateAddressFromScriptPubKey(Script script) {
    BitcoinBaseAddress? address;
    if (BitcoinScriptUtils.isP2wpkh(script)) {
      address = P2wpkhAddress.fromProgram(program: script.script[1]);
    } else if (BitcoinScriptUtils.isP2pkh(script)) {
      address = P2pkhAddress.fromHash160(addrHash: script.script[2]);
    } else if (BitcoinScriptUtils.isP2pk(script)) {
      address = P2pkAddress(publicKey: script.script[0]);
    } else if (BitcoinScriptUtils.isP2sh(script)) {
      address = P2shAddress.fromHash160(addrHash: script.script[1]);
    } else if (BitcoinScriptUtils.isP2sh32(script)) {
      address = P2shAddress.fromHash160(
          addrHash: script.script[1], type: P2shAddressType.p2pkInP2sh32);
    } else if (BitcoinScriptUtils.isP2wsh(script)) {
      address = P2wshAddress.fromProgram(program: script.script[1]);
    } else if (BitcoinScriptUtils.isP2tr(script)) {
      address = P2trAddress.fromProgram(program: script.script[1]);
    }
    if (address == null || address.toScriptPubKey() != script) {
      throw DartBitcoinPluginException(
          "Unknown scriptPubKey: Unable to generate a valid address.");
    }
    return address;
  }

  static BitcoinBaseAddress? tryGenerateAddressFromScriptPubKey(Script script) {
    try {
      return generateAddressFromScriptPubKey(script);
    } catch (_) {
      return null;
    }
  }

  static List<int> opPushData(List<int> dataBytes) {
    if (dataBytes.length < BitcoinOpCodeConst.opPushData1) {
      return [dataBytes.length, ...dataBytes];
    } else if (dataBytes.length < mask8) {
      return [BitcoinOpCodeConst.opPushData1, dataBytes.length, ...dataBytes];
    } else if (dataBytes.length < mask16) {
      final lengthBytes = IntUtils.toBytes(dataBytes.length,
          length: 2, byteOrder: Endian.little);
      return [BitcoinOpCodeConst.opPushData2, ...lengthBytes, ...dataBytes];
    } else if (dataBytes.length < mask32) {
      final lengthBytes = IntUtils.toBytes(dataBytes.length,
          length: 4, byteOrder: Endian.little);
      return [BitcoinOpCodeConst.opPushData4, ...lengthBytes, ...dataBytes];
    } else {
      throw const DartBitcoinPluginException(
          'Data too large. Cannot push into script');
    }
  }

  static List<int> pushInteger(int integer) {
    if (integer < 0) {
      throw const DartBitcoinPluginException(
          'Integer is currently required to be positive.');
    }

    /// Calculate the number of bytes required to represent the integer
    final numberOfBytes = (integer.bitLength + 7) ~/ 8;

    /// Convert to little-endian bytes
    List<int> integerBytes = List<int>.filled(numberOfBytes, 0);
    for (var i = 0; i < numberOfBytes; i++) {
      integerBytes[i] = (integer >> (i * 8)) & mask8;
    }

    /// If the last bit is set, add a sign byte to signify a positive integer
    if ((integer & (1 << (numberOfBytes * 8 - 1))) != 0) {
      integerBytes = List<int>.from([...integerBytes, 0x00]);
    }
    final data = opPushData(integerBytes);
    return data;
  }
}
