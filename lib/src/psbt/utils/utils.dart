import 'dart:typed_data';
import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:bitcoin_base/src/psbt/psbt_builder/types/internal_types.dart';
import 'package:bitcoin_base/src/psbt/types/types/global.dart';
import 'package:bitcoin_base/src/psbt/types/types/inputs.dart';
import 'package:bitcoin_base/src/psbt/types/types/outputs.dart';
import 'package:bitcoin_base/src/psbt/psbt_builder/types/types.dart';
import 'package:bitcoin_base/src/psbt/types/types/psbt.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class PsbtUtils {
  static final String fakeEcdsaPubKey = "0" * 33 * 2;
  static final String fakeUnCompresedEcdsaPubKey = "0" * 65 * 2;

  /// 65 byte schnorr signature length
  static const fakeSchnorSignaturBytes =
      '0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101';

  /// 72 bytes (64 byte signature, 6-7 byte Der encoding length)
  static const fakeECDSASignatureBytes =
      '010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101';

  static PsbtInputInfo _getInputInfo(
      {required Psbt psbt, required TxInput input, required int inputIndex}) {
    PsbtTxType inputType = PsbtTxType.legacy;
    bool isSegwit = false;
    bool isP2tr = false;
    Script? scriptPubKey;
    Script? redeemScript;
    Script? p2shRedeemScript;
    BigInt? amount;
    BitcoinBaseAddress? address;
    final noneWitnessUtxo = psbt.input.getInput<PsbtInputNonWitnessUtxo>(
        inputIndex, PsbtInputTypes.nonWitnessUTXO);
    if (noneWitnessUtxo != null) {
      if (input.txIndex >= noneWitnessUtxo.transaction.outputs.length) {
        throw DartBitcoinPluginException(
            "The provided non-Witness UTXO does not contain the given index.");
      }
      final output = noneWitnessUtxo.transaction.outputs[input.txIndex];
      final type = findScriptType(output.scriptPubKey);
      isSegwit = type.isSegwit;
      scriptPubKey = output.scriptPubKey;
      redeemScript = output.scriptPubKey;
      amount = output.amount;
    }
    final witnessUtxo = psbt.input
        .getInput<PsbtInputWitnessUtxo>(inputIndex, PsbtInputTypes.witnessUTXO);
    final witnessScript = psbt.input.getInput<PsbtInputWitnessScript>(
        inputIndex, PsbtInputTypes.witnessScript);
    p2shRedeemScript = psbt.input
        .getInput<PsbtInputRedeemScript>(
            inputIndex, PsbtInputTypes.redeemScript)
        ?.redeemScript;
    final merkleRoot = psbt.input.getInput<PsbtInputTaprootMerkleRoot>(
        inputIndex, PsbtInputTypes.taprootMerkleRoot);
    final leavesScripts = psbt.input.getInputs<PsbtInputTaprootLeafScript>(
        inputIndex, PsbtInputTypes.taprootLeafScript);
    final internalPublicKey = psbt.input.getInput<PsbtInputTaprootInternalKey>(
        inputIndex, PsbtInputTypes.taprootInternalKey);
    isSegwit |= witnessUtxo != null;
    isP2tr |= internalPublicKey != null;
    if (isSegwit) {
      if (witnessUtxo == null) {
        throw DartBitcoinPluginException(
            "WitnessUtxo required for spending witness utxos.");
      }
      inputType = isP2tr ? PsbtTxType.witnessV1 : PsbtTxType.witnessV0;

      amount = witnessUtxo.amount;
      scriptPubKey = witnessUtxo.scriptPubKey;
      if (witnessScript != null) {
        if (isP2tr) {
          throw DartBitcoinPluginException(
              "WitnessScript cannot be used in P2TR UTXOs.");
        }
        redeemScript = witnessScript.witnessScript;
        address = P2wshAddress.fromScript(script: redeemScript);
        if (p2shRedeemScript != null) {
          address = P2shAddress.fromScript(script: address.toScriptPubKey());
        }
        if (address.toScriptPubKey() != scriptPubKey) {
          throw DartBitcoinPluginException(
              "ScriptPubKey does not match the one generated from witness script.");
        }
      } else {
        if (!isP2tr) {
          final type = findScriptType(p2shRedeemScript ?? scriptPubKey);
          if (type == ScriptPubKeyType.p2wsh) {
            throw DartBitcoinPluginException(
                "Missing witness script for input $inputIndex.");
          }
          if (type != ScriptPubKeyType.p2wpkh) {
            if (p2shRedeemScript != null) {
              throw DartBitcoinPluginException(
                  "Invalid Nested P2SH redeem script. ",
                  details: {"script": p2shRedeemScript.toHex()});
            }
            throw DartBitcoinPluginException("Invalid witness scriptPubKey. ",
                details: {"script": scriptPubKey.toHex()});
          }
          final redeem = p2shRedeemScript ?? scriptPubKey;
          if (!BitcoinScriptUtils.isP2wpkh(redeem)) {
            throw DartBitcoinPluginException("Invalid p2wpkh scriptPubKey.");
          }
          redeemScript = P2pkhAddress.fromHash160(addrHash: redeem.script[1])
              .toScriptPubKey();
        }
      }
    } else if (witnessScript != null ||
        merkleRoot != null ||
        internalPublicKey != null ||
        leavesScripts != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT input: cannot have both legacy and witness fields.");
    }

    /// coinbase input
    if (!isSegwit && noneWitnessUtxo == null) {
      throw DartBitcoinPluginException("NonWintessUtxo missing.");
    }
    if (!isSegwit && p2shRedeemScript != null) {
      redeemScript = p2shRedeemScript;
      if (BitcoinScriptUtils.isP2sh32(scriptPubKey!)) {
        address = P2shAddress.fromScript32(script: redeemScript);
      } else {
        address = P2shAddress.fromScript(script: redeemScript);
      }

      if (address.toScriptPubKey() != scriptPubKey) {
        throw DartBitcoinPluginException(
            "ScriptPubKey does not match the one generated from p2sh redeem script. ${address.toScriptPubKey()}");
      }
    }

    if (isP2tr) {
      if (merkleRoot != null && leavesScripts == null) {
        throw DartBitcoinPluginException(
            "Witness v1 script-path spending requires leaf scripts.");
      }
      address = P2trAddress.fromInternalKey(
          internalKey: internalPublicKey!.xOnlyPubKey,
          merkleRoot: merkleRoot?.hash);
      if (address.toScriptPubKey() != scriptPubKey) {
        throw DartBitcoinPluginException(
            "ScriptPubKey does not match the one generated from the internal key and Merkle root.");
      }
    } else if (isSegwit && (merkleRoot != null || leavesScripts != null)) {
      throw DartBitcoinPluginException(
          "Invalid PSBT input: merkleRoot and leaf scripts must not be provided for Witness v0.");
    }
    address ??=
        BitcoinScriptUtils.generateAddressFromScriptPubKey(scriptPubKey!);
    switch (inputType) {
      case PsbtTxType.legacy:
        return PsbtNonTaprootInputInfo.legacy(
            redeemScript: redeemScript!,
            index: inputIndex,
            p2shRedeemScript: p2shRedeemScript,
            scriptPubKey: scriptPubKey!,
            amount: amount!,
            address: address);
      case PsbtTxType.witnessV0:
        return PsbtNonTaprootInputInfo.v0(
            redeemScript: redeemScript!,
            index: inputIndex,
            amount: witnessUtxo!.amount,
            p2shRedeemScript: p2shRedeemScript,
            scriptPubKey: scriptPubKey!,
            witnessScript: witnessScript?.witnessScript,
            address: address);
      default:
        final musigInfo = _getInputExistsMusi2Info(
            psbt: psbt,
            index: inputIndex,
            type: inputType,
            xOnly: internalPublicKey!,
            scripts: leavesScripts);
        return PsbtTaprootInputInfo(
            scriptPubKey: scriptPubKey!,
            amount: amount!,
            index: inputIndex,
            allScriptPubKeys: [],
            allAmounts: [],
            internalPublicKey: internalPublicKey,
            merkleRoot: merkleRoot,
            tapleafScripts: leavesScripts,
            address: address,
            musig2inputInfo: musigInfo);
    }
  }

  static PsbtInputInfo getPsbtInputInfo(
      {required Psbt psbt,
      required int inputIndex,
      required List<TxInput> txInputs}) {
    validateTxInputs(
        psbInput: psbt.input,
        inputIndex: inputIndex,
        inputsLength: txInputs.length);
    final TxInput input = txInputs[inputIndex];
    PsbtInputInfo inputParams =
        _getInputInfo(psbt: psbt, input: input, inputIndex: inputIndex);
    if (inputParams.type != PsbtTxType.witnessV1) return inputParams;
    final v1Param = inputParams.cast<PsbtTaprootInputInfo>();
    List<Script> scriptPubKeys = [];
    List<BigInt> amounts = [];
    for (int i = 0; i < psbt.input.length; i++) {
      if (i == inputIndex) {
        scriptPubKeys.add(v1Param.scriptPubKey);
        amounts.add(v1Param.amount);
        continue;
      }
      final TxInput input = txInputs[i];
      final sciptPubKey =
          getInputScriptPubKey(psbtInput: psbt.input, input: input, index: i);
      final amount = getInputAmount(psbt: psbt, input: input, index: i);
      scriptPubKeys.add(sciptPubKey);
      amounts.add(amount);
    }
    return PsbtTaprootInputInfo(
        index: v1Param.index,
        amount: v1Param.amount,
        scriptPubKey: v1Param.scriptPubKey,
        allScriptPubKeys: scriptPubKeys,
        allAmounts: amounts,
        internalPublicKey: v1Param.internalPublicKey,
        merkleRoot: v1Param.merkleRoot,
        tapleafScripts: v1Param.tapleafScripts,
        address: v1Param.address,
        musig2inputInfo: v1Param.musig2inputInfo);
  }

  static BtcTransaction cleanUpAdnValidateNonUtxoWitness(
      {required BtcTransaction transaction,
      required int outIndex,
      required String txId}) {
    if (outIndex >= transaction.outputs.length) {
      throw DartBitcoinPluginException(
          "The provided non-Witness UTXO does not contain the given index.");
    }
    if (transaction.txId() != StringUtils.strip0x(txId.toLowerCase())) {
      throw DartBitcoinPluginException(
          "Transaction ID mismatch. Expected: ${transaction.txId()}, but got: ${StringUtils.strip0x(txId.toLowerCase())}");
    }
    return transaction;
  }

  static ScriptPubKeyType findScriptType(Script scriptPubKey) {
    final type = BitcoinScriptUtils.findScriptType(scriptPubKey);
    if (type == null) {
      throw DartBitcoinPluginException(
          "Unknown scriptPubKey. Unable to determine script type.",
          details: {"script": scriptPubKey.toHex()});
    }
    return type;
  }

  static PsbtTxType getTxType(PsbtInput input) {
    bool isSegwit = input.entries.any((e) => e.any((e) =>
        e.type == PsbtInputTypes.witnessUTXO ||
        e.type == PsbtInputTypes.finalizedWitness ||
        e.type == PsbtInputTypes.witnessScript));
    bool isP2tr = input.entries.any((e) => e.any((e) =>
        e.type == PsbtInputTypes.taprootInternalKey ||
        e.type == PsbtInputTypes.taprootMerkleRoot ||
        e.type == PsbtInputTypes.taprootBip32Derivation));
    if (isP2tr) return PsbtTxType.witnessV1;
    if (isSegwit) return PsbtTxType.witnessV0;
    return PsbtTxType.legacy;
  }

  static bool keyInScript(
      {ECPublic? publicKey,
      String? keyStr,
      required Script script,
      PsbtTxType? type}) {
    return findSciptKeyInfo(
            script: script, keyStr: keyStr, publicKey: publicKey, type: type) !=
        null;
  }

  static PsbtScriptKeyInfo? findSciptKeyInfo(
      {ECPublic? publicKey,
      String? keyStr,
      required Script script,
      PsbtTxType? type}) {
    if (keyStr != null) {
      keyStr = StringUtils.strip0x(keyStr.toLowerCase());
      int index = script.script.indexOf(keyStr);
      if (!index.isNegative) {
        return PsbtScriptKeyInfo(
            index: index,
            key: keyStr,
            mode: PsbtScriptKeyMode.fromKeyString(keyStr));
      }
      return null;
    }
    if (publicKey == null) return null;
    String key = publicKey.toHash160Hex();
    int index = script.script.indexOf(key);
    if (type == null || !type.isP2tr) {
      if (!index.isNegative) {
        return PsbtScriptKeyInfo(
            index: index,
            key: publicKey.toHex(),
            mode: PsbtScriptKeyMode.compressed);
      }
      key = publicKey.toHex();
      index = script.script.indexOf(key);
      if (!index.isNegative) {
        return PsbtScriptKeyInfo(
            index: index, key: key, mode: PsbtScriptKeyMode.compressed);
      }
      if (type == null || !type.isSegwit) {
        key = publicKey.toHex(mode: PubKeyModes.uncompressed);
        index = script.script.indexOf(key);
        if (!index.isNegative) {
          return PsbtScriptKeyInfo(
              index: index, key: key, mode: PsbtScriptKeyMode.uncompressed);
        }
        key = publicKey.toHash160Hex(mode: PubKeyModes.uncompressed);
        index = script.script.indexOf(key);
        if (!index.isNegative) {
          return PsbtScriptKeyInfo(
              index: index,
              key: publicKey.toHex(mode: PubKeyModes.uncompressed),
              mode: PsbtScriptKeyMode.uncompressed);
        }
      }
    }
    if (type == null || type.isP2tr) {
      key = publicKey.toXOnlyHex();
      index = script.script.indexOf(key);
      if (!index.isNegative) {
        return PsbtScriptKeyInfo(
            index: index, key: key, mode: PsbtScriptKeyMode.xOnly);
      }
    }

    return null;
  }

  static PsbtInputTaprootLeafScript findCorrectLeafScript(
      {required List<PsbtInputTaprootLeafScript> tapLeafScripts,
      required int index,
      List<int>? tapleafHash}) {
    if (tapleafHash == null) {
      if (tapLeafScripts.length > 1) {
        throw DartBitcoinPluginException(
            "Multiple leaf scripts detected in input $index. A leaf hash is required to locate them.");
      }
      return tapLeafScripts.first;
    }
    return tapLeafScripts.firstWhere(
      (e) => BytesUtils.bytesEqual(e.leafScript.hash(), tapleafHash),
      orElse: () {
        throw DartBitcoinPluginException(
            "No matching Taproot leaf script found in input $index for the provided tapleaf ${BytesUtils.toHexString(tapleafHash)}.");
      },
    );
  }

  static Script getInputScriptPubKey(
      {required PsbtInput psbtInput,
      required TxInput input,
      required int index}) {
    final noneWitnessUtxo = psbtInput.getInput<PsbtInputNonWitnessUtxo>(
        index, PsbtInputTypes.nonWitnessUTXO);
    if (noneWitnessUtxo != null) {
      if (input.txIndex >= noneWitnessUtxo.transaction.outputs.length) {
        throw DartBitcoinPluginException(
            "Invalid input $index. The provided non-Witness UTXO does not contain the given index.");
      }
      final output = noneWitnessUtxo.transaction.outputs[input.txIndex];
      return output.scriptPubKey;
    }
    final witnessUtxo = psbtInput.getInput<PsbtInputWitnessUtxo>(
        index, PsbtInputTypes.witnessUTXO);
    if (witnessUtxo != null) {
      return witnessUtxo.scriptPubKey;
    }
    throw DartBitcoinPluginException(
        "Missing scriptPubKey for input at index $index.");
  }

  static BigInt getInputAmount(
      {required Psbt psbt, required TxInput input, required int index}) {
    final noneWitnessUtxo = psbt.input.getInput<PsbtInputNonWitnessUtxo>(
        index, PsbtInputTypes.nonWitnessUTXO);
    if (noneWitnessUtxo != null) {
      if (input.txIndex >= noneWitnessUtxo.transaction.outputs.length) {
        throw DartBitcoinPluginException(
            "Invalid input $index. The provided non-Witness UTXO does not contain the given index.");
      }
      final output = noneWitnessUtxo.transaction.outputs[input.txIndex];
      return output.amount;
    }
    final witnessUtxo = psbt.input
        .getInput<PsbtInputWitnessUtxo>(index, PsbtInputTypes.witnessUTXO);
    if (witnessUtxo != null) {
      return witnessUtxo.amount;
    }
    throw DartBitcoinPluginException(
        "Missing amount for input at index $index.");
  }

  static PsbtMusig2InputInfo? _getInputExistsMusi2Info(
      {required Psbt psbt,
      required int index,
      required PsbtTxType type,
      required PsbtInputTaprootInternalKey xOnly,
      required List<PsbtInputTaprootLeafScript>? scripts}) {
    if (!type.isP2tr) return null;
    final pubKeys = psbt.input.getInputs<PsbtInputMuSig2ParticipantPublicKeys>(
        index, PsbtInputTypes.muSig2ParticipantPublicKeys);
    if (pubKeys == null) return null;
    final nonces = psbt.input.getInputs<PsbtInputMuSig2PublicNonce>(
        index, PsbtInputTypes.muSig2PublicNonce);
    final signatures = psbt.input
        .getInputs<PsbtInputMuSig2ParticipantPartialSignature>(
            index, PsbtInputTypes.muSig2ParticipantPartialSignature);
    return PsbtMusig2InputInfo(
        publicKeys: pubKeys,
        nonces: nonces ?? [],
        partialSigs: signatures ?? []);
  }

  static List<String> _finalizeMultisigScript(
      {required PsbtGeneratedTransactionDigest digest,
      required MultiSignatureAddress multisig,
      bool fake = false}) {
    final currentScript =
        digest.params.witnessScript ?? digest.params.p2shRedeemScript!;
    final multisigSigners =
        multisig.signers.map((e) => ECPublic.fromHex(e.publicKey)).toList();
    List<PsbtInputPartialSig> validSignatures = [];
    if (!fake) {
      validSignatures = digest.getPartialSignatures(multisigSigners);
    }
    List<String> signatures = [];
    final threshold = multisig.threshold;
    for (int i = 0; i < multisig.signers.length; i++) {
      if (signatures.length >= threshold) break;
      final pubKey = multisigSigners[i];
      final signer = multisig.signers[i];

      final signature = fake
          ? fakeECDSASignatureBytes
          : validSignatures.firstWhereNullable((e) {
              return e.publicKey == pubKey && e.mode == signer.keyType;
            })?.signatureHex();
      if (signature != null) {
        for (int w = 0; w < signer.weight; w++) {
          signatures.add(signature);
          if (signatures.length >= threshold) break;
        }
      }
    }
    if (signatures.length < threshold) {
      throw DartBitcoinPluginException(
          "Missing multisig signatures: Required $threshold, but only ${signatures.length} provided.");
    }
    return [
      if (BitcoinScriptUtils.hasOpCheckMultisig(currentScript)) '',
      ...signatures,
      digest.params.redeemScript.toHex()
    ];
  }

  static List<String> _finalizeTaprootMultisigScript({
    required P2trMultiSignatureAddress p2trMultisig,
    required PsbtGeneratedTransactionDigest digest,
    bool fake = false,
  }) {
    final leafScript = digest.leafScript!;
    List<PsbtInputTaprootScriptSpendSignature> scriptSignatures = fake
        ? []
        : digest.getTaprootScriptSignatures(
            p2trMultisig.signers.map((e) => e.xOnly).toList());
    scriptSignatures = () {
      final sigs = scriptSignatures.map((e) {
        final inScript = findSciptKeyInfo(
            keyStr: e.xOnlyPubKeyHex, script: leafScript.script)!;
        return (e, inScript);
      }).toList()
        ..sort((a, b) => b.$2.index.compareTo(a.$2.index));
      return sigs.map((e) => e.$1).toList();
    }();
    List<String> signatures = [];
    int someWeight = 0;
    for (int i = 0; i < p2trMultisig.signers.length; i++) {
      final signer = p2trMultisig.signers[i];
      final signature = fake
          ? fakeSchnorSignaturBytes
          : scriptSignatures
              .firstWhereNullable((e) => e.xOnlyPubKeyHex == signer.xOnly)
              ?.signatureHex();
      for (int w = 0; w < signer.weight; w++) {
        if (someWeight >= p2trMultisig.threshold) {
          signatures.add('');
        } else {
          signatures.add(signature ?? '');
        }
        if (signature != null) someWeight++;
      }
    }
    if (someWeight < p2trMultisig.threshold) {
      throw DartBitcoinPluginException(
          "Missing P2TR multisig script signatures: Required ${p2trMultisig.threshold}, but only $someWeight provided.",
          details: {"leafScript": leafScript.script.toString()});
    }
    return [
      ...signatures.reversed,
      leafScript.script.toHex(),
      leafScript.controllBlockHex
    ];
  }

  static PsbtFinalizeInput _userFinalizeInput(
      {required PsbtFinalizeInput finalizeInput,
      required PsbtInputInfo params,
      required PsbtTxType txType}) {
    TxWitnessInput? witness = finalizeInput.witness;
    Script? scriptSig = finalizeInput.scriptSig;
    if (params.type.isSegwit) {
      if (witness == null) {
        throw DartBitcoinPluginException(
            "FinalizedScriptWitness required for witness UTXOs.");
      }
      if (params.p2shRedeemScript != null) {
        if (scriptSig == null) {
          throw DartBitcoinPluginException(
              "P2SH redeemScript required for P2SH-Segwit UTXOS.");
        }
      } else if (scriptSig != null) {
        throw DartBitcoinPluginException(
            "FinalizedScriptSig does not required for legacy UTXOS.");
      }
    } else {
      if (txType.isSegwit) {
        witness ??= TxWitnessInput(stack: []);
      }
      if (scriptSig == null) {
        throw DartBitcoinPluginException(
            "FinalizedScriptSig required for legacy UTXOS.");
      }
    }
    return PsbtFinalizeInput(witness: witness, scriptSig: scriptSig);
  }

  static List<String> _finalizeScriptSpent(
      PsbtGeneratedTransactionDigest digest,
      {bool fake = false}) {
    final currentScript =
        digest.params.witnessScript ?? digest.params.p2shRedeemScript!;
    if (BitcoinScriptUtils.isP2wpkh(currentScript)) {
      if (fake) {
        return [fakeECDSASignatureBytes, fakeEcdsaPubKey];
      }
      final signature = digest.getPartialSignature();
      final scriptPubKey =
          signature.publicKey.toP2wpkhInP2sh().toScriptPubKey();
      if (scriptPubKey != digest.params.scriptPubKey) {
        throw DartBitcoinPluginException(
            'Mismatch P2WPKH-P2SH signer scriptPubKey.');
      }
      return [signature.signatureHex(), signature.publicKey.toHex()];
    }

    if (BitcoinScriptUtils.isP2pkh(currentScript)) {
      final signature = digest.getPartialSignatureOrNull();
      final pubKey = signature == null
          ? null
          : findSciptKeyInfo(
              publicKey: signature.publicKey, script: currentScript);
      if (fake) {
        if (pubKey != null) {
          return [fakeECDSASignatureBytes, pubKey.key, currentScript.toHex()];
        }
        return [
          fakeECDSASignatureBytes,
          fakeUnCompresedEcdsaPubKey,
          currentScript.toHex()
        ];
      }
      if (signature == null || pubKey == null) {
        throw DartBitcoinPluginException(
            "Cannot find current signer key in signature.");
      }
      return [signature.signatureHex(), pubKey.key, currentScript.toHex()];
    } else if (BitcoinScriptUtils.isP2pk(currentScript)) {
      if (fake) {
        return [fakeECDSASignatureBytes, currentScript.toHex()];
      }
      final signature = digest.getPartialSignature();
      return [signature.signatureHex(), currentScript.toHex()];
    }
    final multisig = BitcoinScriptUtils.parseMultisigScript(currentScript);
    if (multisig != null) {
      return _finalizeMultisigScript(
          digest: digest, multisig: multisig, fake: fake);
    }
    if (currentScript.script.isEmpty) {
      return [currentScript.toHex()];
    }
    if (BitcoinScriptUtils.isOpTrue(currentScript)) {
      return [currentScript.toHex()];
    }
    if (BitcoinScriptUtils.isSha256(currentScript)) {
      return [digest.getScriptSha256(currentScript), currentScript.toHex()];
    }
    if (BitcoinScriptUtils.isHash256(currentScript)) {
      return [digest.getScriptHash256(currentScript), currentScript.toHex()];
    }
    if (BitcoinScriptUtils.isHash160(currentScript)) {
      return [digest.getScriptHash160(currentScript), currentScript.toHex()];
    }
    if (BitcoinScriptUtils.isRipemd160(currentScript)) {
      return [digest.getScriptRipemd160(currentScript), currentScript.toHex()];
    }
    if (BitcoinScriptUtils.isPubKeyOpCheckSig(currentScript)) {
      final signature = digest.getPartialSignature();
      final pubKey = findSciptKeyInfo(
          publicKey: signature.publicKey, script: currentScript);
      if (pubKey == null) {
        throw DartBitcoinPluginException(
            "Cannot find current signer public key in script.");
      }
      return [pubKey.key, currentScript.toHex()];
    }
    throw DartBitcoinPluginException(
      "Unable to finalize custom script input at index ${digest.params.index}. Please use the onFinalizeCallback to complete the input finalization. ${currentScript.toHex()}",
    );
  }

  static PsbtInputData? getReadyMusig2Signature(
      PsbtGeneratedTransactionDigest digest) {
    if (!digest.params.type.isP2tr) return null;
    final taprootParams = digest.params.cast<PsbtTaprootInputInfo>();
    final musig = taprootParams.musig2inputInfo;
    final script = digest.leafScript;
    final internalKey = taprootParams.internalPublicKey.xOnlyPubKey;
    if (musig == null) return null;
    final validSignatures = switch (script == null) {
      true => musig.getNonScriptSignatures(internalKey),
      false => musig.getScriptSignatures(script!.leafScript),
    };
    final validNonces = switch (script == null) {
      true => musig.getNonScriptNonces(internalKey),
      false => musig.getScriptNonces(script!.leafScript),
    };
    PsbtInputMuSig2ParticipantPublicKeys? key = switch (script == null) {
      true => musig.getNonceScriptPublicKey(internalKey),
      false => musig.getScriptPublicKey(script!.leafScript),
    };
    if (key == null ||
        validNonces.length != validSignatures.length ||
        validNonces.length != key.pubKeys.length) {
      return null;
    }
    final tweak = digest.generateTaprootTweak();
    List<int> signature = MuSig2.partialSigAgg(
      signatures: validSignatures.map((e) => e.signature).toList(),
      session: MuSig2Session(
          tweaks: [if (tweak != null) MuSig2Tweak(tweak: tweak)],
          aggnonce:
              MuSig2.nonceAgg(validNonces.map((e) => e.publicNonce).toList()),
          publicKeys: key.pubKeys
              .map((e) => e.toBytes(mode: PubKeyModes.compressed))
              .toList(),
          msg: digest.digest),
    );
    signature = [
      ...signature,
      if (digest.sighashType != BitcoinOpCodeConst.sighashDefault)
        digest.sighashType
    ];
    if (digest.leafScript != null) {
      return PsbtInputTaprootScriptSpendSignature(
          signature: signature,
          xOnlyPubKey: validNonces.first.plainPublicKey.toXOnly(),
          leafHash: digest.leafScript!.leafScript.hash());
    }
    return PsbtInputTaprootKeySpendSignature(signature);
  }

  static List<String> _finalizeTaprootScriptSpent(
      {required PsbtGeneratedTransactionDigest digest,
      required PsbtInput input,
      bool fake = false}) {
    PsbtInputTaprootLeafScript? leafScript = digest.leafScript;

    if (leafScript == null) {
      throw DartBitcoinPluginException(
          "No tapleaf script found to finalize input at index ${digest.params.index}.",
          details: {"scriptPubKey": digest.params.scriptPubKey.toString()});
    }
    final currentScript = leafScript.script;
    final script = currentScript.toHex();
    final controlBlock = leafScript.controllBlockHex;

    if (BitcoinScriptUtils.hasAnyOpCheckSig(currentScript)) {
      if (BitcoinScriptUtils.isXOnlyOpChecksig(currentScript)) {
        if (fake) {
          return [fakeSchnorSignaturBytes, script, controlBlock];
        }
        final signature = digest
            .getTaprootScriptSignature(currentScript.script[0].toString());
        return [signature.signatureHex(), script, controlBlock];
      }
      final taprootMultisig =
          BitcoinScriptUtils.isP2trMultiScript(leafScript.script);
      if (taprootMultisig != null) {
        return _finalizeTaprootMultisigScript(
            p2trMultisig: taprootMultisig, digest: digest, fake: fake);
      }
    } else {
      if (currentScript.script.isEmpty) {
        return [currentScript.toHex(), script, controlBlock];
      }
      if (BitcoinScriptUtils.isOpTrue(currentScript)) {
        return [currentScript.toHex(), script, controlBlock];
      }
      if (BitcoinScriptUtils.isSha256(currentScript)) {
        return [digest.getScriptSha256(currentScript), script, controlBlock];
      }
      if (BitcoinScriptUtils.isHash256(currentScript)) {
        return [digest.getScriptHash256(currentScript), script, controlBlock];
      }
      if (BitcoinScriptUtils.isHash160(currentScript)) {
        return [digest.getScriptHash160(currentScript), script, controlBlock];
      }
      if (BitcoinScriptUtils.isRipemd160(currentScript)) {
        return [digest.getScriptRipemd160(currentScript), script, controlBlock];
      }
    }
    throw DartBitcoinPluginException(
      "Unable to finalize custom script input at index ${digest.params.index}. Please use the onFinalizeCallback to complete the input finalization.",
    );
  }

  static List<String> _finalizeNonScriptSpent(
      {required PsbtGeneratedTransactionDigest digest,
      required PsbtInput input,
      bool fake = false}) {
    final script = digest.params.scriptPubKey;
    if (BitcoinScriptUtils.isP2tr(script)) {
      if (fake) {
        return [fakeSchnorSignaturBytes];
      }
      return [digest.getTaprootKeyPathSignature()];
    } else if (BitcoinScriptUtils.isP2pk(digest.params.scriptPubKey)) {
      if (fake) {
        return [fakeECDSASignatureBytes];
      }
      return [digest.getPartialSignature().signatureHex()];
    } else if (BitcoinScriptUtils.isP2pkh(script) ||
        BitcoinScriptUtils.isP2wpkh(script)) {
      final sig = digest.getPartialSignatureOrNull();
      final pk = sig == null
          ? null
          : findSciptKeyInfo(publicKey: sig.publicKey, script: script);
      if (fake) {
        return [
          sig?.signatureHex() ?? fakeECDSASignatureBytes,
          pk?.key ??
              (BitcoinScriptUtils.isP2wpkh(script)
                  ? fakeEcdsaPubKey
                  : fakeUnCompresedEcdsaPubKey)
        ];
      }

      if (pk == null || sig == null) {
        throw DartBitcoinPluginException(
            "Signature public key does not match the scriptPubKey for input ${digest.params.index}.");
      }
      return [sig.signatureHex(), pk.key];
    }
    throw DartBitcoinPluginException(
        "Unable to finalize custom script input at index ${digest.params.index}. Please use the onFinalizeCallback to complete the input finalization.",
        details: {"scriptPubKey": digest.params.scriptPubKey.toString()});
  }

  static final List<int> fakeFinalizeGlobalIdentifier =
      'fake_finalize'.codeUnits.asImmutableBytes;

  static PsbtFinalizeInput finalizeInput(
      {required Psbt psbt,
      required int index,
      required List<TxInput> txInputs,
      required BtcTransaction unsignedTx,
      PsbtFinalizeResponse? userFinalizedInput}) {
    final userData = psbt.global.getGlobals<PsbtGlobalProprietaryUseType>(
            PsbtGlobalTypes.proprietary) ??
        [];
    bool fake = userData.any((e) =>
        BytesUtils.bytesEqual(e.identifier, fakeFinalizeGlobalIdentifier));
    final txType = getTxType(psbt.input);
    final params =
        getPsbtInputInfo(psbt: psbt, inputIndex: index, txInputs: txInputs);
    final digest = generateInputTransactionDigest(
        index: index,
        unsignedTx: unsignedTx,
        params: params,
        tapleafHash: userFinalizedInput?.tapleafHash,
        input: psbt.input,
        psbt: psbt);
    if (userFinalizedInput?.finalizeInput != null) {
      return _userFinalizeInput(
          finalizeInput: userFinalizedInput!.finalizeInput!,
          params: params,
          txType: txType);
    }
    List<String> unlockScript = switch (params.isScriptSpending) {
      false =>
        _finalizeNonScriptSpent(digest: digest, input: psbt.input, fake: fake),
      true => () {
          if (params.type.isP2tr) {
            return _finalizeTaprootScriptSpent(
                digest: digest, input: psbt.input, fake: fake);
          }
          return _finalizeScriptSpent(digest, fake: fake);
        }(),
    };
    if (txType.isLegacy) {
      return PsbtFinalizeInput(scriptSig: Script(script: unlockScript));
    }
    if (params.isScriptSpending) {
      if (params.type.isLegacy) {
        return PsbtFinalizeInput(
            scriptSig: Script(script: unlockScript),
            witness: TxWitnessInput(stack: []));
      }
      return PsbtFinalizeInput(
          witness: TxWitnessInput(stack: unlockScript),
          scriptSig: params.p2shRedeemScript != null
              ? Script(script: [params.p2shRedeemScript!.toHex()])
              : null);
    } else {
      if (params.type.isLegacy) {
        return PsbtFinalizeInput(
            scriptSig: Script(script: unlockScript),
            witness: TxWitnessInput(stack: []));
      }
      return PsbtFinalizeInput(witness: TxWitnessInput(stack: unlockScript));
    }
  }

  static PsbtInputLocktime _toLocktime(int locktime) {
    if (locktime.isNegative || locktime > maxUint32) {
      throw DartBitcoinPluginException(
          "Invalid integer provided as locktime: The locktime value must be a valid unsigned 32-bit integer.");
    }
    return PsbtInputLocktime(
        isBlockBased: locktime < BitcoinOpCodeConst.minInputLocktime,
        timelock: locktime);
  }

  static PsbtInputLocktime? getCurrentInputslocktime(
      {required List<TxInput> inputs}) {
    int? height;
    int? timeLock;
    for (final i in inputs) {
      final lock = i.sequenceAsNumber();
      if (lock == maxUint32) continue;
      final locktime = _toLocktime(lock);
      if (locktime.isBlockBased) {
        height = IntUtils.max(locktime.timelock, height ?? 0);
        continue;
      }
      timeLock = IntUtils.max(locktime.timelock, timeLock ?? 0);
    }
    if (height == null && timeLock == null) return null;
    if (timeLock != null && height != null) {
      throw DartBitcoinPluginException(
          "Invalid Psbt input: Cannot mix height-based and time-based locktimes in a PSBT.");
    }
    return PsbtInputLocktime(
        isBlockBased: height != null, timelock: timeLock ?? height!);
  }

  static List<int> buildTransactionLocktime(
      {required List<TxInput> inputs, List<int>? locktimeFallBack}) {
    final lock = getCurrentInputslocktime(inputs: inputs);
    if (lock == null) {
      return locktimeFallBack ?? BitcoinOpCodeConst.defaultTxLocktime;
    }
    return IntUtils.toBytes(lock.timelock,
        length: BitcoinOpCodeConst.locktimeLengthInBytes,
        byteOrder: Endian.little);
  }

  static int _validateAndGetSigHashType(
      {required PsbtTxType inputType,
      required PsbtInput input,
      required int index,
      int? sighashType}) {
    final sighash =
        input.getInput<PsbtInputSigHash>(index, PsbtInputTypes.sighashType);
    if (sighashType != null) {
      if (sighash == null) return sighashType;
      if (sighashType != sighash.sighash) {
        throw DartBitcoinPluginException(
            "Input is marked with a different sighash type. Please update the input sighash type first.");
      }
      return sighashType;
    }
    if (sighash != null) return sighash.sighash;
    if (inputType.isP2tr) return BitcoinOpCodeConst.sighashDefault;
    return BitcoinOpCodeConst.sighashAll;
  }

  static PsbtGeneratedTransactionDigest generateInputTransactionDigest(
      {required int index,
      required BtcTransaction unsignedTx,
      required PsbtInputInfo params,
      required List<int>? tapleafHash,
      required PsbtInput input,
      required Psbt psbt,
      int? sighashType}) {
    sighashType = _validateAndGetSigHashType(
        inputType: params.type,
        index: index,
        input: input,
        sighashType: sighashType);
    PsbtInputTaprootLeafScript? tapleafScript;
    List<int> digest;
    if (isSighashForked(sighashType)) {
      if (params.type == PsbtTxType.witnessV1) {
        throw DartBitcoinPluginException(
            "Invalid sighash type: Forked sighash types are not compatible with witness v1 transactions.");
      }
      final v0Input = params.cast<PsbtNonTaprootInputInfo>();
      digest = unsignedTx.getTransactionSegwitDigit(
          txInIndex: index,
          script: v0Input.redeemScript,
          sighash: sighashType,
          amount: params.amount);
    } else {
      digest = switch (params.type) {
        PsbtTxType.legacy => () {
            final legacyInput = params.cast<PsbtNonTaprootInputInfo>();
            return unsignedTx.getTransactionDigest(
                txInIndex: index,
                script: legacyInput.redeemScript,
                sighash: sighashType!);
          }(),
        PsbtTxType.witnessV0 => () {
            final v0Input = params.cast<PsbtNonTaprootInputInfo>();
            return unsignedTx.getTransactionSegwitDigit(
                txInIndex: index,
                script: v0Input.redeemScript,
                sighash: sighashType!,
                amount: params.amount);
          }(),
        PsbtTxType.witnessV1 => () {
            final tapInput = params.cast<PsbtTaprootInputInfo>();
            if (tapInput.tapleafScripts != null) {
              tapleafScript = PsbtUtils.findCorrectLeafScript(
                  tapLeafScripts: tapInput.tapleafScripts!,
                  tapleafHash: tapleafHash,
                  index: index);
            }
            return unsignedTx.getTransactionTaprootDigset(
                txIndex: index,
                scriptPubKeys: tapInput.allScriptPubKeys,
                sighash: sighashType!,
                amounts: tapInput.allAmounts,
                tapleafScript: tapleafScript?.leafScript);
          }(),
      };
    }

    return PsbtGeneratedTransactionDigest(
        digest: digest,
        sighashType: sighashType,
        leafScript: tapleafScript,
        params: params,
        psbt: psbt);
  }

  static void validateNewInputLocktime(
      {required List<TxInput> inputs, required TxInput newInput}) {
    final inputSequence = newInput.sequenceAsNumber();
    if (inputSequence == maxUint32) return;
    final currentLocktime = getCurrentInputslocktime(inputs: inputs);
    if (currentLocktime == null) return;
    final locktime = _toLocktime(inputSequence);
    if (currentLocktime.isBlockBased == locktime.isBlockBased) {
      return;
    }
    throw DartBitcoinPluginException(
        "Invalid Psbt input: Cannot mix height-based and time-based locktimes in a PSBT.");
  }

  static List<int> _validateSchnorrSignature(
      {required List<int> signature,
      required int index,
      required int expectedSighash}) {
    if (!CryptoSignatureUtils.isValidSchnorrSignature(signature)) {
      throw DartBitcoinPluginException(
          "Invalid Schnorr signature at input $index. Signature may be malformed or improperly formatted.");
    }
    if (signature.length == CryptoSignerConst.schnoorSginatureLength) {
      if (expectedSighash == BitcoinOpCodeConst.sighashDefault) {
        return signature;
      }
      return [...signature, expectedSighash];
    }
    if (signature.last != expectedSighash) {
      throw DartBitcoinPluginException(
          "Signature mismatch at input $index: Expected sighash $expectedSighash, but got ${signature.last}. The Schnorr signature may be malformed or improperly formatted.");
    }
    return signature;
  }

  static List<int> _validateEcdsaSignature(
      {required List<int> signature,
      required int index,
      required int expectedSighash}) {
    if (!CryptoSignatureUtils.isValidBitcoinDERSignature(signature)) {
      throw DartBitcoinPluginException(
          "Invalid DER-encoded signature at input $index. Signature may be malformed or improperly formatted.");
    }
    if (signature.last != expectedSighash) {
      throw DartBitcoinPluginException(
          "Signature mismatch at input $index: Expected sighash $expectedSighash, but got ${signature.last}. The DER-encoded signature may be malformed or improperly formatted.");
    }
    return signature;
  }

  static bool verifyBchSchnorrSignature(
      List<int> digest, List<int> signature, ECPublic pubKey) {
    if (digest.length != 32) {
      throw const ArgumentException("The message must be a 32-byte array.");
    }
    if (signature.length != 64) {
      throw const ArgumentException("Invalid signature length.");
    }

    final BigInt order = Curves.generatorSecp256k1.order!;
    final List<int> rBytes = signature.sublist(0, 32);
    final List<int> sBytes = signature.sublist(32, 64);

    final BigInt rX = BigintUtils.fromBytes(rBytes);
    final BigInt s = BigintUtils.fromBytes(sBytes);

    if (s >= order) {
      return false;
    }

    final P = pubKey.point;
    BigInt e = BigintUtils.fromBytes(QuickCrypto.sha256Hash([
          ...rBytes,
          ...pubKey.toBytes(mode: PubKeyModes.compressed),
          ...digest
        ])) %
        order;
    final sp = Curves.generatorSecp256k1 * s;

    if (P.y.isEven) {
      e = Curves.generatorSecp256k1.order! - e;
    }
    final ProjectiveECCPoint eP = P * e;

    final R = sp + eP;
    if (R.isInfinity) return false;
    if (R.y.isOdd || R.x != rX) {
      return false;
    }
    return true;
  }

  static List<int> validateSignature(
      {required List<int> signature,
      required int index,
      required int expectedSighash,
      required PsbtTxType type}) {
    if (type.isP2tr ||
        CryptoSignatureUtils.isValidSchnorrSignature(signature)) {
      return _validateSchnorrSignature(
          signature: signature, index: index, expectedSighash: expectedSighash);
    }
    return _validateEcdsaSignature(
        signature: signature, index: index, expectedSighash: expectedSighash);
  }

  static List<int> validateMusigPartialSignature(
      {required List<int> signature, required int index}) {
    if (!MuSig2Utils.isValidPartialSignature(signature)) {
      throw DartBitcoinPluginException(
          "Invalid Musig2 Schnorr partial signature at input $index. Signature may be malformed or improperly formatted.");
    }
    return signature;
  }

  static List<PsbtInputSighashInfo> getAllExistsSighashType(
      PsbtInput psbtInput, PsbtTxType txType) {
    List<PsbtInputSighashInfo> sighashInfos = [];
    for (int i = 0; i < psbtInput.length; i++) {
      final sighashType =
          psbtInput.getInput<PsbtInputSigHash>(i, PsbtInputTypes.sighashType);
      if (sighashType != null) {
        sighashInfos.add(PsbtInputSighashInfo(
            inputIndex: i, sighashType: sighashType.sighash));
        continue;
      }
      final exitSignatures =
          psbtInput.entries[i].whereType<PsbtInputDataSignature>().toList();
      final finalizeScriptSig = psbtInput.getInput<PsbtInputFinalizedScriptSig>(
          i, PsbtInputTypes.finalizedScriptSig);
      final finalizeWitness =
          psbtInput.getInput<PsbtInputFinalizedScriptWitness>(
              i, PsbtInputTypes.finalizedWitness);
      if (finalizeWitness != null ||
          finalizeScriptSig != null ||
          exitSignatures.isNotEmpty) {
        sighashInfos.add(PsbtInputSighashInfo(
            inputIndex: i,
            sighashType: txType.isP2tr
                ? BitcoinOpCodeConst.sighashDefault
                : BitcoinOpCodeConst.sighashAll));
      }
    }
    return sighashInfos;
  }

  static int? getInputSigHash(PsbtInput psbtInput, int index) {
    final sighashType =
        psbtInput.getInput<PsbtInputSigHash>(index, PsbtInputTypes.sighashType);
    if (sighashType != null) {
      return sighashType.sighash;
    }
    return null;
  }

  static void validateCanAddOrUpdateOutput(
      {required Psbt psbt, int? outputIndex, bool isUpdate = true}) {
    final sighashes =
        getAllExistsSighashType(psbt.input, getTxType(psbt.input));
    for (final i in sighashes) {
      if (!i.canModifyOutput(
          outputIndex: outputIndex ?? -1,
          isUpdate: isUpdate,
          allSigashes: sighashes)) {
        throw DartBitcoinPluginException(
            "Unable to modify output${outputIndex == null ? '' : ' $outputIndex'}. A signature with an unmodifiable sighash flag exists, preventing changes.");
      }
    }
  }

  static void validateTxInputs({
    required PsbtInput psbInput,
    required int inputIndex,
    int? inputsLength,
  }) {
    if (inputIndex >= psbInput.length) {
      throw DartBitcoinPluginException(
          "Invalid input index: $inputIndex. The PSBT contains only ${psbInput.length} inputs.");
    }
    if (inputsLength != null && inputsLength != psbInput.length) {
      throw DartBitcoinPluginException(
          "Invalid PSBT: transaction inputs length does not match PSBT inputs length.");
    }
  }

  static void validateTxOutputs(
      {required PsbtOutput psbtOutput,
      required int outputIndex,
      List<TxOutput>? outputs}) {
    if (outputIndex >= psbtOutput.length) {
      throw DartBitcoinPluginException(
          "Invalid output index: $outputIndex. The PSBT contains only ${psbtOutput.length} outputs.");
    }
    if (outputs != null && outputs.length != psbtOutput.length) {
      throw DartBitcoinPluginException(
          "Invalid PSBT: transaction outputs length does not match PSBT outputs length.");
    }
  }

  static void validateCanAddOrUpdateInput(
      {required Psbt psbt, int? inputIndex}) {
    final sighashes =
        getAllExistsSighashType(psbt.input, getTxType(psbt.input));
    if (psbt.input.length == 1) return;
    for (final i in sighashes) {
      if (!i.canModifyInput(inputIndex ?? -1)) {
        throw DartBitcoinPluginException(
            "Unable to modify input${inputIndex == null ? '' : ' $inputIndex'}. A signature with an unmodifiable sighash flag exists, preventing changes.");
      }
    }
  }

  static bool finalized({required PsbtInput input, required int index}) {
    bool alreadyFinalized =
        input.hasInput(index, PsbtInputTypes.finalizedScriptSig);
    return alreadyFinalized |=
        input.hasInput(index, PsbtInputTypes.finalizedWitness);
  }

  static PsbtInputData getPsbtSequenceInputData(TxInput input) {
    final sequenceNumber = input.sequenceAsNumber();
    if (sequenceNumber == mask32) {
      return PsbtInputSequenceNumber(sequenceNumber);
    } else if (sequenceNumber < BitcoinOpCodeConst.minInputLocktime) {
      return PsbtInputRequiredTimeBasedLockTime(sequenceNumber);
    }
    return PsbtInputRequiredHeightBasedLockTime(sequenceNumber);
  }

  static void validateAddMusig2PubKeyNonce(
      {required int inputIndex,
      required Psbt psbt,
      required List<TxInput> txInputs,
      required PsbtInputMuSig2PublicNonce pubKeyNonce}) {
    final info = getPsbtInputInfo(
        psbt: psbt, inputIndex: inputIndex, txInputs: txInputs);
    if (!info.type.isP2tr) {
      throw DartBitcoinPluginException(
          "Invalid input type: MuSig2 requires a Taproot (P2TR) input, but a non-Taproot input was detected.");
    }
    final aggPubKeys = psbt.input
        .getInputs<PsbtInputMuSig2ParticipantPublicKeys>(
            inputIndex, PsbtInputTypes.muSig2ParticipantPublicKeys);
    final nonces = psbt.input.getInputs<PsbtInputMuSig2PublicNonce>(
        inputIndex, PsbtInputTypes.muSig2PublicNonce);
    if (aggPubKeys == null) {
      throw DartBitcoinPluginException(
          "Missing MuSig2 participant public keys: PSBT input at index $inputIndex does not contain MuSig2 aggregated public keys.");
    }
    final taprootParams = info.cast<PsbtTaprootInputInfo>();
    aggPubKeys.firstWhere(
      (e) => e.pubKeys.contains(pubKeyNonce.publicKey),
      orElse: () => throw DartBitcoinPluginException(
          "Public key not found: The provided public key is not part of any MuSig2 participant set in the PSBT input at index $inputIndex."),
    );
    if (taprootParams.isKeyPath && pubKeyNonce.tapleafHash != null) {
      throw DartBitcoinPluginException(
          "Key-path spending does not use a tapleaf hash.");
    }

    if (taprootParams.isScriptSpending) {
      if (pubKeyNonce.tapleafHash == null) {
        throw DartBitcoinPluginException(
            "Script-path spending requires a tapleaf hash.");
      }
      taprootParams.tapleafScripts!.firstWhere(
        (e) =>
            BytesUtils.bytesEqual(e.leafScript.hash(), pubKeyNonce.tapleafHash),
        orElse: () => throw DartBitcoinPluginException(
            "Taproot script not found: No tapleaf script matches the provided tapleaf hash."),
      );
    }

    if (nonces != null &&
        nonces.any((e) =>
            e.plainPublicKey == pubKeyNonce.plainPublicKey &&
            e.publicKey == pubKeyNonce.publicKey &&
            BytesUtils.bytesEqual(e.tapleafHash, pubKeyNonce.tapleafHash))) {
      throw DartBitcoinPluginException(
          "Duplicate nonce detected: A nonce with the same public key and tapleaf hash already exists.");
    }
  }

  static bool canChangeOutput(int sighashType) {
    if (sighashType == BitcoinOpCodeConst.sighashDefault) return false;
    if (isSighash(sighashType, BitcoinOpCodeConst.sighashAll)) return false;
    return true;
  }

  static bool isSighash(int sighash, int type) {
    return (sighash & 0x1F) == type;
  }

  static bool isSighashForked(int sighash) {
    return (sighash & BitcoinOpCodeConst.sighashForked ==
            BitcoinOpCodeConst.sighashForked) ||
        (sighash & 0x1F) == BitcoinOpCodeConst.sighashForked;
  }

  static bool isAnyoneCanPay(int sighash) {
    return (sighash & BitcoinOpCodeConst.sighashAnyoneCanPay) != 0;
  }
}
