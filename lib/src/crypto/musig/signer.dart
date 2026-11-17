import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// A signer class for MuSig2, handling key aggregation, nonce generation,
/// signing, and partial signature aggregation.
///
/// Protocol flows run through blockchain_utils' musig2Key layer
/// ([Musig2PrivateKey]/[MuSig2AggregatePublicKey]); this class keeps the
/// Taproot-flavored bitcoin surface (EC keys, P2TR addresses, tweaks).
class Musig2Signer {
  /// A list of private keys for signing. This can be empty for public-only operations.
  final List<ECPrivate> privateKeys;

  /// A list of public keys used in the MuSig2 signing process.
  final List<ECPublic> publicKeys;

  /// Backing musig2Key: held secrets plus the aggregate public key.
  final Musig2PrivateKey key;

  /// Private constructor to enforce the use of the factory constructor.
  Musig2Signer._({
    required List<ECPrivate> privateKeys,
    required List<ECPublic> publicKeys,
    required this.key,
  }) : privateKeys = privateKeys.immutable,
       publicKeys = publicKeys.immutable;

  /// The aggregated MuSig2 public key, used for Taproot or MuSig2 signing.
  ///
  ECPublic get aggPublicKey =>
      ECPublic.fromBytes(key.publicKey.point.toBytes());

  /// Generates a new `Musig2Signer` instance by aggregating the provided public keys.
  ///
  /// - If `sortKeys` is `true`, the public keys will be lexicographically sorted before aggregation.
  /// - If `privateKeys` are provided, they will be used for signing.
  factory Musig2Signer.generate(
    List<ECPublic> publicKeys, {
    List<ECPrivate> privateKeys = const [],
    bool sortKeys = false,
  }) {
    final secpPubs = publicKeys.map((e) => e.publicKey).toList();
    List<ECPublic> ordered = publicKeys;
    List<Secp256k1PublicKey> orderedSecp = secpPubs;
    if (sortKeys) {
      final index = List<int>.generate(publicKeys.length, (i) => i)..sort(
        (a, b) => BytesUtils.compareBytes(
          secpPubs[a].toBytes(),
          secpPubs[b].toBytes(),
        ),
      );
      ordered = index.map((i) => publicKeys[i]).toList();
      orderedSecp = index.map((i) => secpPubs[i]).toList();
    }
    final MuSig2AggregatePublicKey agg;
    if (orderedSecp.length >= MuSig2Constants.minimumRequiredKey) {
      agg = MuSig2AggregatePublicKey.aggPublicKeys(orderedSecp);
    } else {
      // Degenerate sub-threshold group: aggregate point only, same as the
      // raw protocol path (no participant list to drive keyed nonce gen).
      agg = MuSig2AggregatePublicKey.aggPublicKey(
        blockchainUtils.api.muSig2.aggPublicKeys(
          orderedSecp.map((e) => e.toBytes()).toList(),
        ),
      );
    }
    return Musig2Signer._(
      privateKeys: privateKeys,
      publicKeys: ordered,
      key: Musig2PrivateKey.partial(
        publicKey: agg,
        secretKeys: privateKeys.map((e) => e.secretKey).toList(),
      ),
    );
  }

  /// Generates a Taproot address using the aggregated MuSig2 public key.
  ///
  /// - If a `scriptTree` is provided, it will be included in the Taproot address.
  P2trAddress toAddress({TaprootTree? scriptTree}) {
    return P2trAddress.fromInternalKey(
      internalKey: aggPublicKey.toXOnly(),
      treeScript: scriptTree,
    );
  }

  /// Generates a list of MuSig2 nonces for signing.
  ///
  /// - `rand` is optional random data for nonce generation.
  /// - `sk` (optional) is the private key for deterministic nonce generation.
  /// - `aggPubKey` is the aggregate public key in the MuSig2 session, used to generate nonces across multiple participants.
  /// - `msg` is the message being signed.
  /// - `extra` is additional data used in nonce generation.
  List<MuSig2Nonce> generateNonces({
    List<int>? rand,
    List<int>? sk,
    List<int>? aggPubKey,
    List<int>? msg,
    List<int>? extra,
  }) {
    final pubKeys = key.publicKey.publicKeys;
    if (pubKeys == null) {
      // Degenerate sub-threshold group: per-key protocol calls.
      return publicKeys
          .map(
            (e) => blockchainUtils.api.muSig2.nonceGenerate(
              publicKey: e.toBytes(mode: CryptoKeyEncoding.base),
              aggPubKey: aggPubKey,
              extra: extra,
              msg: msg,
              rand: rand,
              sk: sk,
            ),
          )
          .toList();
    }
    return key.generateNonces(
      MuSig2GenerateNoncesParams(
        rand: rand ?? QuickCrypto.generateRandom(length: 32),
        sk: sk,
        aggPubKey: aggPubKey,
        msg: msg,
        extra: extra,
      ),
    );
  }

  /// Generates a MuSig2 nonce for a participant.
  ///
  /// - `publicKey`: The public key of the participant.
  /// - `rand`: Optional random data used for nonce generation. If not provided, a random value will be generated.
  /// - `sk`: Optional private key for deterministic nonce generation. If provided, `rand` and `extra` will be ignored.
  /// - `aggPubKey`: The aggregate public key in the MuSig2 session, used to generate nonces across multiple participants.
  /// - `msg`: The message that is being signed, used to generate the nonce.
  /// - `extra`: Optional additional data to include in the nonce generation.
  ///
  /// Returns a `MuSig2Nonce` object containing the generated nonce data.
  MuSig2Nonce generateNonce(
    ECPublic publicKey, {
    List<int>? rand,
    List<int>? sk,
    List<int>? aggPubKey,
    List<int>? msg,
    List<int>? extra,
  }) {
    return blockchainUtils.api.muSig2.nonceGenerate(
      publicKey: publicKey.toBytes(mode: CryptoKeyEncoding.base),
      aggPubKey: aggPubKey,
      extra: extra,
      msg: msg,
      rand: rand,
      sk: sk,
    );
  }

  /// Aggregates multiple MuSig2 nonces into a single aggregated nonce.
  BuBytes aggNonce(List<MuSig2Nonce> nonces) {
    return blockchainUtils.api.muSig2
        .nonceAgg(nonces.map((e) => e.pubnonce).toList())
        .asImmutableBytes;
  }

  MuSig2Session _session({
    required List<int> aggnonce,
    required List<int> message,
    List<int>? merkleRoot,
    TaprootTree? treeScript,
    bool tweak = true,
  }) {
    return MuSig2Session(
      aggnonce: aggnonce,
      publicKeys:
          publicKeys
              .map((e) => e.toBytes(mode: CryptoKeyEncoding.base))
              .toList(),
      msg: message,
      tweaks: [
        if (tweak)
          MuSig2Tweak(
            tweak: TaprootUtils.calculateTweek(
              aggPublicKey.toXOnly(),
              treeScript: merkleRoot != null ? null : treeScript,
              merkleRoot: merkleRoot,
            ),
          ),
      ],
    );
  }

  /// Signs a message using the provided MuSig2 secret nonces.
  ///
  /// - Each signer must provide their secret nonce (`secNonces`).
  /// - The message (`message`) must be the same for all participants.
  /// - Returns a list of partial signatures.
  ///
  /// Throws an exception if a corresponding private key is not found.
  List<BuBytes> partialSign({
    required List<MuSig2Nonce> secNonces,
    required List<int> message,
    List<int>? merkleRoot,
    TaprootTree? treeScript,
    bool tweak = true,
    List<ECPrivate> extraKeys = const [],
  }) {
    final session = _session(
      aggnonce: aggNonce(secNonces),
      message: message,
      merkleRoot: merkleRoot,
      treeScript: treeScript,
      tweak: tweak,
    );
    final signingKey =
        extraKeys.isEmpty
            ? key
            : Musig2PrivateKey.partial(
              publicKey: key.publicKey,
              secretKeys: [
                ...key.secretKeys,
                ...extraKeys.map((e) => e.secretKey),
              ],
            );
    return secNonces
        .map(
          (n) =>
              signingKey
                  .partialSign(
                    MuSig2PartialSigningParams(session: session, nonce: n),
                  )
                  .signature,
        )
        .toList();
  }

  /// Aggregates the provided partial signatures into a final MuSig2 signature.
  ///
  /// - `signatures`: List of partial signatures from all participants.
  /// - `secNonces`: The secret nonces used for signing.
  /// - `message`: The message that was signed.
  ///
  /// Returns the final aggregated signature.
  BuBytes aggSigs({
    required List<List<int>> signatures,
    required List<MuSig2Nonce> secNonces,
    required List<int> message,
    int? sighash = BitcoinOpCodeConst.sighashDefault,
    List<int>? merkleRoot,
    TaprootTree? treeScript,
    bool tweak = true,
  }) {
    final session = _session(
      aggnonce: aggNonce(secNonces),
      message: message,
      merkleRoot: merkleRoot,
      treeScript: treeScript,
      tweak: tweak,
    );
    final aggSignature = blockchainUtils.api.muSig2.partialSigAgg(
      signatures: signatures,
      session: session,
    );
    if (sighash != null && sighash != BitcoinOpCodeConst.sighashDefault) {
      final bytes = BuBytes.empty()..addAll([...aggSignature, sighash]);
      return bytes.asImmutableBytes;
    }
    return aggSignature.asImmutableBytes;
  }

  /// Generates nonces, signs the message, and returns the final aggregated signature.
  ///
  /// This is a convenience method that performs all signing steps in one call.
  /// It is n-of-n only: nonces are generated for every key in [publicKeys] and
  /// every participant must contribute a secret. For a k-of-n subset, drive
  /// [generateNonce] (once per participating signer) → [partialSign] →
  /// [aggSigs] manually, or use [fullSignForSubset] when this machine holds
  /// the subset's secrets.
  ///
  /// - `digest`: The hash of the message to be signed.
  ///
  /// Returns the final aggregated signature.
  BuBytes fullSign(
    List<int> digest, {
    List<int>? merkleRoot,
    TaprootTree? treeScript,
    List<ECPrivate> extraKeys = const [],
    bool tweak = true,
  }) {
    final heldSecrets = key.secretKeys.length + extraKeys.length;
    if (heldSecrets != publicKeys.length) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Musig2Signer.fullSign is n-of-n only: holds $heldSecrets secret(s) for ${publicKeys.length} public key(s). "
        "For a k-of-n subset use generateNonce per participant → partialSign → aggSigs, "
        "or fullSignForSubset when this machine holds the subset secrets.",
      );
    }
    final nonces = generateNonces();
    final signatures = partialSign(
      secNonces: nonces,
      message: digest,
      merkleRoot: merkleRoot,
      treeScript: treeScript,
      tweak: tweak,
      extraKeys: extraKeys,
    );
    return aggSigs(
      signatures: signatures,
      secNonces: nonces,
      message: digest,
      merkleRoot: merkleRoot,
      treeScript: treeScript,
      tweak: tweak,
    );
  }

  BuBytes fullSignForSubset({
    required List<ECPublic> participants,
    required List<int> digest,
    List<int>? merkleRoot,
    TaprootTree? treeScript,
    List<ECPrivate> extraKeys = const [],
    bool tweak = true,
  }) {
    if (participants.isEmpty) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "fullSignForSubset requires at least one participating public key.",
      );
    }
    for (final p in participants) {
      if (!publicKeys.contains(p)) {
        throw BuError(
          DefaultErrorType.invalidArgument,
          "fullSignForSubset: participant ${p.toHex()} is not a group member.",
        );
      }
    }
    final nonces = participants.map(generateNonce).toList();
    final signatures = partialSign(
      secNonces: nonces,
      message: digest,
      merkleRoot: merkleRoot,
      treeScript: treeScript,
      tweak: tweak,
      extraKeys: extraKeys,
    );
    return aggSigs(
      signatures: signatures,
      secNonces: nonces,
      message: digest,
      merkleRoot: merkleRoot,
      treeScript: treeScript,
      tweak: tweak,
    );
  }

  /// Verifies a MuSig2 partial signature.
  ///
  /// - `signature`: The partial signature to verify.
  /// - `pubNonce`: The public nonce associated with the signer.
  /// - `publicKey`: The public key of the signer.
  /// - `aggNonce`: The aggregated nonce for the signing session.
  /// - `digest`: The message digest that was signed.
  ///
  /// Returns `true` if the partial signature is valid, otherwise `false`.
  bool partialSigVerify({
    required List<int> signature,
    required List<int> pubNonce,
    required ECPublic publicKey,
    required List<int> aggNonce,
    required List<int> digest,
    List<MuSig2Tweak> tweaks = const [],
  }) {
    final session = MuSig2Session(
      aggnonce: aggNonce,
      publicKeys:
          publicKeys
              .map((e) => e.toBytes(mode: CryptoKeyEncoding.base))
              .toList(),
      msg: digest,
      tweaks: tweaks,
    );
    return key.publicKey.verify(
      MuSig2PartialVerifiyingParams(
        signature: MuSig2PartialSignature(
          signature: signature,
          pubnonce: pubNonce,
          publicKey: publicKey.toBytes(mode: CryptoKeyEncoding.base),
        ),
        session: session,
      ),
    );
  }
}
