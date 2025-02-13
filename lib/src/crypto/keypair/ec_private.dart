import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// Represents an ECDSA private key.
class ECPrivate {
  final Bip32PrivateKey prive;
  const ECPrivate(this.prive);

  /// creates an object from hex
  factory ECPrivate.fromHex(String keyHex) {
    return ECPrivate.fromBytes(BytesUtils.fromHexString(keyHex));
  }

  /// creates an object from raw 32 bytes
  factory ECPrivate.fromBytes(List<int> prive) {
    final key = Bip32PrivateKey.fromBytes(prive, Bip32KeyData(),
        Bip32Const.mainNetKeyNetVersions, EllipticCurveTypes.secp256k1);
    return ECPrivate(key);
  }

  /// returns the corresponding ECPublic object
  ECPublic getPublic() =>
      ECPublic.fromHex(BytesUtils.toHexString(prive.publicKey.compressed));

  /// creates an object from a WIF of WIFC format (string)
  factory ECPrivate.fromWif(String wif, {required List<int>? netVersion}) {
    final decode = WifDecoder.decode(wif,
        netVer: netVersion ?? BitcoinNetwork.mainnet.wifNetVer);
    return ECPrivate.fromBytes(decode.item1);
  }

  /// returns as WIFC (compressed) or WIF format (string)
  String toWif(
      {PubKeyModes pubKeyMode = PubKeyModes.compressed,
      BitcoinNetwork network = BitcoinNetwork.mainnet}) {
    return WifEncoder.encode(toBytes(),
        netVer: network.wifNetVer, pubKeyMode: pubKeyMode);
  }

  /// returns the key's raw bytes
  List<int> toBytes() {
    return prive.raw;
  }

  String toHex() {
    return BytesUtils.toHexString(prive.raw);
  }

  /// Returns a Bitcoin compact signature in hex
  String signMessage(List<int> message,
      {String messagePrefix = '\x18Bitcoin Signed Message:\n'}) {
    final btcSigner = BitcoinSigner.fromKeyBytes(toBytes());
    final signature = btcSigner.signMessage(message, messagePrefix);
    return BytesUtils.toHexString(signature);
  }

  /// sign transaction digest  and returns the signature.
  String signInput(List<int> txDigest,
      {int sigHash = BitcoinOpCodeConst.SIGHASH_ALL}) {
    final btcSigner = BitcoinSigner.fromKeyBytes(toBytes());
    var signature = btcSigner.signTransaction(txDigest);
    signature = <int>[...signature, sigHash];
    return BytesUtils.toHexString(signature);
  }

  String signSchnorr(List<int> txDigest,
      {int sighash = BitcoinOpCodeConst.TAPROOT_SIGHASH_ALL}) {
    final btcSigner = BitcoinSigner.fromKeyBytes(toBytes());
    var signatur = btcSigner.signSchnorrTransaction(txDigest,
        tapScripts: [], tweak: false);
    if (sighash != BitcoinOpCodeConst.TAPROOT_SIGHASH_ALL) {
      signatur = <int>[...signatur, sighash];
    }
    return BytesUtils.toHexString(signatur);
  }

  /// sign taproot transaction digest and returns the signature.
  String signTapRoot(List<int> txDigest,
      {int sighash = BitcoinOpCodeConst.TAPROOT_SIGHASH_ALL,
      List<List<Script>> tapScripts = const [],
      bool tweak = true}) {
    assert(() {
      if (!tweak && tapScripts.isNotEmpty) {
        return false;
      }
      return true;
    }(),
        'When the tweak is false, the `tapScripts` are ignored, to use the tap script path, you need to consider the tweak value to be true.');
    final tapScriptBytes = !tweak
        ? []
        : tapScripts.map((e) => e.map((e) => e.toBytes()).toList()).toList();
    final btcSigner = BitcoinSigner.fromKeyBytes(toBytes());
    var signatur = btcSigner.signSchnorrTransaction(txDigest,
        tapScripts: tapScriptBytes, tweak: tweak);
    if (sighash != BitcoinOpCodeConst.TAPROOT_SIGHASH_ALL) {
      signatur = <int>[...signatur, sighash];
    }
    return BytesUtils.toHexString(signatur);
  }

  static ECPrivate random() {
    final secret = QuickCrypto.generateRandom();
    return ECPrivate.fromBytes(secret);
  }
}
