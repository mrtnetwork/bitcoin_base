import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// A signer class for MuSig2, handling key aggregation, nonce generation,
/// signing, and partial signature aggregation.
class Musig2Signer {
  /// A list of private keys for signing. This can be empty for public-only operations.
  final List<ECPrivate> privateKeys;

  /// A list of public keys used in the MuSig2 signing process.
  final List<ECPublic> publicKeys;

  /// The aggregated MuSig2 public key, used for Taproot or MuSig2 signing.
  final ECPublic aggPublicKey;

  /// Private constructor to enforce the use of the factory constructor.
  Musig2Signer._({
    required List<ECPrivate> privateKeys,
    required List<ECPublic> publicKeys,
    required this.aggPublicKey,
  })  : privateKeys = privateKeys.immutable,
        publicKeys = publicKeys.immutable;

  /// Generates a new `Musig2Signer` instance by aggregating the provided public keys.
  ///
  /// - If `sortKeys` is `true`, the public keys will be lexicographically sorted before aggregation.
  /// - If `privateKeys` are provided, they will be used for signing.
  factory Musig2Signer.generate(List<ECPublic> publicKeys,
      {List<ECPrivate> privateKeys = const [], bool sortKeys = false}) {
    List<List<int>> publicKeysBytes =
        publicKeys.map((e) => e.toBytes(mode: PubKeyModes.compressed)).toList();

    if (sortKeys) {
      publicKeysBytes = MuSig2Utils.sortPublicKeys(publicKeysBytes);
    }

    final aggKey = MuSig2.aggPublicKeys(keys: publicKeysBytes);

    return Musig2Signer._(
      privateKeys: privateKeys,
      publicKeys: sortKeys
          ? publicKeysBytes.map((e) => ECPublic.fromBytes(e)).toList()
          : publicKeys,
      aggPublicKey: ECPublic.fromBytes(aggKey.publicKey.toBytes()),
    );
  }

  /// Generates a Taproot address using the aggregated MuSig2 public key.
  ///
  /// - If a `scriptTree` is provided, it will be included in the Taproot address.
  P2trAddress toAddress({TaprootTree? scriptTree}) {
    return P2trAddress.fromInternalKey(
        internalKey: aggPublicKey.toXOnly(), treeScript: scriptTree);
  }

  /// Generates a list of MuSig2 nonces for signing.
  ///
  /// - `rand` is optional random data for nonce generation.
  /// - `sk` (optional) is the private key for deterministic nonce generation.
  /// - `aggPubKey` is the aggregate public key.
  /// - `msg` is the message being signed.
  /// - `extra` is additional data used in nonce generation.
  List<MuSig2Nonce> generateNonces(
      {List<int>? rand,
      List<int>? sk,
      List<int>? aggPubKey,
      List<int>? msg,
      List<int>? extra}) {
    return publicKeys
        .map((e) => MuSig2.nonceGenerate(
            publicKey: e.toBytes(mode: PubKeyModes.compressed),
            aggPubKey: aggPubKey,
            extra: extra,
            msg: msg,
            rand: rand,
            sk: sk))
        .toList();
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
  MuSig2Nonce generateNonce(ECPublic publicKey,
      {List<int>? rand,
      List<int>? sk,
      List<int>? aggPubKey,
      List<int>? msg,
      List<int>? extra}) {
    return MuSig2.nonceGenerate(
        publicKey: publicKey.toBytes(mode: PubKeyModes.compressed),
        aggPubKey: aggPubKey,
        extra: extra,
        msg: msg,
        rand: rand,
        sk: sk);
  }

  /// Aggregates multiple MuSig2 nonces into a single aggregated nonce.
  List<int> aggNonce(List<MuSig2Nonce> nonces) {
    return MuSig2.nonceAgg(nonces.map((e) => e.pubnonce).toList());
  }

  /// Signs a message using the provided MuSig2 secret nonces.
  ///
  /// - Each signer must provide their secret nonce (`secNonces`).
  /// - The message (`message`) must be the same for all participants.
  /// - Returns a list of partial signatures.
  ///
  /// Throws an exception if a corresponding private key is not found.
  List<List<int>> partialSign(
      {required List<MuSig2Nonce> secNonces,
      required List<int> message,
      List<int>? merkleRoot,
      TaprootTree? treeScript,
      bool tweak = true,
      List<ECPrivate> extraKeys = const []}) {
    final aggNonce = this.aggNonce(secNonces);
    final session = MuSig2Session(
        aggnonce: aggNonce,
        publicKeys: publicKeys
            .map((e) => e.toBytes(mode: PubKeyModes.compressed))
            .toList(),
        msg: message,
        tweaks: [
          if (tweak)
            MuSig2Tweak(
                tweak: TaprootUtils.calculateTweek(aggPublicKey.toXOnly(),
                    treeScript: merkleRoot != null ? null : treeScript,
                    merkleRoot: merkleRoot))
        ]);
    List<List<int>> signatures = [];
    final privateKeys = [...this.privateKeys, ...extraKeys];
    for (final i in secNonces) {
      final pubKey = publicKeys.firstWhere(
        (e) => e.point == i.publicKey,
        orElse: () => throw DartBitcoinPluginException(
            "Unable to find nonce public key in MuSig2 public keys."),
      );

      final key = privateKeys.firstWhere(
        (e) => e.prive.publicKey.point == pubKey.point,
        orElse: () {
          throw DartBitcoinPluginException(
              "Unable to find private key for the given public nonce.",
              details: {"publicKey": pubKey.toHex()});
        },
      );

      final sig = MuSig2.sign(
          secnonce: i.secnonce, sk: key.toBytes(), session: session);
      signatures.add(sig);
    }

    return signatures;
  }

  /// Aggregates the provided partial signatures into a final MuSig2 signature.
  ///
  /// - `signatures`: List of partial signatures from all participants.
  /// - `secNonces`: The secret nonces used for signing.
  /// - `message`: The message that was signed.
  ///
  /// Returns the final aggregated signature.
  List<int> aggSigs(
      {required List<List<int>> signatures,
      required List<MuSig2Nonce> secNonces,
      required List<int> message,
      int? sighash = BitcoinOpCodeConst.sighashDefault,
      List<int>? merkleRoot,
      TaprootTree? treeScript,
      bool tweak = true,
      List<ECPrivate> extraKeys = const []}) {
    final aggNonce = this.aggNonce(secNonces);
    final session = MuSig2Session(
        aggnonce: aggNonce,
        tweaks: [
          if (tweak)
            MuSig2Tweak(
                tweak: TaprootUtils.calculateTweek(aggPublicKey.toXOnly(),
                    treeScript: merkleRoot != null ? null : treeScript,
                    merkleRoot: merkleRoot))
        ],
        publicKeys: publicKeys
            .map((e) => e.toBytes(mode: PubKeyModes.compressed))
            .toList(),
        msg: message);
    final aggSignature =
        MuSig2.partialSigAgg(signatures: signatures, session: session);
    if (sighash != null && sighash != BitcoinOpCodeConst.sighashDefault) {
      return [...aggSignature, sighash];
    }
    return aggSignature;
  }

  /// Generates nonces, signs the message, and returns the final aggregated signature.
  ///
  /// This is a convenience method that performs all signing steps in one call.
  ///
  /// - `digest`: The hash of the message to be signed.
  ///
  /// Returns the final aggregated signature.
  List<int> fullSign(
    List<int> digest, {
    List<int>? merkleRoot,
    TaprootTree? treeScript,
    List<ECPrivate> extraKeys = const [],
    bool tweak = true,
  }) {
    final nonces = generateNonces();
    final signatures = partialSign(
        secNonces: nonces,
        message: digest,
        merkleRoot: merkleRoot,
        treeScript: treeScript,
        tweak: tweak,
        extraKeys: extraKeys);
    return aggSigs(
        signatures: signatures,
        secNonces: nonces,
        message: digest,
        merkleRoot: merkleRoot,
        treeScript: treeScript,
        tweak: tweak);
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
  bool partialSigVerify(
      {required List<int> signature,
      required List<int> pubNonce,
      required ECPublic publicKey,
      required List<int> aggNonce,
      required List<int> digest}) {
    final session = MuSig2Session(
        aggnonce: aggNonce,
        publicKeys: publicKeys
            .map((e) => e.toBytes(mode: PubKeyModes.compressed))
            .toList(),
        msg: digest);

    return MuSig2.partialSigVerify(
        signature: signature,
        pubnonce: pubNonce,
        pk: publicKey.toBytes(mode: PubKeyModes.compressed),
        session: session);
  }
}
