import 'dart:typed_data';
import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/address/core.dart';
import 'package:bitcoin_base/src/bitcoin/address/segwit_address.dart';
import 'package:bitcoin_base/src/bitcoin/constant/constant.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/crypto/ec/ec_encryption.dart';
import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';
import 'package:bitcoin_base/src/formating/magic_prefix.dart';
import 'ec_encryption.dart' as ec;

class ECPublic {
  /// Constructs an ECPublic key from a byte representation.
  ECPublic.fromBytes(Uint8List public) {
    if (!ec.isPoint(public)) {
      throw ArgumentError("Bad point");
    }
    final d = reEncodedFromForm(public, false);
    _key = d;
  }

  /// Constructs an ECPublic key from hex representation.
  ECPublic.fromHex(String hex) {
    final toBytes = hexToBytes(hex);
    if (!ec.isPoint(toBytes)) {
      throw ArgumentError("Bad point");
    }
    final d = reEncodedFromForm(toBytes, false);
    _key = d;
  }

  late final Uint8List _key;

  /// toHex converts the ECPublic key to a hex-encoded string.
  /// If 'compressed' is true, the key is in compressed format.
  String toHex({bool compressed = true}) {
    final bytes = toBytes();
    if (compressed) {
      final point = reEncodedFromForm(bytes, true);
      return bytesToHex(point);
    }
    return bytesToHex(bytes);
  }

  /// _toHash160 computes the RIPEMD160 hash of the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  Uint8List _toHash160({bool compressed = true}) {
    final bytes = hexToBytes(toHex(compressed: compressed));
    return hash160(bytes);
  }

  /// toHash160 computes the RIPEMD160 hash of the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  String toHash160({bool compressed = true}) {
    final bytes = hexToBytes(toHex(compressed: compressed));
    return bytesToHex(hash160(bytes));
  }

  /// toAddress generates a P2PKH (Pay-to-Public-Key-Hash) address from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2pkhAddress toAddress({bool compressed = true}) {
    final h16 = _toHash160(compressed: compressed);
    final toHex = bytesToHex(h16);

    return P2pkhAddress(hash160: toHex);
  }

  /// toSegwitAddress generates a P2WPKH (Pay-to-Witness-Public-Key-Hash) SegWit address
  /// from the ECPublic key. If 'compressed' is true, the key is in compressed format.
  P2wpkhAddress toSegwitAddress({bool compressed = true}) {
    final h16 = _toHash160(compressed: compressed);
    final toHex = bytesToHex(h16);

    return P2wpkhAddress(program: toHex);
  }

  /// toP2pkAddress generates a P2PK (Pay-to-Public-Key) address from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2pkAddress toP2pkAddress({bool compressed = true}) {
    final h = toHex(compressed: compressed);
    return P2pkAddress(publicKey: h);
  }

  /// toRedeemScript generates a redeem script from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  Script toRedeemScript({bool compressed = true}) {
    final redeem = toHex(compressed: compressed);
    return Script(script: [redeem, "OP_CHECKSIG"]);
  }

  /// toP2pkhInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2PK (Pay-to-Public-Key) script derived from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2shAddress toP2pkhInP2sh({bool compressed = true}) {
    final addr = toAddress(compressed: compressed);
    return P2shAddress.fromScript(
        script: addr.toScriptPubKey(), type: AddressType.p2pkhInP2sh);
  }

  /// toP2pkInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2PK (Pay-to-Public-Key) script derived from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2shAddress toP2pkInP2sh({bool compressed = true}) {
    return P2shAddress(script: toRedeemScript(compressed: compressed));
  }

  /// ToTaprootAddress generates a P2TR(Taproot) address from the ECPublic key
  /// and an optional script. The 'script' parameter can be used to specify
  /// custom spending conditions.
  P2trAddress toTaprootAddress({List<dynamic>? scripts}) {
    final pubKey = toTapRotHex(script: scripts);

    return P2trAddress(program: pubKey);
  }

  /// toP2wpkhInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2WPKH (Pay-to-Witness-Public-Key-Hash) script derived from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2shAddress toP2wpkhInP2sh({bool compressed = true}) {
    final addr = toSegwitAddress(compressed: compressed);
    return P2shAddress.fromScript(
        script: addr.toScriptPubKey(), type: AddressType.p2wpkhInP2sh);
  }

  /// toP2wshScript generates a P2WSH (Pay-to-Witness-Script-Hash) script
  /// derived from the ECPublic key. If 'compressed' is true, the key is in compressed format.
  Script toP2wshScript({bool compressed = true}) {
    return Script(script: [
      'OP_1',
      toHex(compressed: compressed),
      "OP_1",
      "OP_CHECKMULTISIG"
    ]);
  }

  /// toP2wshAddress generates a P2WSH (Pay-to-Witness-Script-Hash) address
  /// from the ECPublic key. If 'compressed' is true, the key is in compressed format.
  P2wshAddress toP2wshAddress({bool compressed = true}) {
    return P2wshAddress(script: toP2wshScript(compressed: compressed));
  }

  /// toP2wshInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2WSH (Pay-to-Witness-Script-Hash) script derived from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2shAddress toP2wshInP2sh({bool compressed = true}) {
    final p2sh = toP2wshAddress(compressed: compressed);
    return P2shAddress.fromScript(
        script: p2sh.toScriptPubKey(), type: AddressType.p2wshInP2sh);
  }

  /// calculateTweek computes and returns the TapTweak value based on the ECPublic key
  /// and an optional script. It uses the key's x-coordinate and the Merkle root of the script
  /// (if provided) to calculate the tweak.
  BigInt calculateTweek({dynamic script}) {
    final tweak = _calculateTweek(_key, script: script);
    return decodeBigInt(tweak);
  }

  /// toBytes returns the uncompressed byte representation of the ECPublic key.
  Uint8List toBytes({int? prefix = 0x04}) {
    if (prefix != null) {
      return Uint8List.fromList([prefix, ..._key]);
    }
    return Uint8List.fromList([..._key]);
  }

  /// toCompressedBytes returns the compressed byte representation of the ECPublic key.
  Uint8List toCompressedBytes() {
    final point = reEncodedFromForm(toBytes(), true);
    return point;
  }

  /// returns the x coordinate only as hex string after tweaking (needed for taproot)
  String toTapRotHex({List<dynamic>? script}) {
    final tweak = _calculateTweek(_key, script: script);
    final point = tweakTaprootPoint(_key, tweak);
    return bytesToHex(point.sublist(0, 32));
  }

  /// toXOnlyHex extracts and returns the x-coordinate (first 32 bytes) of the ECPublic key
  /// as a hexadecimal string.
  String toXOnlyHex() {
    return bytesToHex(_key.sublist(0, 32));
  }

  /// _calculateTweek computes and returns the TapTweak value based on the ECPublic key
  /// and an optional script. It uses the key's x-coordinate and the Merkle root of the script
  /// (if provided) to calculate the tweak.
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

  /// _getTagHashedMerkleRoot computes and returns the tagged hashed Merkle root for Taproot
  /// based on the provided argument. It handles different argument types, including scripts
  /// and lists of scripts.
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

  /// _tapleafTaggedHash computes and returns the tagged hash of a script for Taproot,
  /// using the specified script. It prepends a version byte and then tags the hash with "TapLeaf".
  Uint8List _tapleafTaggedHash(Script script) {
    final scriptBytes = prependVarint(script.toBytes());

    final part = Uint8List.fromList([LEAF_VERSION_TAPSCRIPT, ...scriptBytes]);
    return taggedHash(part, 'TapLeaf');
  }

  /// _tapBranchTaggedHash computes and returns the tagged hash of two byte slices
  /// for Taproot, where 'a' and 'b' are the input byte slices. It ensures that 'a' and 'b'
  /// are sorted and concatenated before tagging the hash with "TapBranch".
  Uint8List _tapBranchTaggedHash(Uint8List a, Uint8List b) {
    if (isLessThanBytes(a, b)) {
      return taggedHash(Uint8List.fromList([...a, ...b]), "TapBranch");
    }
    return taggedHash(Uint8List.fromList([...b, ...a]), "TapBranch");
  }

  /// returns true if the message was signed with this public key's
  bool verify(String message, Uint8List signature) {
    final msg = singleHash(magicMessage(message));
    return ec.verify(msg, toBytes(), signature.sublist(1));
  }

  /// GetSignaturePublic extracts and returns the public key associated with a signature
  /// for the given message. If the extraction is successful, it returns an ECPublic key;
  /// otherwise, it returns nil.
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
