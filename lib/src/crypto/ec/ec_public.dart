import 'dart:typed_data';
import 'package:bitcoin/src/bitcoin/address/address.dart';
import 'package:bitcoin/src/bitcoin/address/segwit_address.dart';
import 'package:bitcoin/src/bitcoin/constant/constant.dart';
import 'package:bitcoin/src/bitcoin/script/script.dart';
import 'package:bitcoin/src/crypto/crypto.dart';
import 'package:bitcoin/src/crypto/ec/ec_encryption.dart';
import 'package:bitcoin/src/formating/bytes_num_formating.dart';
import 'package:bitcoin/src/formating/magic_prefix.dart';
import 'ec_encryption.dart' as ec;

class ECPublic {
  ECPublic.fromHex(String hex) {
    final toBytes = hexToBytes(hex);
    if (!ec.isPoint(toBytes)) {
      throw ArgumentError("Bad point");
    }
    final d = reEncodedFromForm(toBytes, false);
    _key = d;
  }

  late final Uint8List _key;

  String toHex({bool compressed = true}) {
    final bytes = toBytes();
    if (compressed) {
      final d = reEncodedFromForm(bytes, true);
      return bytesToHex(d);
    }
    return bytesToHex(bytes);
  }

  Uint8List _toHash160({bool compressed = true}) {
    final bytes = hexToBytes(toHex(compressed: compressed));
    return hash160(bytes);
  }

  String toHash160({bool compressed = true}) {
    final bytes = hexToBytes(toHex(compressed: compressed));
    return bytesToHex(hash160(bytes));
  }

  P2pkhAddress toAddress({bool copressed = true}) {
    final h16 = _toHash160(compressed: copressed);
    final str = bytesToHex(h16);

    return P2pkhAddress(hash160: str);
  }

  P2wpkhAddress toSegwitAddress({bool copressed = true}) {
    final h16 = _toHash160(compressed: copressed);
    final str = bytesToHex(h16);

    return P2wpkhAddress(program: str);
  }

  P2pkAddress toP2pkAddress({bool copressed = true}) {
    final d = toHex(compressed: copressed);
    return P2pkAddress(publicKey: d);
  }

  Script toRedeemScript({bool copressed = true}) {
    final d = toHex(compressed: copressed);
    return Script(script: [d, "OP_CHECKSIG"]);
  }

  BigInt calculateTweek({dynamic script}) {
    final tweak = _calculateTweek(_key, script: script);
    return decodeBigInt(tweak);
  }

  Uint8List toBytes({int? compressedPrefix = 0x04}) {
    if (compressedPrefix != null) {
      return Uint8List.fromList([compressedPrefix, ..._key]);
    }
    return Uint8List.fromList([..._key]);
  }

  String toTapRotHex({List<dynamic>? script}) {
    final tweak = _calculateTweek(_key, script: script);
    final point = tweakTaprootPoint(_key, tweak);
    return bytesToHex(point.sublist(0, 32));
  }

  String toXOnlyHex() {
    return bytesToHex(_key.sublist(0, 32));
  }

  Uint8List _calculateTweek(Uint8List public, {dynamic script}) {
    final keyX = Uint8List.fromList(public.getRange(0, 32).toList());
    if (script == null) {
      final tweek = taggedHash(keyX, "TapTweak");
      return tweek;
    }
    final merkleRoot = _getTagHashedMerkleRoot(script);
    final tweek =
        taggedHash(Uint8List.fromList([...keyX, ...merkleRoot]), "TapTweak");
    return tweek;
  }

  Uint8List _getTagHashedMerkleRoot(dynamic args) {
    if (args is Script) {
      final tagged = _tapleafTaggedHash(args);
      return tagged;
    }

    args as List;
    if (args.isEmpty) return Uint8List(0);
    if (args.length == 1) {
      return _getTagHashedMerkleRoot(args.first);
    } else if (args.length == 2) {
      final left = _getTagHashedMerkleRoot(args.first);
      final right = _getTagHashedMerkleRoot(args.last);
      final tap = _tapBranchTaggedHash(left, right);
      return tap;
    }
    throw Exception("List cannot have more than 2 branches.");
  }

  Uint8List _tapleafTaggedHash(Script script) {
    final scriptBytes = prependVarint(script.toBytes());

    final part = Uint8List.fromList([LEAF_VERSION_TAPSCRIPT, ...scriptBytes]);
    return taggedHash(part, 'TapLeaf');
  }

  Uint8List _tapBranchTaggedHash(Uint8List a, Uint8List b) {
    if (isLessThanBytes(a, b)) {
      return taggedHash(Uint8List.fromList([...a, ...b]), "TapBranch");
    }
    return taggedHash(Uint8List.fromList([...b, ...a]), "TapBranch");
  }

  P2trAddress toTaprootAddress({List<dynamic>? scripts}) {
    final pubKey = toTapRotHex(script: scripts);

    return P2trAddress(program: pubKey);
  }

  bool verify(String message, Uint8List signature) {
    final msg = singleHash(magicMessage(message));
    return ec.verify(msg, toBytes(), signature.sublist(1));
  }

  static ECPublic? getSignaturPublic(String message, Uint8List signatur) {
    final msg = singleHash(magicMessage(message));
    int prefix = signatur[0];
    int recid = -1;
    if (prefix >= 31) {
      recid = prefix - 31;
    } else {
      recid = prefix - 27;
    }
    final rec =
        ec.recoverPublicKeyFromSignature(recid, signatur.sublist(1), msg);
    if (rec != null) {
      final ECPublic s = ECPublic.fromHex(bytesToHex(rec));
      return s;
    }
    return null;
  }
}
