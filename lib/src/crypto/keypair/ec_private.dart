import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import 'ec_public.dart';

enum BIP137Mode {
  p2pkhUncompressed(0),
  p2pkhCompressed(4),
  p2shP2wpkh(8),
  p2wpkh(12);

  const BIP137Mode(this.header);
  static BIP137Mode fromValue(int? header) {
    return values.firstWhere(
      (e) => e.header == header,
      orElse:
          () =>
              throw BuError(
                DefaultErrorType.notFound,
                "No BIP137Mode found for the given header value",
              ),
    );
  }

  final int header;
  static BIP137Mode findMode(int header) {
    if (header < 27 || header > 42) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "BIP137 header byte out of range.",
        details: {'header': '$header', 'expected': '27..42'},
      );
    }
    if (header >= 39) {
      return BIP137Mode.p2wpkh;
    } else if (header >= 35) {
      return BIP137Mode.p2shP2wpkh;
    } else if (header >= 31) {
      return BIP137Mode.p2pkhCompressed;
    }
    return BIP137Mode.p2pkhUncompressed;
  }
}

/// Represents an ECDSA private key.
class ECPrivate with SecretState {
  final Secp256k1PrivateKey secretKey;
  const ECPrivate(this.secretKey);

  /// creates an object from hex
  factory ECPrivate.fromHex(String keyHex) {
    final bytes = BytesUtils.fromHexString(keyHex);
    try {
      return ECPrivate.fromBytes(bytes);
    } finally {
      bytes.forceZero();
    }
  }

  /// creates an object from raw 32 bytes
  factory ECPrivate.fromBytes(List<int> prive) {
    final key = Secp256k1PrivateKey.fromBytes(prive);
    return ECPrivate(key);
  }

  /// returns the corresponding ECPublic object
  ECPublic getPublic() => ECPublic(secretKey.publicKey);

  /// creates an object from a WIF of WIFC format (string)
  factory ECPrivate.fromWif(String wif, {List<int>? netVersion}) {
    netVersion ??= BitcoinNetwork.mainnet.wifNetVer;
    if (netVersion == null) {
      throw BuError(DefaultErrorType.invalidArgument, "Missing WIF prefix.");
    }
    final decode = WifDecoder.decode(wif, netVer: netVersion);
    try {
      return ECPrivate.fromBytes(decode.$1);
    } finally {
      decode.$1.zero();
    }
  }

  /// returns as WIFC (compressed) or WIF format (string)
  String toWif({
    CryptoKeyEncoding pubKeyMode = CryptoKeyEncoding.base,
    BitcoinNetwork network = BitcoinNetwork.mainnet,
  }) {
    final wif = network.wifNetVer;
    if (wif == null) {
      throw BuError(
        DefaultErrorType.invalidState,
        "Missing network wif prefix.",
        details: {"network": network.name},
      );
    }
    return secretKey.takeSecretKey().useValue(
      (k) => WifEncoder.encode(k, netVer: wif, pubKeyMode: pubKeyMode),
    );
  }

  /// returns the key's raw bytes
  SecretBytes toBytes() {
    return secretKey.toBytes();
  }

  /// returns the key's as hex
  String toHex() {
    return secretKey.takeSecretKey().toHex();
  }

  /// Signs a message using BIP-137 format for standardized Bitcoin message signing.
  ///
  /// This method produces a compact ECDSA signature with a modified recovery ID
  /// based on the specified BIP-137 signing mode.
  ///
  /// - [message]: The raw message to be signed.
  /// - [messagePrefix]: The prefix used for Bitcoin's message signing
  ///   (default is `BitcoinSignerUtils.signMessagePrefix`).
  /// - [mode]: The BIP-137 mode specifying the key type (e.g., P2PKH uncompressed, compressed, SegWit, etc.).
  /// - [extraEntropy]: Optional extra entropy to modify the signature (default is an empty list).
  ///
  /// The recovery ID (first byte of the signature) is adjusted based on the
  /// BIP-137 mode's header value. The final signature is encoded in Base64.
  String signBip137(
    List<int> message, {
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
    BIP137Mode mode = BIP137Mode.p2pkhUncompressed,
    List<int> extraEntropy = const [],
  }) {
    final btcSigner = BitcoinKeySigner(secretKey);
    final signature = btcSigner.signMessage(
      message: message,
      messagePrefix: messagePrefix,
      extraEntropy: extraEntropy,
    );
    int rId = signature.encoded[0] + mode.header;
    return StringUtils.decode([
      rId,
      ...signature.encoded.sublist(1),
    ], encoding: StringEncoding.base64);
  }

  /// Signs a message using Bitcoin's message signing format.
  ///
  /// This method produces a compact ECDSA signature for a given message, following
  /// the Bitcoin Signed Message standard.
  ///
  /// - [message]: The raw message to be signed.
  /// - [messagePrefix]: The prefix used for Bitcoin's message signing.
  /// - [extraEntropy]: Optional extra entropy to modify the signature.
  String signMessage(
    List<int> message, {
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
    List<int> extraEntropy = const [],
  }) {
    final btcSigner = BitcoinKeySigner(secretKey);
    final signature = btcSigner.signMessage(
      message: message,
      messagePrefix: messagePrefix,
      extraEntropy: extraEntropy,
    );
    return BytesUtils.toHexString(signature.signature.toBytes());
  }

  /// Signs the given transaction digest using ECDSA (DER-encoded).
  ///
  /// - [txDigest]: The transaction digest (message) to sign.
  /// - [sighash]: The sighash flag to append (default is SIGHASH_ALL).
  String signECDSA(
    List<int> txDigest, {
    int? sighash = BitcoinOpCodeConst.sighashAll,
    List<int> extraEntropy = const [],
  }) {
    final btcSigner = BitcoinKeySigner(secretKey);
    List<int> signature =
        btcSigner.signECDSADer(txDigest, extraEntropy: extraEntropy).encoded;
    if (sighash != null) {
      signature = <int>[...signature, sighash];
    }
    return BytesUtils.toHexString(signature);
  }

  /// Signs the given transaction digest using Schnorr signature (old style).
  ///
  /// This method is primarily useful for networks like Bitcoin Cash (BCH) that
  /// support Schnorr signatures in a legacy format.
  /// In BCH OP_CHECKMULTISIG and OP_CHECKMULTISIGVERIFY, will not be upgraded to allow Schnorr signatures.
  /// https://github.com/bitcoincashorg/bitcoincash.org/blob/master/spec/2019-05-15-schnorr.md
  /// - [txDigest]: The transaction digest (message) to sign.
  /// - [sighash]: The sighash flag to append (default is SIGHASH_DEFAULT).
  String signSchnorr(
    List<int> txDigest, {
    int sighash = BitcoinOpCodeConst.sighashDefault,
    List<int> extraEntropy = const [],
  }) {
    final btcSigner = BitcoinKeySigner(secretKey);
    List<int> signature =
        btcSigner.signSchnorr(txDigest, extraEntropy: extraEntropy).encoded;
    if (sighash != BitcoinOpCodeConst.sighashDefault) {
      signature = <int>[...signature, sighash];
    }
    return BytesUtils.toHexString(signature);
  }

  /// Signs a Taproot transaction digest and returns the signature.
  ///
  /// - [txDigest]: The transaction digest to be signed.
  /// - [sighash]: The sighash type (default: `TAPROOT_SIGHASH_ALL`).
  /// - [treeScript]: Taproot script tree for Tweaking with public key.
  /// - [merkleRoot]: Merkle root for the Taproot tree. If provided, this overrides the default computation of the Merkle root from [treeScript].
  /// - [tweak]: If `true`, the internal key is tweaked, either with or without [treeScript] or [merkleRoot], before signing.
  /// - [tapTweakHash]: If provided, it will be used directly instead of tweaking with the internal key.
  String signBip340(
    List<int> txDigest, {
    int sighash = BitcoinOpCodeConst.sighashDefault,
    TaprootTree? treeScript,
    List<int>? merkleRoot,
    List<int>? tapTweakHash,
    List<int>? aux,
    bool tweak = true,
  }) {
    if (!tweak &&
        (treeScript != null || merkleRoot != null || tapTweakHash != null)) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid parameters: 'tweak' must be true when specifying 'treeScript', 'merkleRoot', or 'tapTweakHash'.",
      );
    }
    if (merkleRoot != null && treeScript != null) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Use either merkleRoot or treeScript to generate merkle, not both.",
      );
    }
    if (tapTweakHash != null && (treeScript != null || merkleRoot != null)) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Use either tapTweakHash or (treeScript/merkleRoot), not both.",
      );
    }
    final btcSigner = BitcoinKeySigner(secretKey);
    List<int> signature =
        btcSigner
            .signBip340(
              digest: txDigest,
              aux: aux,
              tapTweakHash:
                  tweak
                      ? tapTweakHash ??
                          TaprootUtils.calculateTweek(
                            getPublic().toXOnly(),
                            treeScript: merkleRoot != null ? null : treeScript,
                            merkleRoot: merkleRoot,
                          )
                      : null,
            )
            .encoded;
    if (sighash != BitcoinOpCodeConst.sighashDefault) {
      signature = <int>[...signature, sighash];
    }
    return BytesUtils.toHexString(signature);
  }

  static ECPrivate random() {
    return ECPrivate(Secp256k1PrivateKey.random());
  }

  @override
  void dispose() {
    secretKey.dispose();
  }
}
