import 'package:bitcoin_base/bitcoin_base.dart' show BIP137Mode;
import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

typedef PublicKeyType = CryptoKeyEncoding;

class ECPublic {
  final Secp256k1PublicKey publicKey;
  const ECPublic(this.publicKey);

  factory ECPublic.fromBip32(Bip32PublicKey publicKey) {
    if (publicKey.type != CryptoKeyType.secp256k1) {
      throw BuError(DefaultErrorType.badPublicKey, 
        'invalid public key curve for bitcoin',
      );
    }
    return ECPublic(publicKey.pubKey as Secp256k1PublicKey);
  }

  /// Constructs an ECPublic key from a byte representation.
  factory ECPublic.fromBytes(List<int> public) {
    final publicKey = Secp256k1PublicKey.fromBytes(public);
    return ECPublic(publicKey);
  }

  /// Constructs an ECPublic key from hex representation.
  factory ECPublic.fromHex(String hex) {
    return ECPublic.fromBytes(BytesUtils.fromHexString(hex));
  }

  /// toHex converts the ECPublic key to a hex-encoded string.
  /// The public key is encoded according to `mode`.
  String toHex({PublicKeyType mode = PublicKeyType.base}) {
    return BytesUtils.toHexString(toBytes(mode: mode));
  }

  /// toHash160 computes the hash160 (SHA-256 then RIPEMD-160) of the ECPublic key.
  /// The public key is encoded according to `mode`.
  BuBytes toHash160({PublicKeyType mode = PublicKeyType.base}) {
    final bytes = BytesUtils.fromHexString(toHex(mode: mode));
    return QuickCrypto.hash160(bytes).asImmutableBytes;
  }

  /// toHash160Hex computes the hash160 of the ECPublic key and returns it as a hex string.
  /// The public key is encoded according to `mode`.
  String toHash160Hex({PublicKeyType mode = PublicKeyType.base}) {
    return BytesUtils.toHexString(toHash160(mode: mode));
  }

  /// toAddress generates a P2PKH (Pay-to-Public-Key-Hash) address from the ECPublic key.
  /// The public key is encoded according to `mode`.
  P2pkhAddress toAddress({
    PublicKeyType mode = PublicKeyType.base,
    bool bchToken = false,
  }) {
    final h16 = toHash160(mode: mode);
    final toHex = BytesUtils.toHexString(h16);
    return P2pkhAddress.fromHash160(
      addrHash: toHex,
      type: bchToken ? P2pkhAddressType.p2pkhwt : P2pkhAddressType.p2pkh,
    );
  }

  /// toSegwitAddress generates a P2WPKH (Pay-to-Witness-Public-Key-Hash) SegWit address
  /// from the ECPublic key. The public key is encoded according to `mode`.
  P2wpkhAddress toSegwitAddress() {
    final h16 = toHash160();
    final toHex = BytesUtils.toHexString(h16);

    return P2wpkhAddress.fromProgram(program: toHex);
  }

  /// toP2pkAddress generates a P2PK (Pay-to-Public-Key) address from the ECPublic key.
  /// The public key is encoded according to `mode`.
  P2pkAddress toP2pkAddress({PublicKeyType mode = PublicKeyType.base}) {
    return P2pkAddress(publicKey: toHex(mode: mode));
  }

  /// toRedeemScript generates a redeem script from the ECPublic key.
  /// The public key is encoded according to `mode`.
  Script toRedeemScript({PublicKeyType mode = PublicKeyType.base}) {
    return Script(script: [toHex(mode: mode), BitcoinOpcode.opCheckSig]);
  }

  /// toP2pkhInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2PK (Pay-to-Public-Key) script derived from the ECPublic key.
  /// The public key is encoded according to `mode`.
  P2shAddress toP2pkhInP2sh({
    PublicKeyType mode = PublicKeyType.base,
    bool useBCHP2sh32 = false,
    bool bchToken = false,
  }) {
    final addr = toAddress(mode: mode);
    final script = addr.toScriptPubKey();
    if (useBCHP2sh32) {
      return P2shAddress.fromHash160(
        addrHash: BytesUtils.toHexString(
          QuickCrypto.sha256DoubleHash(script.toBytes()),
        ),
        type:
            bchToken
                ? P2shAddressType.p2pkhInP2sh32wt
                : P2shAddressType.p2pkhInP2sh32,
      );
    }
    return P2shAddress.fromScript(
      script: script,
      type:
          bchToken
              ? P2shAddressType.p2pkhInP2shwt
              : P2shAddressType.p2pkhInP2sh,
    );
  }

  /// toP2pkInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2PK (Pay-to-Public-Key) script derived from the ECPublic key.
  /// The public key is encoded according to `mode`.
  P2shAddress toP2pkInP2sh({
    PublicKeyType mode = PublicKeyType.base,
    bool useBCHP2sh32 = false,
    bool bchToken = false,
  }) {
    final script = toRedeemScript(mode: mode);
    if (useBCHP2sh32) {
      return P2shAddress.fromHash160(
        addrHash: BytesUtils.toHexString(
          QuickCrypto.sha256DoubleHash(script.toBytes()),
        ),
        type:
            bchToken
                ? P2shAddressType.p2pkInP2sh32wt
                : P2shAddressType.p2pkInP2sh32,
      );
    }
    return P2shAddress.fromScript(
      script: script,
      type:
          bchToken ? P2shAddressType.p2pkInP2shwt : P2shAddressType.p2pkInP2sh,
    );
  }

  /// toTaprootAddress generates a P2TR (Taproot) address from the ECPublic key
  /// and an optional script tree. The 'treeScript' parameter can be used to specify
  /// custom spending conditions.
  P2trAddress toTaprootAddress({TaprootTree? treeScript}) {
    return P2trAddress.fromInternalKey(
      internalKey: toXOnly(),
      treeScript: treeScript,
    );
  }

  /// toP2wpkhInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2WPKH (Pay-to-Witness-Public-Key-Hash) script derived from the ECPublic key.
  /// The public key is encoded according to `mode`.
  P2shAddress toP2wpkhInP2sh() {
    final addr = toSegwitAddress();
    return P2shAddress.fromScript(
      script: addr.toScriptPubKey(),
      type: P2shAddressType.p2wpkhInP2sh,
    );
  }

  /// toP2wshScript generates a P2WSH (Pay-to-Witness-Script-Hash) script
  /// derived from the ECPublic key. The public key is encoded according to `mode`.
  Script toP2wshScript() {
    return Script(
      script: [
        BitcoinOpcode.op1,
        toHex(),
        BitcoinOpcode.op1,
        BitcoinOpcode.opCheckMultiSig,
      ],
    );
  }

  /// toNativeWitnessScript generates the witness script for a native segwit address type.
  /// Returns the scriptPubKey for P2WPKH and P2WSH.
  Script toNativeWitnessScript(SegwitAddressType type) {
    return switch (type) {
      SegwitAddressType.p2wpkh => toSegwitAddress().toScriptPubKey(),
      SegwitAddressType.p2wsh => toP2wshScript(),
      SegwitAddressType.p2tr =>
        throw BuError(DefaultErrorType.unsupported, 
          "P2TR is not supported for native witness script. Use toTaprootAddress().toScriptPubKey().",
        ),
    };
  }

  /// toP2shRedeemScript generates the redeem script for a P2SH address
  /// wrapping various address types. The public key is encoded according to `mode`.
  Script toP2shRedeemScript(
    P2shAddressType type, {
    PublicKeyType mode = PublicKeyType.base,
  }) {
    if (!type.supportedKeyEncoding.contains(mode)) {
      throw BuError(DefaultErrorType.unsupported, 
        "${type.name} does not support ${mode.name} public key encoding.",
      );
    }
    return switch (type) {
      P2shAddressType.p2wshInP2sh => toP2wshAddress().toScriptPubKey(),
      P2shAddressType.p2wpkhInP2sh => toSegwitAddress().toScriptPubKey(),
      P2shAddressType.p2pkInP2sh ||
      P2shAddressType.p2pkInP2sh32 ||
      P2shAddressType.p2pkInP2shwt ||
      P2shAddressType.p2pkInP2sh32wt => toRedeemScript(mode: mode),
      P2shAddressType.p2pkhInP2sh ||
      P2shAddressType.p2pkhInP2sh32 ||
      P2shAddressType.p2pkhInP2shwt ||
      P2shAddressType.p2pkhInP2sh32wt => toAddress(mode: mode).toScriptPubKey(),
    };
  }

  /// generateAddress generates a Bitcoin address from the ECPublic key.
  /// Returns a [BitcoinBaseAddress] for the given [addressType] and [encoding].
  BitcoinBaseAddress generateAddress({
    required BitcoinAddressType addressType,
    required CryptoKeyEncoding encoding,
  }) {
    if (!addressType.supportedKeyEncoding.contains(encoding)) {
      throw BuError(DefaultErrorType.unsupported, 
        "${addressType.name} does not support ${encoding.name} encoding.",
      );
    }
    return switch (addressType) {
      PubKeyAddressType.p2pk => toP2pkAddress(mode: encoding),
      P2pkhAddressType.p2pkh || P2pkhAddressType.p2pkhwt => toAddress(
        mode: encoding,
        bchToken: addressType == P2pkhAddressType.p2pkhwt,
      ),
      P2shAddressType.p2wshInP2sh when encoding == CryptoKeyEncoding.base =>
        toP2wshInP2sh(),
      P2shAddressType.p2wpkhInP2sh when encoding == CryptoKeyEncoding.base =>
        toP2wpkhInP2sh(),
      P2shAddressType.p2pkhInP2sh ||
      P2shAddressType.p2pkhInP2shwt => toP2pkhInP2sh(
        useBCHP2sh32: false,
        mode: encoding,
        bchToken: addressType == P2shAddressType.p2pkhInP2shwt,
      ),
      P2shAddressType.p2pkInP2sh ||
      P2shAddressType.p2pkInP2shwt => toP2pkInP2sh(
        useBCHP2sh32: false,
        mode: encoding,
        bchToken: addressType == P2shAddressType.p2pkInP2shwt,
      ),
      P2shAddressType.p2pkhInP2sh32 ||
      P2shAddressType.p2pkhInP2sh32wt => toP2pkhInP2sh(
        useBCHP2sh32: true,
        mode: encoding,
        bchToken: addressType == P2shAddressType.p2pkhInP2sh32wt,
      ),
      P2shAddressType.p2pkInP2sh32 ||
      P2shAddressType.p2pkInP2sh32wt => toP2pkInP2sh(
        useBCHP2sh32: true,
        mode: encoding,
        bchToken: addressType == P2shAddressType.p2pkInP2sh32wt,
      ),
      SegwitAddressType.p2wpkh when encoding == CryptoKeyEncoding.base =>
        toSegwitAddress(),
      SegwitAddressType.p2wsh when encoding == CryptoKeyEncoding.base =>
        toP2wshAddress(),
      SegwitAddressType.p2tr when encoding == CryptoKeyEncoding.base =>
        toTaprootAddress(),
      _ => throw BuError(DefaultErrorType.unsupported, "Unsupported address type."),
    };
  }

  BitcoinNetworkAddress generateNetworkAddress({
    required BitcoinAddressType addressType,
    required CryptoKeyEncoding encoding,
    required BasedUtxoNetwork network,
  }) {
    if (!network.supportedAddress.contains(addressType)) {
      throw BuError(DefaultErrorType.unsupported, 
        "${network.name} does not support ${addressType.name} address.",
      );
    }
    final baseAddr = generateAddress(
      addressType: addressType,
      encoding: encoding,
    );
    return BitcoinNetworkAddress.fromBaseAddress(
      address: baseAddr,
      network: network,
    );
  }

  /// toP2wshAddress generates a P2WSH (Pay-to-Witness-Script-Hash) address
  /// from the ECPublic key. The public key is encoded according to `mode`.
  P2wshAddress toP2wshAddress() {
    return P2wshAddress.fromScript(script: toP2wshScript());
  }

  /// toP2wshInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2WSH (Pay-to-Witness-Script-Hash) script derived from the ECPublic key.
  /// The public key is encoded according to `mode`.
  P2shAddress toP2wshInP2sh() {
    final p2sh = toP2wshAddress();
    return P2shAddress.fromScript(
      script: p2sh.toScriptPubKey(),
      type: P2shAddressType.p2wshInP2sh,
    );
  }

  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.uncompressed}) {
    return publicKey.toBytes(mode: mode);
  }

  /// returns the x coordinate only as hex string after tweaking (needed for taproot)
  String tweakPublicKey({TaprootTree? treeScript}) {
    final pubKey = TaprootUtils.tweakPublicKey(
      toBytes(mode: CryptoKeyEncoding.base),
      treeScript: treeScript,
    );
    return BytesUtils.toHexString(pubKey.toXOnly());
  }

  BuBytes toXOnly() {
    return BuBytes.from(publicKey.toBytes().sublist(1));
  }

  /// toXOnlyHex extracts and returns the x-coordinate (first 32 bytes) of the ECPublic key
  /// as a hexadecimal string.
  String toXOnlyHex() {
    return BytesUtils.toHexString(toXOnly());
  }

  /// Verifies a Bitcoin signed message using the provided signature.
  ///
  /// This method checks if the given signature is valid for the specified message,
  /// following Bitcoin's message signing format.
  ///
  /// - [message]: The original message that was signed.
  /// - [signature]: The compact ECDSA signature to verify.
  /// - [messagePrefix]: The prefix used in Bitcoin's message signing.
  bool verify({
    required List<int> message,
    required List<int> signature,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
  }) {
    final verifyKey = BitcoinSignatureVerifier.fromKeyBytes(toBytes());
    return verifyKey.verifyMessageSignature(
      message: message,
      messagePrefix: messagePrefix,
      signature: signature,
    );
  }

  /// Recovers the BIP-137 public key from a signed message and signature.
  ///
  /// This method extracts the public key from a Bitcoin-signed message using the
  /// BIP-137 standard, which allows for signature-based public key recovery.
  ///
  /// - [message]: The original message that was signed.
  /// - [signature]: The Base64-encoded signature.
  /// - [messagePrefix]: The prefix used in Bitcoin's message signing.
  ECPublic getBip137PublicKey({
    required List<int> message,
    required String signature,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
  }) {
    final signatureBytes = StringUtils.encode(
      signature,
      encoding: StringEncoding.base64,
    );
    final ecdsaPubKey = BitcoinSignatureVerifier.recoverPublicKey(
      message: message,
      signature: signatureBytes,
      messagePrefix: messagePrefix,
    );
    return ECPublic.fromBytes(ecdsaPubKey.toBytes());
  }

  /// Recovers the BIP-137 address from a signed message and signature.
  ///
  /// This method extracts the public key from a Bitcoin-signed message using the
  /// BIP-137 standard, and then derives the appropriate Bitcoin address based on
  /// the signature's recovery mode (e.g., P2PKH, P2WPKH, P2SH-P2WPKH).
  ///
  /// - [message]: The original message that was signed.
  /// - [signature]: The Base64-encoded signature.
  /// - [messagePrefix]: The prefix used in Bitcoin's message signing
  ///   (default is `BitcoinSignerUtils.signMessagePrefix`).
  ///
  /// Returns the corresponding Bitcoin address derived from the recovered public key.
  /// The address type is determined by the recovery mode of the signature (e.g.,
  /// uncompressed, compressed, SegWit, or P2SH-wrapped SegWit).
  BitcoinBaseAddress getBip137Address({
    required List<int> message,
    required String signature,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
  }) {
    final signatureBytes = StringUtils.encode(
      signature,
      encoding: StringEncoding.base64,
    );
    final ecdsaPubKey = BitcoinSignatureVerifier.recoverPublicKey(
      message: message,
      signature: signatureBytes,
      messagePrefix: messagePrefix,
    );
    final publicKey = ECPublic.fromBytes(ecdsaPubKey.toBytes());
    final mode = BIP137Mode.findMode(signatureBytes[0]);
    return switch (mode) {
      BIP137Mode.p2pkhUncompressed => publicKey.toAddress(
        mode: CryptoKeyEncoding.uncompressed,
      ),
      BIP137Mode.p2pkhCompressed => publicKey.toAddress(),
      BIP137Mode.p2wpkh => publicKey.toSegwitAddress(),
      BIP137Mode.p2shP2wpkh => publicKey.toP2wpkhInP2sh(),
    };
  }

  /// Verifies that a BIP-137 signature matches the expected Bitcoin address.
  ///
  /// This method checks whether the address derived from the BIP-137 signature
  /// matches the provided address by comparing the corresponding scriptPubKey.
  ///
  /// - [message]: The original message that was signed.
  /// - [signature]: The Base64-encoded signature to verify.
  /// - [address]: The expected Bitcoin address to compare against.
  /// - [messagePrefix]: The prefix used in Bitcoin's message signing
  bool verifyBip137Address({
    required List<int> message,
    required String signature,
    required BitcoinBaseAddress address,
    String messagePrefix = BitcoinSignerUtils.signMessagePrefix,
  }) {
    final signerAddress = getBip137Address(
      message: message,
      signature: signature,
      messagePrefix: messagePrefix,
    );
    return address.toScriptPubKey() == signerAddress.toScriptPubKey();
  }

  /// Verifies an ECDSA DER-encoded signature against a given digest.
  ///
  /// This method checks whether the provided DER-encoded signature is valid for
  /// the given digest using the public key.
  ///
  /// - [digest]: The hash or message digest that was signed.
  /// - [signature]: The DER-encoded ECDSA signature to verify.
  ///
  /// Returns `true` if the signature is valid for the given digest, otherwise `false`.
  bool verifyDerSignature({
    required List<int> digest,
    required List<int> signature,
  }) {
    final verifyKey = BitcoinSignatureVerifier.fromKeyBytes(toBytes());
    return verifyKey.verifyECDSADerSignature(
      digest: digest,
      signature: signature,
    );
  }

  /// Verifies a BIP-340 Taproot signature for a given message.
  ///
  /// - [digest]: The original message or transaction digest that was signed.
  /// - [signature]: The BIP-340 signature to verify.
  /// - [treeScript]: Taproot script tree for Tweaking with public key.
  /// - [merkleRoot]: Merkle root for the Taproot tree. If provided, this overrides the default computation of the Merkle root from [treeScript].
  /// - [tweak]: If `true`, the internal key is tweaked, either with or without [treeScript] or [merkleRoot], before verifying.
  /// - [tapTweakHash]: If provided, it will be used directly instead of tweaking with the internal key.
  bool verifyBip340Signature({
    required List<int> digest,
    required List<int> signature,
    TaprootTree? treeScript,
    List<int>? merkleRoot,
    List<int>? tapTweakHash,
    bool tweak = true,
  }) {
    if (!tweak &&
        (treeScript != null || merkleRoot != null || tapTweakHash != null)) {
      throw BuError(DefaultErrorType.invalidArgument, 
        "Invalid parameters: 'tweak' must be true when specifying 'treeScript', 'merkleRoot', or 'tapTweakHash'.",
      );
    }
    if (merkleRoot != null && treeScript != null) {
      throw BuError(DefaultErrorType.invalidArgument, 
        "Use either merkleRoot or treeScript to generate merkle, not both.",
      );
    }
    if (tapTweakHash != null && (treeScript != null || merkleRoot != null)) {
      throw BuError(DefaultErrorType.invalidArgument, 
        "Use either tapTweakHash or (treeScript/merkleRoot), not both.",
      );
    }
    if (signature.length >
        CryptoSignerConst.ecdsaSignatureLength +
            CryptoSignerConst.ecdsaRecoveryIdLength) {
      signature = signature.sublist(0, CryptoSignerConst.ecdsaSignatureLength);
    }
    final verifyKey = BitcoinSignatureVerifier.fromKeyBytes(toBytes());
    return verifyKey.verifyBip340Signature(
      digest: digest,
      signature: signature,
      tapTweakHash:
          tweak
              ? tapTweakHash ??
                  TaprootUtils.calculateTweek(
                    toXOnly(),
                    treeScript: merkleRoot != null ? null : treeScript,
                    merkleRoot: merkleRoot,
                  )
              : null,
    );
  }

  /// Verifies a Schnorr(old style) signature for a given digest.
  ///
  /// This method checks whether the provided Schnorr signature is valid for
  /// the given digest using the public key.
  ///
  /// - [digest]: The hash or message digest that was signed.
  /// - [signature]: The Schnorr signature to verify.
  ///
  /// Returns `true` if the signature is valid for the given digest, otherwise `false`.
  bool verifySchnorrSignature({
    required List<int> digest,
    required List<int> signature,
  }) {
    final verifyKey = BitcoinSignatureVerifier.fromKeyBytes(toBytes());
    return verifyKey.verifySchnorrSignature(
      digest: digest,
      signature: signature,
    );
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ECPublic) return false;
    return other.publicKey == publicKey;
  }

  @override
  int get hashCode => publicKey.hashCode;
}
