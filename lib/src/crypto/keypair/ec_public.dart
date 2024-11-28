import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class ECPublic {
  final Bip32PublicKey publicKey;
  final bool? compressed;
  const ECPublic._(this.publicKey, {this.compressed = true});

  factory ECPublic.fromBip32(Bip32PublicKey publicKey) {
    if (publicKey.curveType != EllipticCurveTypes.secp256k1) {
      throw const DartBitcoinPluginException(
          "invalid public key curve for bitcoin");
    }
    return ECPublic._(publicKey);
  }

  /// Constructs an ECPublic key from a byte representation.
  factory ECPublic.fromBytes(List<int> public) {
    final publicKey = Bip32PublicKey.fromBytes(public, Bip32KeyData(),
        Bip32Const.mainNetKeyNetVersions, EllipticCurveTypes.secp256k1);
    return ECPublic._(publicKey,
        compressed: public.length == 65 ? false : true);
  }

  /// Constructs an ECPublic key from hex representation.
  factory ECPublic.fromHex(String hex) {
    return ECPublic.fromBytes(BytesUtils.fromHexString(hex));
  }

  /// toHex converts the ECPublic key to a hex-encoded string.
  /// If 'compressed' is true, the key is in compressed format.
  String toHex({bool compressed = true}) {
    if (compressed) {
      return BytesUtils.toHexString(publicKey.compressed);
    }
    return BytesUtils.toHexString(publicKey.uncompressed);
  }

  /// _toHash160 computes the RIPEMD160 hash of the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  List<int> _toHash160({bool compressed = true}) {
    final bytes = BytesUtils.fromHexString(toHex(compressed: compressed));
    return QuickCrypto.hash160(bytes);
  }

  /// toHash160 computes the RIPEMD160 hash of the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  String toHash160({bool compressed = true}) {
    final bytes = BytesUtils.fromHexString(toHex(compressed: compressed));
    return BytesUtils.toHexString(QuickCrypto.hash160(bytes));
  }

  /// toAddress generates a P2PKH (Pay-to-Public-Key-Hash) address from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2pkhAddress toAddress({bool compressed = true}) {
    final h16 = _toHash160(compressed: compressed);
    final toHex = BytesUtils.toHexString(h16);
    return P2pkhAddress.fromHash160(addrHash: toHex);
  }

  /// toSegwitAddress generates a P2WPKH (Pay-to-Witness-Public-Key-Hash) SegWit address
  /// from the ECPublic key. If 'compressed' is true, the key is in compressed format.
  P2wpkhAddress toSegwitAddress({bool compressed = true}) {
    final h16 = _toHash160(compressed: compressed);
    final toHex = BytesUtils.toHexString(h16);

    return P2wpkhAddress.fromProgram(program: toHex);
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
  P2shAddress toP2pkhInP2sh({bool compressed = true, useBCHP2sh32 = false}) {
    final addr = toAddress(compressed: compressed);
    final script = addr.toScriptPubKey();
    if (useBCHP2sh32) {
      return P2shAddress.fromHash160(
          addrHash: BytesUtils.toHexString(
              QuickCrypto.sha256DoubleHash(script.toBytes())),
          type: P2shAddressType.p2pkhInP2sh32);
    }
    return P2shAddress.fromScript(
        script: script, type: P2shAddressType.p2pkhInP2sh);
  }

  /// toP2pkInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2PK (Pay-to-Public-Key) script derived from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2shAddress toP2pkInP2sh(
      {bool compressed = true, bool useBCHP2sh32 = false}) {
    final script = toRedeemScript(compressed: compressed);
    if (useBCHP2sh32) {
      return P2shAddress.fromHash160(
          addrHash: BytesUtils.toHexString(
              QuickCrypto.sha256DoubleHash(script.toBytes())),
          type: P2shAddressType.p2pkInP2sh32);
    }
    return P2shAddress.fromScript(
        script: script, type: P2shAddressType.p2pkInP2sh);
  }

  /// ToTaprootAddress generates a P2TR(Taproot) address from the ECPublic key
  /// and an optional script. The 'script' parameter can be used to specify
  /// custom spending conditions.
  P2trAddress toTaprootAddress({List<List<Script>>? scripts}) {
    final pubKey = toTapRotHex(script: scripts);
    return P2trAddress.fromProgram(program: pubKey);
  }

  /// toP2wpkhInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2WPKH (Pay-to-Witness-Public-Key-Hash) script derived from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2shAddress toP2wpkhInP2sh({bool compressed = true}) {
    final addr = toSegwitAddress(compressed: compressed);
    return P2shAddress.fromScript(
        script: addr.toScriptPubKey(), type: P2shAddressType.p2wpkhInP2sh);
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
    return P2wshAddress.fromScript(
        script: toP2wshScript(compressed: compressed));
  }

  /// toP2wshInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2WSH (Pay-to-Witness-Script-Hash) script derived from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2shAddress toP2wshInP2sh({bool compressed = true}) {
    final p2sh = toP2wshAddress(compressed: compressed);
    return P2shAddress.fromScript(
        script: p2sh.toScriptPubKey(), type: P2shAddressType.p2wshInP2sh);
  }

  /// toBytes returns the uncompressed byte representation of the ECPublic key.
  List<int> toBytes({bool whitPrefix = true}) {
    if (!whitPrefix) {
      return publicKey.uncompressed.sublist(1);
    }
    return publicKey.uncompressed;
  }

  /// toCompressedBytes returns the compressed byte representation of the ECPublic key.
  List<int> toCompressedBytes() {
    return publicKey.compressed;
  }

  /// returns the x coordinate only as hex string after tweaking (needed for taproot)
  String toTapRotHex({List<List<Script>>? script}) {
    final scriptBytes =
        script?.map((e) => e.map((e) => e.toBytes()).toList()).toList();
    final pubKey = P2TRUtils.tweakPublicKey(
        publicKey.point as ProjectiveECCPoint,
        script: scriptBytes);
    return BytesUtils.toHexString(
        BigintUtils.toBytes(pubKey.x, length: publicKey.point.curve.baselen));
  }

  /// toXOnlyHex extracts and returns the x-coordinate (first 32 bytes) of the ECPublic key
  /// as a hexadecimal string.
  String toXOnlyHex() {
    return BytesUtils.toHexString(publicKey.uncompressed.sublist(1, 33));
  }

  /// returns true if the message was signed with this public key's
  bool verify(List<int> message, List<int> signature,
      {String messagePrefix = '\x18Bitcoin Signed Message:\n'}) {
    final verifyKey = BitcoinVerifier.fromKeyBytes(toBytes());
    return verifyKey.verifyMessage(message, messagePrefix, signature);
  }

  /// returns true if the message was signed with this public key's
  bool verifyTransaactionSignature(List<int> message, List<int> signature) {
    final verifyKey = BitcoinVerifier.fromKeyBytes(toBytes());
    return verifyKey.verifyTransaction(message, signature);
  }

  /// returns true if the message was signed with this public key's
  bool verifySchnorrTransactionSignature(List<int> message, List<int> signature,
      {List<dynamic>? tapleafScripts, bool isTweak = true}) {
    final verifyKey = BitcoinVerifier.fromKeyBytes(toBytes());
    return verifyKey.verifySchnorr(message, signature,
        tapleafScripts: tapleafScripts, isTweak: isTweak);
  }
}
