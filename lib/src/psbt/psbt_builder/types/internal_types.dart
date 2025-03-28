import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/psbt/psbt.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

abstract class PsbtInputInfo {
  final PsbtTxType type;
  abstract final Script redeemScript;
  final Script scriptPubKey;
  final BigInt amount;
  final int index;
  final Script? p2shRedeemScript;
  final Script? witnessScript;
  final BitcoinBaseAddress address;
  bool get isScriptSpending =>
      p2shRedeemScript != null || witnessScript != null;
  PsbtInputInfo(
      {required this.type,
      required this.index,
      required this.amount,
      required this.scriptPubKey,
      required this.address,
      this.p2shRedeemScript,
      this.witnessScript});
  T cast<T extends PsbtInputInfo>() {
    if (this is! T) {
      throw DartBitcoinPluginException(
          "Invalid cast: expected ${T.runtimeType}, but found $runtimeType.");
    }
    return this as T;
  }
}

class PsbtNonTaprootInputInfo extends PsbtInputInfo {
  @override
  final Script redeemScript;
  PsbtNonTaprootInputInfo._({
    required super.p2shRedeemScript,
    required this.redeemScript,
    required super.index,
    required super.scriptPubKey,
    required super.amount,
    required super.witnessScript,
    required super.type,
    required super.address,
    // required super.existsSignatures,
  });
  factory PsbtNonTaprootInputInfo.legacy({
    required Script? p2shRedeemScript,
    required Script redeemScript,
    required int index,
    required Script scriptPubKey,
    required BigInt amount,
    required BitcoinBaseAddress address,
    // required List<PsbtInputSignatures> existsSignatures,
  }) {
    return PsbtNonTaprootInputInfo._(
      p2shRedeemScript: p2shRedeemScript,
      redeemScript: redeemScript,
      index: index,
      scriptPubKey: scriptPubKey,
      amount: amount,
      witnessScript: null,
      type: PsbtTxType.legacy,
      address: address,
    );
  }
  factory PsbtNonTaprootInputInfo.v0(
      {required Script redeemScript,
      required int index,
      required Script scriptPubKey,
      required BigInt amount,
      required BitcoinBaseAddress address,
      // required List<PsbtInputSignatures> existsSignatures,
      Script? p2shRedeemScript,
      Script? witnessScript}) {
    return PsbtNonTaprootInputInfo._(
        p2shRedeemScript: p2shRedeemScript,
        redeemScript: redeemScript,
        index: index,
        scriptPubKey: scriptPubKey,
        amount: amount,
        witnessScript: witnessScript,
        type: PsbtTxType.witnessV0,
        address: address);
  }
}

class PsbtTaprootInputInfo extends PsbtInputInfo {
  final List<Script> allScriptPubKeys;
  final List<BigInt> allAmounts;
  final PsbtInputTaprootInternalKey internalPublicKey;
  final PsbtInputTaprootMerkleRoot? merkleRoot;
  final List<PsbtInputTaprootLeafScript>? tapleafScripts;
  final PsbtMusig2InputInfo? musig2inputInfo;
  bool get isKeyPath => tapleafScripts == null;
  PsbtTaprootInputInfo(
      {required super.index,
      required super.amount,
      required super.scriptPubKey,
      required this.internalPublicKey,
      List<PsbtInputTaprootLeafScript>? tapleafScripts,
      this.merkleRoot,
      required List<Script> allScriptPubKeys,
      required List<BigInt> allAmounts,
      required super.address,
      required this.musig2inputInfo})
      : allScriptPubKeys = allScriptPubKeys.immutable,
        allAmounts = allAmounts.immutable,
        tapleafScripts = tapleafScripts?.immutable,
        super(type: PsbtTxType.witnessV1);

  @override
  Script get redeemScript => scriptPubKey;

  @override
  bool get isScriptSpending => merkleRoot != null;
}

class PsbtGeneratedTransactionDigest {
  final List<int> digest;
  final PsbtInputTaprootLeafScript? leafScript;
  final int sighashType;
  final PsbtInputInfo params;
  final Psbt psbt;
  PsbtGeneratedTransactionDigest(
      {required List<int> digest,
      this.leafScript,
      required this.sighashType,
      required this.params,
      List<PsbtInputMuSig2PublicNonce>? aggNonce,
      required this.psbt})
      : digest = digest.asImmutableBytes;

  PsbtInputData createSignature(
      SignInputResponse signature, PsbtBtcSigner signer) {
    final pubkey =
        _validateSigner(signer.signerPublicKey, signer is PsbtBtcMusig2Signer);
    if (params.type.isP2tr) {
      final taprootParams = params.cast<PsbtTaprootInputInfo>();
      if (signer is PsbtBtcMusig2Signer) {
        final nonce = _getMusigSignerNonce(signature);
        return PsbtInputMuSig2ParticipantPartialSignature(
            publicKey: signer.signerPublicKey,
            plainPublicKey: nonce.plainPublicKey,
            tapleafHash: nonce.tapleafHash,
            partialSignature: PsbtUtils.validateMusigPartialSignature(
                signature: signature.signature, index: taprootParams.index));
      }
      final schnorrSignature = PsbtUtils.validateSchnorrSignature(
          signature: signature.signature,
          index: params.index,
          expectedSighash: sighashType);
      if (leafScript == null) {
        return PsbtInputTaprootKeySpendSignature(schnorrSignature);
      }

      return PsbtInputTaprootScriptSpendSignature(
          signature: schnorrSignature,
          leafHash: leafScript!.leafScript.hash(),
          xOnlyPubKey: signature.signerPublicKey.toXOnly());
    }
    final ecdsaSignature = PsbtUtils.validateEcdsaSignature(
        signature: signature.signature,
        index: params.index,
        expectedSighash: sighashType);
    return PsbtInputPartialSig(
        signature: ecdsaSignature,
        publicKey: signature.signerPublicKey.toBytes(
            mode: pubkey!.mode == PsbtScriptKeyMode.compressed
                ? PubKeyModes.compressed
                : PubKeyModes.uncompressed));
  }

  PsbtInputMuSig2PublicNonce _getMusigSignerNonce(SignInputResponse signature) {
    if (!params.type.isP2tr) {
      throw DartBitcoinPluginException(
          "MuSig2 Public Nonce Only Work with taproot input.");
    }
    final taprootParams = params.cast<PsbtTaprootInputInfo>();
    final musig = taprootParams.musig2inputInfo;
    if (musig == null) {
      throw DartBitcoinPluginException(
          "Missing MuSig2 participant public keys: PSBT input at index ${params.index} does not contain MuSig2 aggregated public keys.");
    }
    return musig.getMusigSignerNonce(
        xOnly: taprootParams.internalPublicKey.xOnlyPubKey,
        signerPublicKey: signature.signerPublicKey,
        leafScript: leafScript?.leafScript);
  }

  List<int>? generateTaprootTweak() {
    final taprootParams = params.cast<PsbtTaprootInputInfo>();
    List<int>? tweak;
    if (leafScript == null) {
      tweak = TaprootUtils.calculateTweek(
          taprootParams.internalPublicKey.xOnlyPubKey);
    }
    return tweak;
  }

  PsbtSignInputDigest createRequest(PsbtBtcSigner signer) {
    _validateSigner(signer.signerPublicKey, signer is PsbtBtcMusig2Signer);
    if (params.type == PsbtTxType.witnessV1) {
      final taprootParams = params.cast<PsbtTaprootInputInfo>();
      List<int>? tweak;
      if (leafScript == null) {
        tweak = TaprootUtils.calculateTweek(
            taprootParams.internalPublicKey.xOnlyPubKey);
      }
      if (signer is PsbtBtcMusig2Signer) {
        final musig = taprootParams.musig2inputInfo;
        if (musig == null) {
          throw DartBitcoinPluginException(
              "Missing MuSig2 participant public keys: PSBT input at index ${params.index} does not contain MuSig2 aggregated public keys.");
        }
        return PsbtMusig2SigningInputDigest(
            digest: digest,
            aggNonce: musig.generateAggNonce(
                xOnly: taprootParams.internalPublicKey.xOnlyPubKey,
                aggPublicKey: signer.aggPublicKey,
                leafScript: leafScript?.leafScript),
            tweak: tweak);
      } else {
        return PsbtSigningInputDigest(
            digest: digest,
            isTaproot: true,
            tweak: tweak,
            sighash: sighashType);
      }
    } else {
      return PsbtSigningInputDigest(
          digest: digest, isTaproot: false, sighash: sighashType);
    }
  }

  PsbtScriptKeyInfo? _validateSigner(ECPublic publicKey, bool isMusigPubKey) {
    if (params.type.isP2tr && isMusigPubKey) {
      final taprootParams = params.cast<PsbtTaprootInputInfo>();
      final musig = taprootParams.musig2inputInfo;
      if (musig == null) {
        throw DartBitcoinPluginException(
            "Missing MuSig2 participant public keys: PSBT input at index ${params.index}.");
      }
      return null;
    }
    if (params.isScriptSpending) {
      final script = leafScript?.script ?? params.redeemScript;
      final pubKey = PsbtUtils.findSciptKeyInfo(
          publicKey: publicKey, script: script, type: params.type);
      if (pubKey == null) {
        throw DartBitcoinPluginException(
            "Signer public key does not match the scriptPubKey for input ${params.index}.");
      }
      return pubKey;
    } else {
      if (params.type.isP2tr) {
        final taprootParam = params.cast<PsbtTaprootInputInfo>();
        if (!BytesUtils.bytesEqual(
            publicKey.toXOnly(), taprootParam.internalPublicKey.xOnlyPubKey)) {
          throw DartBitcoinPluginException(
              "Signer public key does not match the internalPublicKey for input ${params.index}.");
        }
        return null;
      }
      final script = params.scriptPubKey;
      final pubKey = PsbtUtils.findSciptKeyInfo(
          publicKey: publicKey, script: script, type: params.type);
      if (pubKey == null) {
        throw DartBitcoinPluginException(
            "Signer public key does not match the scriptPubKey for input ${params.index}.");
      }
      return pubKey;
    }
  }

  PsbtInputPartialSig getPartialSignature() {
    List<PsbtInputPartialSig> partialSigs = psbt.input
            .getInputs<PsbtInputPartialSig>(
                params.index, PsbtInputTypes.partialSignature) ??
        [];
    assert(!params.type.isP2tr);
    final script =
        params.isScriptSpending ? params.redeemScript : params.scriptPubKey;
    partialSigs = partialSigs.where((e) {
      return PsbtUtils.keyInScript(
              publicKey: e.publicKey, script: script, type: params.type) &&
          verifyEcdsaSignature(e);
    }).toList();

    if (partialSigs.isEmpty) {
      throw DartBitcoinPluginException(
          "No valid signature found for input ${params.index}.");
    }
    return partialSigs.first;
  }

  List<PsbtInputTaprootScriptSpendSignature> getTaprootScriptSignatures(
      List<String> xOnlyKeys) {
    final musig2Signatures = PsbtUtils.getReadyMusig2Signature(this);
    List<PsbtInputTaprootScriptSpendSignature> partialSigs = [
      ...psbt.input.getInputs<PsbtInputTaprootScriptSpendSignature>(
              params.index, PsbtInputTypes.taprootScriptSpentSignature) ??
          [],
      if (musig2Signatures != null)
        musig2Signatures.cast<PsbtInputTaprootScriptSpendSignature>(),
    ];
    partialSigs = partialSigs
        .where((e) =>
            xOnlyKeys.contains(e.xOnlyPubKeyHex) &&
            BytesUtils.bytesEqual(e.leafHash, leafScript!.leafScript.hash()) &&
            verifySchnorrSignature(
                xOnly: e.xOnlyPubKey, signature: e.signature))
        .toList();
    if (partialSigs.isEmpty) {
      throw DartBitcoinPluginException(
          "No signature found for input ${params.index}.",
          details: {"scriptPubKey": params.scriptPubKey.toString()});
    }
    return partialSigs;
  }

  bool verifyEcdsaSignature(PsbtInputPartialSig sig) {
    try {
      return sig.publicKey.verifyTransaactionSignature(digest, sig.signature);
    } catch (_) {
      return false;
    }
  }

  List<PsbtInputPartialSig> getPartialSignatures(List<ECPublic> publicKeys) {
    final partialSigs = psbt.input
        .getInputs<PsbtInputPartialSig>(
            params.index, PsbtInputTypes.partialSignature)
        ?.where(
            (e) => publicKeys.contains(e.publicKey) && verifyEcdsaSignature(e))
        .toList();
    if (partialSigs == null) {
      throw DartBitcoinPluginException(
          "No valid signature found for input ${params.index}.",
          details: {"scriptPubKey": params.scriptPubKey.toString()});
    }
    return partialSigs;
  }

  String getScriptSha256(Script script) {
    if (!BitcoinScriptUtils.isSha256(script)) {
      throw DartBitcoinPluginException(
          "The provided script does not match the expected SHA-256 script type.");
    }
    final hashBytes = BytesUtils.tryFromHexString(script.script[1]);
    final hashesh = psbt.input
        .getInputs<PsbtInputSha256>(params.index, PsbtInputTypes.sha256)
        ?.firstWhereNullable((e) => BytesUtils.bytesEqual(e.hash, hashBytes));
    if (hashesh == null) {
      throw DartBitcoinPluginException(
          "Failed to find matching input for the provided hash.",
          details: {"scriptPubKey": params.scriptPubKey.toString()});
    }
    return hashesh.preImageHex();
  }

  String getScriptHash256(Script script) {
    if (!BitcoinScriptUtils.isHash256(script)) {
      throw DartBitcoinPluginException(
          "The provided script does not match the expected HASH256 script type.");
    }
    final hashBytes = BytesUtils.tryFromHexString(script.script[1]);
    final hashesh = psbt.input
        .getInputs<PsbtInputHash256>(params.index, PsbtInputTypes.hash256)
        ?.firstWhereNullable((e) => BytesUtils.bytesEqual(e.hash, hashBytes));
    if (hashesh == null) {
      throw DartBitcoinPluginException(
          "Failed to find matching input for the provided hash.",
          details: {"scriptPubKey": params.scriptPubKey.toString()});
    }
    return hashesh.preImageHex();
  }

  String getScriptHash160(Script script) {
    if (!BitcoinScriptUtils.isHash160(script)) {
      throw DartBitcoinPluginException(
          "The provided script does not match the expected HASH160 script type.");
    }
    final hashBytes = BytesUtils.tryFromHexString(script.script[1]);
    final hashesh = psbt.input
        .getInputs<PsbtInputHash160>(params.index, PsbtInputTypes.hash160)
        ?.firstWhereNullable((e) => BytesUtils.bytesEqual(e.hash, hashBytes));
    if (hashesh == null) {
      throw DartBitcoinPluginException(
          "Failed to find matching input for the provided hash.",
          details: {"scriptPubKey": params.scriptPubKey.toString()});
    }
    return hashesh.preImageHex();
  }

  String getScriptRipemd160(Script script) {
    if (!BitcoinScriptUtils.isRipemd160(script)) {
      throw DartBitcoinPluginException(
          "The provided script does not match the expected RIPEMD160 script type.");
    }
    final hashBytes = BytesUtils.tryFromHexString(script.script[1]);
    final hashesh = psbt.input
        .getInputs<PsbtInputRipemd160>(params.index, PsbtInputTypes.ripemd160)
        ?.firstWhereNullable((e) => BytesUtils.bytesEqual(e.hash, hashBytes));
    if (hashesh == null) {
      throw DartBitcoinPluginException(
          "Failed to find matching input for the provided hash.",
          details: {"scriptPubKey": params.scriptPubKey.toString()});
    }
    return hashesh.preImageHex();
  }

  bool verifySchnorrSignature(
      {required List<int> xOnly, required List<int> signature}) {
    try {
      final tweak = generateTaprootTweak();
      return BitcoinVerifier.verifySchnorrSignature(
          xOnly: xOnly, message: digest, signature: signature, tweak: tweak);
    } catch (_) {
      return false;
    }
  }

  String getTaprootKeyPathSignature() {
    final taprootParams = params.cast<PsbtTaprootInputInfo>();
    final musig = PsbtUtils.getReadyMusig2Signature(this)
        ?.cast<PsbtInputTaprootKeySpendSignature>();
    List<PsbtInputTaprootKeySpendSignature> signatures = [
      ...psbt.input.getInputs<PsbtInputTaprootKeySpendSignature>(
              params.index, PsbtInputTypes.taprootKeySpentSignature) ??
          [],
      if (musig != null) musig
    ];
    final signature = signatures.firstWhereNullable((e) =>
        verifySchnorrSignature(
            xOnly: taprootParams.internalPublicKey.xOnlyPubKey,
            signature: e.signature));

    if (signature == null) {
      throw DartBitcoinPluginException(
          "No valid signature found for input ${params.index} type P2TR key-path.");
    }
    return signature.signatureHex();
  }

  PsbtInputTaprootScriptSpendSignature getTaprootScriptSignature(String xOnly) {
    return getTaprootScriptSignatures([xOnly]).first;
  }

  PsbtInputSigHash? getPsbtSigHash() {
    if (params.type.isP2tr &&
        sighashType != BitcoinOpCodeConst.sighashDefault) {
      return PsbtInputSigHash(sighashType);
    } else if (sighashType != BitcoinOpCodeConst.sighashAll) {
      return PsbtInputSigHash(sighashType);
    }
    return null;
  }
}

enum PsbtScriptKeyMode {
  xOnly,
  compressed,
  uncompressed;

  static PsbtScriptKeyMode fromKeyString(String key) {
    final toBytes = BytesUtils.tryFromHexString(key);
    if (toBytes != null) {
      if (toBytes.length == EcdsaKeysConst.pointCoordByteLen) return xOnly;
      if (toBytes.length == EcdsaKeysConst.pubKeyCompressedByteLen) {
        return compressed;
      }
      if (toBytes.length == EcdsaKeysConst.pubKeyUncompressedByteLen) {
        return uncompressed;
      }
    }
    throw DartBitcoinPluginException(
        "Invalid key format: '$key'. Expected a valid hex string of length "
        "${EcdsaKeysConst.pointCoordByteLen}, ${EcdsaKeysConst.pubKeyCompressedByteLen}, "
        "or ${EcdsaKeysConst.pubKeyUncompressedByteLen}.");
  }
}

class PsbtScriptKeyInfo {
  final int index;
  final String key;
  final PsbtScriptKeyMode mode;
  const PsbtScriptKeyInfo(
      {required this.index, required this.key, required this.mode});
}

class PsbtMusig2InputInfo {
  final List<PsbtInputMuSig2ParticipantPublicKeys> publicKeys;
  final List<PsbtInputMuSig2PublicNonce> nonces;
  final List<PsbtInputMuSig2ParticipantPartialSignature> partialSigs;
  PsbtMusig2InputInfo({
    required List<PsbtInputMuSig2ParticipantPublicKeys> publicKeys,
    required List<PsbtInputMuSig2PublicNonce> nonces,
    required List<PsbtInputMuSig2ParticipantPartialSignature> partialSigs,
  })  : publicKeys = publicKeys.immutable,
        nonces = nonces.immutable,
        partialSigs = partialSigs.immutable;

  List<PsbtInputMuSig2PublicNonce> getScriptNonces(TaprootLeaf leafScript) {
    return nonces
        .where((e) =>
            BytesUtils.bytesEqual(e.tapleafHash, leafScript.hash()) &&
            PsbtUtils.keyInScript(
                keyStr: e.plainPublicKey.toXOnlyHex(),
                script: leafScript.script))
        .toList();
  }

  List<PsbtInputMuSig2PublicNonce> getNonScriptNonces(List<int> xOnly) {
    return nonces
        .where((e) =>
            e.tapleafHash == null &&
            BytesUtils.bytesEqual(e.plainPublicKey.toXOnly(), xOnly))
        .toList();
  }

  List<PsbtInputMuSig2ParticipantPartialSignature> getScriptSignatures(
      TaprootLeaf leafScript) {
    return partialSigs
        .where((e) =>
            BytesUtils.bytesEqual(e.tapleafHash, leafScript.hash()) &&
            PsbtUtils.keyInScript(
                keyStr: e.plainPublicKey.toXOnlyHex(),
                script: leafScript.script))
        .toList();
  }

  List<PsbtInputMuSig2ParticipantPartialSignature> getNonScriptSignatures(
      List<int> internalKey) {
    return partialSigs
        .where((e) =>
            e.tapleafHash == null &&
            BytesUtils.bytesEqual(e.plainPublicKey.toXOnly(), internalKey))
        .toList();
  }

  PsbtInputMuSig2ParticipantPublicKeys? getScriptPublicKey(
      TaprootLeaf leafScript) {
    return publicKeys.firstWhereNullable((e) => PsbtUtils.keyInScript(
        keyStr: e.aggregatePubKey.toXOnlyHex(), script: leafScript.script));
  }

  PsbtInputMuSig2ParticipantPublicKeys? getNonceScriptPublicKey(
      List<int> internalKey) {
    return publicKeys.firstWhereNullable(
        (e) => BytesUtils.bytesEqual(e.aggregatePubKey.toXOnly(), internalKey));
  }

  List<int> generateAggNonce(
      {required List<int> xOnly,
      required ECPublic aggPublicKey,
      TaprootLeaf? leafScript}) {
    final aggKey = publicKeys.firstWhere(
      (e) => e.aggregatePubKey == aggPublicKey,
      orElse: () => throw DartBitcoinPluginException(
          "MuSig2 participant public keys not found: No matching aggregate public key and participant set found."),
    );
    List<PsbtInputMuSig2PublicNonce> nonces = [];
    if (leafScript == null) {
      nonces = getNonScriptNonces(xOnly);
    } else {
      nonces = getScriptNonces(leafScript);
    }
    List<PsbtInputMuSig2PublicNonce> validNonces = [];
    for (final i in aggKey.pubKeys) {
      final nonce = nonces.firstWhereNullable((e) => e.publicKey == i);
      if (nonce == null) break;
      validNonces.add(nonce);
    }
    if (validNonces.length != aggKey.pubKeys.length) {
      throw DartBitcoinPluginException(
          "Unable to create aggregate nonce: The number of available nonces (${validNonces.length}) does not match the number of MuSig2 participant public keys (${aggKey.pubKeys.length}).");
    }
    return MuSig2.nonceAgg(nonces.map((e) => e.publicNonce).toList());
  }

  PsbtInputMuSig2PublicNonce getMusigSignerNonce(
      {required List<int> xOnly,
      required ECPublic signerPublicKey,
      TaprootLeaf? leafScript}) {
    List<PsbtInputMuSig2PublicNonce> nonces = [];
    if (leafScript == null) {
      nonces = getNonScriptNonces(xOnly);
    } else {
      nonces = getScriptNonces(leafScript);
    }
    return nonces.firstWhere((e) => e.publicKey == signerPublicKey);
  }
}

class PsbtInputLocktime {
  final bool isBlockBased;
  final int timelock;
  const PsbtInputLocktime({required this.isBlockBased, required this.timelock});
}
