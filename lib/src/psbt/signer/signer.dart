import 'package:bitcoin_base/src/crypto/keypair/ec_private.dart';
import 'package:bitcoin_base/src/crypto/keypair/ec_public.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

abstract class PsbtBtcSigner<SIGNINGRESPONSE extends SignInputResponse,
    DIGEST extends PsbtSignInputDigest> {
  const PsbtBtcSigner();
  abstract final ECPublic signerPublicKey;
  SIGNINGRESPONSE btcSignInput(DIGEST digest);
  Future<SIGNINGRESPONSE> btcSignInputAsync(DIGEST digest);
}

abstract class PsbtBtcMusig2Signer
    extends PsbtBtcSigner<SignInputResponse, PsbtMusig2SigningInputDigest> {
  const PsbtBtcMusig2Signer();
  abstract final ECPublic aggPublicKey;
  abstract final List<ECPublic> publicKeys;
}

abstract class PsbtSignInputDigest {
  final List<int> digest;
  final List<int>? tweak;
  PsbtSignInputDigest({
    required List<int> digest,
    required List<int>? tweak,
  })  : digest = digest.asImmutableBytes,
        tweak = tweak?.asImmutableBytes;
}

class PsbtSigningInputDigest extends PsbtSignInputDigest {
  final bool isTaproot;
  final int sighash;
  PsbtSigningInputDigest({
    required super.digest,
    super.tweak,
    required this.sighash,
    required this.isTaproot,
  });
}

class PsbtMusig2SigningInputDigest extends PsbtSignInputDigest {
  final List<int> aggNonce;
  PsbtMusig2SigningInputDigest({
    required super.digest,
    required List<int> aggNonce,
    super.tweak,
  }) : aggNonce = aggNonce.asImmutableBytes;
}

class SignInputResponse extends PsbtSigningResponse {
  SignInputResponse._(
      {required super.signature, required super.signerPublicKey});
  factory SignInputResponse(
      {required List<int> signature, required ECPublic signerPublicKey}) {
    return SignInputResponse._(
        signature: signature, signerPublicKey: signerPublicKey);
  }
}

abstract class PsbtSigningResponse {
  final List<int> signature;
  final ECPublic signerPublicKey;
  PsbtSigningResponse({
    required List<int> signature,
    required this.signerPublicKey,
  }) : signature = signature.asImmutableBytes;
}

class PsbtDefaultSigner
    implements PsbtBtcSigner<SignInputResponse, PsbtSigningInputDigest> {
  final ECPrivate privateKey;
  PsbtDefaultSigner(this.privateKey);

  @override
  late final ECPublic signerPublicKey = privateKey.getPublic();

  @override
  SignInputResponse btcSignInput(PsbtSigningInputDigest digest) {
    if (digest.isTaproot) {
      return SignInputResponse(
          signature:
              privateKey.signBtcSchnorr(digest.digest, tweak: digest.tweak),
          signerPublicKey: signerPublicKey);
    }
    final signature =
        privateKey.signInput(digest.digest, sigHash: digest.sighash);
    return SignInputResponse(
        signature: BytesUtils.fromHexString(signature),
        signerPublicKey: signerPublicKey);
  }

  @override
  Future<SignInputResponse> btcSignInputAsync(
      PsbtSigningInputDigest digest) async {
    return btcSignInput(digest);
  }
}

class PsbtMusig2DefaultSigner implements PsbtBtcMusig2Signer {
  final ECPrivate privateKey;
  @override
  final ECPublic aggPublicKey;
  @override
  final List<ECPublic> publicKeys;
  final MuSig2Nonce nonce;
  PsbtMusig2DefaultSigner(
      {required this.privateKey,
      required this.aggPublicKey,
      required this.publicKeys,
      required this.nonce});

  @override
  late final ECPublic signerPublicKey = privateKey.getPublic();

  @override
  SignInputResponse btcSignInput(PsbtMusig2SigningInputDigest digest) {
    final session = MuSig2Session(
        aggnonce: digest.aggNonce,
        publicKeys: publicKeys
            .map((e) => e.toBytes(mode: PubKeyModes.compressed))
            .toList(),
        msg: digest.digest,
        tweaks: [if (digest.tweak != null) MuSig2Tweak(tweak: digest.tweak!)]);
    final signature = MuSig2.sign(
        secnonce: nonce.secnonce, sk: privateKey.toBytes(), session: session);
    return SignInputResponse._(
        signature: signature, signerPublicKey: signerPublicKey);
  }

  @override
  Future<SignInputResponse> btcSignInputAsync(
      PsbtMusig2SigningInputDigest digest) async {
    return btcSignInput(digest);
  }
}
