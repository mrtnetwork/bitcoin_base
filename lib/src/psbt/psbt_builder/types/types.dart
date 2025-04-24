import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:bitcoin_base/src/psbt/psbt.dart';
import 'package:bitcoin_base/src/psbt/types/types/types.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

typedef ONBTCSIGNER = PsbtSignerResponse? Function(PsbtSignerParams);
typedef ONBTCSIGNERASYNC<INPUT extends PsbtTransactionInput>
    = Future<PsbtSignerResponse?> Function(PsbtSignerParams);
typedef ONUPDATEPSBTINPUT<INPUT extends PsbtTransactionInput> = INPUT Function(
    INPUT);
typedef ONFINALIZEINPUT<INPUT extends PsbtTransactionInput>
    = PsbtFinalizeResponse? Function(PsbtFinalizeParams params);
typedef ONFINALIZEINPUTASYNC<INPUT extends PsbtTransactionInput>
    = Future<PsbtFinalizeResponse>? Function(PsbtFinalizeParams);

class PsbtTransactionInput {
  final TxInput txInput;
  final BitcoinBaseAddress address;
  final Script scriptPubKey;

  final PsbtInputSigHash? sigHashType;

  // Mutually exclusive UTXO data
  final PsbtInputNonWitnessUtxo? nonWitnessUtxo;
  final PsbtInputWitnessUtxo? witnessUtxo;

  // Scripts (cannot mix P2SH and P2WSH)
  final PsbtInputRedeemScript? redeemScript;
  final PsbtInputWitnessScript? witnessScript;

  // BIP32 Key Path
  final List<PsbtInputBip32DerivationPath>? bip32derivationPath;

  // Taproot (conditional)
  final PsbtInputTaprootInternalKey? taprootInternalKey;
  final List<PsbtInputTaprootLeafScript>? taprootLeafScript;
  final PsbtInputTaprootKeySpendSignature? taprootKeySpendSignature;
  final List<PsbtInputTaprootScriptSpendSignature>? taprootScriptSpendSignature;
  final PsbtInputTaprootMerkleRoot? taprootMerkleRoot;
  final List<PsbtInputTaprootKeyBip32DerivationPath>?
      taprootKeyBip32DerivationPath;

  // MuSig2 (Optional, for multisig Taproot)
  final List<PsbtInputMuSig2ParticipantPublicKeys>? muSig2ParticipantPublicKeys;
  final List<PsbtInputMuSig2PublicNonce>? muSig2PublicNonce;
  final List<PsbtInputMuSig2ParticipantPartialSignature>?
      muSig2ParticipantPartialSignature;

  // Optional (hashes & commitments)
  final PsbtInputPorCommitments? porCommitments;
  final List<PsbtInputRipemd160>? ripemd160;
  final List<PsbtInputSha256>? sha256;
  final List<PsbtInputHash160>? hash160;
  final List<PsbtInputHash256>? hash256;

  // Proprietary Use
  final List<PsbtInputProprietaryUseType>? proprietaryUseType;

  final List<PsbtInputPartialSig>? partialSigs;
  final PsbtInputFinalizedScriptSig? finalizedScriptSig;
  final PsbtInputFinalizedScriptWitness? finalizedScriptWitness;

  final PsbtInputSilentPaymentInputECDHShare? silentPaymentInputECDHShare;
  final PsbtInputSilentPaymentInputDLEQProof? silentPaymentInputDLEQProof;

  factory PsbtTransactionInput.fromUtxo(PsbtUtxo psbtUtxo) {
    final utxo = psbtUtxo.utxo;
    if (utxo.isP2tr) {
      return PsbtTransactionInput.witnessV1(
        outIndex: utxo.vout,
        txId: utxo.txHash,
        nonWitnessUtxo: psbtUtxo.tx,
        amount: utxo.value,
        xOnlyOrInternalPubKey: psbtUtxo.xOnlyOrInternalPubKey,
        treeScript: psbtUtxo.treeScript,
        scriptPubKey: psbtUtxo.scriptPubKey,
        merkleRoot: psbtUtxo.merkleRoot,
        merkleProof: psbtUtxo.merkleProof,
        leafScript: psbtUtxo.leafScript,
        muSig2ParticipantPublicKeys: psbtUtxo.muSig2ParticipantPublicKeys,
        hash160: psbtUtxo.hash160,
        hash256: psbtUtxo.hash256,
        ripemd160: psbtUtxo.ripemd160,
        sha256: psbtUtxo.sha256,
      );
    } else if (utxo.isSegwit) {
      return PsbtTransactionInput.witnessV0(
        outIndex: utxo.vout,
        txId: utxo.txHash,
        nonWitnessUtxo: psbtUtxo.tx,
        amount: utxo.value,
        witnessScript: psbtUtxo.p2wshWitnessScript,
        scriptPubKey: psbtUtxo.scriptPubKey,
        redeemScript: psbtUtxo.p2shRedeemScript,
        hash160: psbtUtxo.hash160,
        hash256: psbtUtxo.hash256,
        ripemd160: psbtUtxo.ripemd160,
        sha256: psbtUtxo.sha256,
      );
    } else {
      return PsbtTransactionInput.legacy(
        outIndex: utxo.vout,
        txId: utxo.txHash,
        nonWitnessUtxo: psbtUtxo.tx,
        scriptPubKey: psbtUtxo.scriptPubKey,
        amount: utxo.value,
        redeemScript: psbtUtxo.p2shRedeemScript,
        hash160: psbtUtxo.hash160,
        hash256: psbtUtxo.hash256,
        ripemd160: psbtUtxo.ripemd160,
        sha256: psbtUtxo.sha256,
      );
    }
  }

  PsbtTransactionInput._(
      {required this.txInput,
      required this.address,
      required this.scriptPubKey,
      this.sigHashType,
      this.nonWitnessUtxo,
      this.witnessUtxo,
      this.redeemScript,
      this.witnessScript,
      this.bip32derivationPath,
      this.taprootInternalKey,
      this.taprootLeafScript,
      this.taprootKeySpendSignature,
      this.taprootScriptSpendSignature,
      this.taprootMerkleRoot,
      this.taprootKeyBip32DerivationPath,
      this.muSig2ParticipantPublicKeys,
      this.muSig2PublicNonce,
      this.muSig2ParticipantPartialSignature,
      this.porCommitments,
      this.ripemd160,
      this.sha256,
      this.hash160,
      this.hash256,
      this.proprietaryUseType,
      this.partialSigs,
      this.finalizedScriptSig,
      this.finalizedScriptWitness,
      this.silentPaymentInputDLEQProof,
      this.silentPaymentInputECDHShare});
  factory PsbtTransactionInput.legacy(
      {required int outIndex,
      required String txId,
      List<int>? sequence,
      Script? scriptPubKey,
      Script? redeemScript,
      BitcoinBaseAddress? address,
      int? sigHashType,
      BtcTransaction? nonWitnessUtxo,
      BigInt? amount,
      List<PsbtInputBip32DerivationPath>? bip32derivationPath,
      PsbtInputPorCommitments? porCommitments,
      List<PsbtInputRipemd160>? ripemd160,
      List<PsbtInputSha256>? sha256,
      List<PsbtInputHash160>? hash160,
      List<PsbtInputHash256>? hash256,
      List<PsbtInputProprietaryUseType>? proprietaryUseType,
      List<PsbtInputPartialSig>? partialSigs,
      PsbtInputFinalizedScriptSig? finalizedScriptSig}) {
    scriptPubKey ??= address?.toScriptPubKey();
    if (nonWitnessUtxo == null) {
      throw DartBitcoinPluginException("Missing input non-witness UTXOs.");
    }
    nonWitnessUtxo = PsbtUtils.cleanUpAdnValidateNonUtxoWitness(
        transaction: nonWitnessUtxo, outIndex: outIndex, txId: txId);

    final output = nonWitnessUtxo.outputs[outIndex];
    if (scriptPubKey != null && output.scriptPubKey != scriptPubKey) {
      throw DartBitcoinPluginException(
          "Mismatch detected: The provided scriptPubKey does not match the nonWitnessUtxo output scriptPubKey.");
    }
    final type = PsbtUtils.findScriptType(output.scriptPubKey);
    if (type.isP2tr) {
      throw DartBitcoinPluginException(
          "Incorrect legacy scriptPubKey. Use `witnessV1` constractor instead of `legacy` for taproot spending.",
          details: {"type": type.name});
    }
    if (type.isSegwit) {
      throw DartBitcoinPluginException(
          "Incorrect legacy scriptPubKey. Use `witnessV0` constractor instead of `legacy` for segwit spending.",
          details: {"type": type.name});
    }
    if (type.isP2sh) {
      if (redeemScript == null) {
        throw DartBitcoinPluginException(
            "redeemScript is required to spend P2SH scripts.",
            details: {"script": scriptPubKey?.script.join(", ")});
      }
      if (BitcoinScriptUtils.isP2wsh(redeemScript) ||
          BitcoinScriptUtils.isP2wpkh(redeemScript)) {
        throw DartBitcoinPluginException(
            "Incorrect legacy scriptPubKey. Use `witnessV1` constractor instead of `legacy` for nested segwit p2sh spending.",
            details: {"type": type.name});
      }
      P2shAddress addr;
      if (type.isP2sh32) {
        addr = P2shAddress.fromScript32(script: redeemScript);
      } else {
        addr = P2shAddress.fromScript(script: redeemScript);
      }
      if (addr.toScriptPubKey() != output.scriptPubKey) {
        throw DartBitcoinPluginException("Incorrect redeem script.",
            details: {"type": type.name});
      }
    }
    address ??=
        BitcoinScriptUtils.generateAddressFromScriptPubKey(output.scriptPubKey);
    return PsbtTransactionInput._(
        txInput: TxInput(txId: txId, txIndex: outIndex, sequance: sequence),
        sigHashType: sigHashType == null ? null : PsbtInputSigHash(sigHashType),
        nonWitnessUtxo: PsbtInputNonWitnessUtxo(nonWitnessUtxo),
        redeemScript:
            redeemScript == null ? null : PsbtInputRedeemScript(redeemScript),
        bip32derivationPath: bip32derivationPath,
        porCommitments: porCommitments,
        ripemd160: ripemd160,
        sha256: sha256,
        hash160: hash160,
        hash256: hash256,
        proprietaryUseType: proprietaryUseType,
        partialSigs: partialSigs,
        finalizedScriptSig: finalizedScriptSig,
        scriptPubKey: output.scriptPubKey,
        address: address);
  }

  /// **Factory method with validation**
  factory PsbtTransactionInput.witnessV0({
    required int outIndex,
    required String txId,
    List<int>? sequence,
    BigInt? amount,
    Script? scriptPubKey,
    Script? redeemScript,
    BitcoinBaseAddress? address,
    int? sigHashType,
    BtcTransaction? nonWitnessUtxo,
    Script? witnessScript,
    List<PsbtInputBip32DerivationPath>? bip32derivationPath,
    List<PsbtInputMuSig2ParticipantPublicKeys>? muSig2ParticipantPublicKeys,
    List<PsbtInputMuSig2PublicNonce>? muSig2PublicNonce,
    List<PsbtInputMuSig2ParticipantPartialSignature>?
        muSig2ParticipantPartialSignature,
    PsbtInputPorCommitments? porCommitments,
    List<PsbtInputRipemd160>? ripemd160,
    List<PsbtInputSha256>? sha256,
    List<PsbtInputHash160>? hash160,
    List<PsbtInputHash256>? hash256,
    List<PsbtInputProprietaryUseType>? proprietaryUseType,
    List<PsbtInputPartialSig>? partialSigs,
    PsbtInputFinalizedScriptSig? finalizedScriptSig,
    PsbtInputFinalizedScriptWitness? finalizedScriptWitness,
  }) {
    scriptPubKey ??= address?.toScriptPubKey();
    if (nonWitnessUtxo == null) {
      if (scriptPubKey == null || amount == null) {
        throw DartBitcoinPluginException(
            "either 'nonWitnessUtxo' or both scriptPubKey and amount required.");
      }
    }

    if (nonWitnessUtxo != null) {
      nonWitnessUtxo = PsbtUtils.cleanUpAdnValidateNonUtxoWitness(
          transaction: nonWitnessUtxo, outIndex: outIndex, txId: txId);

      final output = nonWitnessUtxo.outputs[outIndex];
      if (scriptPubKey != null) {
        if (scriptPubKey != output.scriptPubKey) {
          throw DartBitcoinPluginException(
              "Mismatch between scriptPubKey and nonWitnessUtxo output scriptPubKey.");
        }
      }
      scriptPubKey ??= output.scriptPubKey;
      amount ??= output.amount;
      if (amount != output.amount) {
        throw DartBitcoinPluginException(
            "Mismatch between amount and nonWitnessUtxo output amount.");
      }
    }
    final type = PsbtUtils.findScriptType(scriptPubKey!);
    if (type.isP2sh) {
      if (nonWitnessUtxo == null) {
        throw DartBitcoinPluginException("Missing input non-witness UTXOs.");
      }
      if (redeemScript == null) {
        throw DartBitcoinPluginException(
            "RedeemScript required for type P2SH.");
      }
      final p2shAddress = P2shAddress.fromScript(script: redeemScript);
      if (p2shAddress.toScriptPubKey() != scriptPubKey) {
        throw DartBitcoinPluginException(
            "Mismatched scriptPubKey: The provided scriptPubKey does not match the one derived from the RedeemScript.");
      }
      if (witnessScript != null) {
        final addr = P2wshAddress.fromScript(script: witnessScript);
        P2shAddress p2shAddress =
            P2shAddress.fromScript(script: addr.toScriptPubKey());
        if (p2shAddress.toScriptPubKey() != scriptPubKey) {
          throw DartBitcoinPluginException(
              "Mismatched scriptPubKey: The provided scriptPubKey does not match the one derived from the WitnessScript.");
        }
      }
    } else if (type.isP2tr) {
      throw DartBitcoinPluginException(
          "Use addP2trInput instead addWitnessV0Input for p2tr scriptPubKey.");
    } else if (!type.isSegwit) {
      throw DartBitcoinPluginException(
          "Invalid segwit scriptPubKey. type: ${type.name}");
    } else {
      if (redeemScript != null) {
        throw DartBitcoinPluginException(
            "RedeemScript cannot be used to spend P2WPKH.");
      }
    }
    if (type == ScriptPubKeyType.p2wsh) {
      if (witnessScript == null) {
        throw DartBitcoinPluginException(
            "WitnessScript is required for P2WSH scriptPubKey.");
      }
      final addr = P2wshAddress.fromScript(script: witnessScript);
      if (addr.toScriptPubKey() != scriptPubKey) {
        throw DartBitcoinPluginException(
            "Mismatched scriptPubKey: The provided scriptPubKey does not match the one derived from the WitnessScript.");
      }
    } else if (!type.isP2sh && witnessScript != null) {
      throw DartBitcoinPluginException(
          "WitnessScript cannot be used to spend P2WPKH.");
    }
    address ??=
        BitcoinScriptUtils.generateAddressFromScriptPubKey(scriptPubKey);
    return PsbtTransactionInput._(
        txInput: TxInput(txId: txId, txIndex: outIndex, sequance: sequence),
        sigHashType: sigHashType == null ? null : PsbtInputSigHash(sigHashType),
        nonWitnessUtxo: nonWitnessUtxo == null
            ? null
            : PsbtInputNonWitnessUtxo(nonWitnessUtxo),
        witnessUtxo:
            PsbtInputWitnessUtxo(amount: amount!, scriptPubKey: scriptPubKey),
        redeemScript:
            redeemScript == null ? null : PsbtInputRedeemScript(redeemScript),
        witnessScript: witnessScript == null
            ? null
            : PsbtInputWitnessScript(witnessScript),
        bip32derivationPath: bip32derivationPath,
        muSig2ParticipantPublicKeys: muSig2ParticipantPublicKeys,
        muSig2PublicNonce: muSig2PublicNonce,
        muSig2ParticipantPartialSignature: muSig2ParticipantPartialSignature,
        porCommitments: porCommitments,
        ripemd160: ripemd160,
        sha256: sha256,
        hash160: hash160,
        hash256: hash256,
        proprietaryUseType: proprietaryUseType,
        finalizedScriptSig: finalizedScriptSig,
        partialSigs: partialSigs,
        finalizedScriptWitness: finalizedScriptWitness,
        scriptPubKey: scriptPubKey,
        address: address);
  }

  /// **Factory method with validation**
  factory PsbtTransactionInput.witnessV1({
    required int outIndex,
    required String txId,
    BitcoinBaseAddress? address,
    int? sigHashType,
    List<int>? sequence,
    BtcTransaction? nonWitnessUtxo,
    BigInt? amount,
    Script? scriptPubKey,
    TapLeafMerkleProof? merkleProof,
    TaprootTree? treeScript,
    TaprootLeaf? leafScript,
    List<int>? xOnlyOrInternalPubKey,
    List<int>? merkleRoot,
    List<PsbtInputBip32DerivationPath>? bip32derivationPath,
    PsbtInputTaprootKeySpendSignature? taprootKeySpendSignature,
    List<PsbtInputTaprootScriptSpendSignature>? taprootScriptSpendSignature,
    List<PsbtInputTaprootKeyBip32DerivationPath>? taprootKeyBip32DerivationPath,
    List<PsbtInputMuSig2ParticipantPublicKeys>? muSig2ParticipantPublicKeys,
    List<PsbtInputMuSig2PublicNonce>? muSig2PublicNonce,
    List<PsbtInputMuSig2ParticipantPartialSignature>?
        muSig2ParticipantPartialSignature,
    PsbtInputPorCommitments? porCommitments,
    List<PsbtInputRipemd160>? ripemd160,
    List<PsbtInputSha256>? sha256,
    List<PsbtInputHash160>? hash160,
    List<PsbtInputHash256>? hash256,
    List<PsbtInputProprietaryUseType>? proprietaryUseType,
    PsbtInputSilentPaymentInputECDHShare? silentPaymentInputECDHShare,
    PsbtInputSilentPaymentInputDLEQProof? silentPaymentInputDLEQProof,
  }) {
    scriptPubKey ??= address?.toScriptPubKey();
    if (nonWitnessUtxo == null) {
      if (scriptPubKey == null || amount == null) {
        throw DartBitcoinPluginException(
            "either 'nonWitnessUtxo' or both scriptPubKey and amount required.");
      }
    }
    if (nonWitnessUtxo != null) {
      nonWitnessUtxo = PsbtUtils.cleanUpAdnValidateNonUtxoWitness(
          transaction: nonWitnessUtxo, outIndex: outIndex, txId: txId);
      final output = nonWitnessUtxo.outputs[outIndex];
      if (scriptPubKey != null) {
        if (scriptPubKey != output.scriptPubKey) {
          throw DartBitcoinPluginException(
              "Mismatch between scriptPubKey and nonWitnessUtxo output scriptPubKey.");
        }
      }
      scriptPubKey ??= output.scriptPubKey;
      amount ??= output.amount;
      if (amount != output.amount) {
        throw DartBitcoinPluginException(
            "Mismatch between amount and nonWitnessUtxo output amount.");
      }
    }

    final type = PsbtUtils.findScriptType(scriptPubKey!);
    if (!type.isP2tr) {
      throw DartBitcoinPluginException(
          "Invalid P2TR scriptPubKey detected: ${type.name}.");
    }
    xOnlyOrInternalPubKey ??= merkleProof?.controlBlock.xOnly;

    if (xOnlyOrInternalPubKey == null) {
      throw DartBitcoinPluginException(
          "xOnlyOrInternalPubKey is required for spending Taproot UTXOs but was not found.");
    }
    xOnlyOrInternalPubKey = TaprootUtils.toXOnly(xOnlyOrInternalPubKey);
    final isScriptPath = leafScript != null ||
        treeScript != null ||
        merkleProof != null ||
        merkleRoot != null;
    if (merkleRoot != null) {
      final addr = P2trAddress.fromInternalKey(
          internalKey: xOnlyOrInternalPubKey, merkleRoot: merkleRoot);
      if (addr.toScriptPubKey() != scriptPubKey) {
        throw DartBitcoinPluginException(
            "Mismatch between scriptPubKey and the one derived from x-only key and merkle root.");
      }
    }
    List<PsbtInputTaprootLeafScript>? leafScripts;
    if (isScriptPath) {
      if (merkleProof == null && treeScript == null) {
        throw DartBitcoinPluginException(
            "Script path spending requires merkleProof. Provide merkleProof or treeScript to generate all possible proofs.");
      }
      if (merkleRoot == null && treeScript == null) {
        throw DartBitcoinPluginException(
            "Script path spending requires merkleRoot. Provide merkleRoot or treeScript to generate one.");
      }
      merkleRoot ??= treeScript!.hash();
      if (merkleProof == null && leafScript != null) {
        merkleProof = TapLeafMerkleProof.generate(
            xOnlyOrInternalPubKey: xOnlyOrInternalPubKey,
            leafScript: leafScript,
            scriptTree: treeScript!);
      }
      if (merkleProof != null) {
        leafScripts = [
          PsbtInputTaprootLeafScript(
              controllBlock: merkleProof.controlBlock.toBytes(),
              script: merkleProof.script.script,
              leafVersion: merkleProof.script.leafVersion)
        ];
      } else {
        final leafs = TaprootUtils.generateAllPossibleProofs(
            xOnlyOrInternalPubKey: xOnlyOrInternalPubKey,
            treeScript: treeScript!);
        leafScripts = leafs
            .map((e) => PsbtInputTaprootLeafScript(
                controllBlock: e.controlBlock.toBytes(),
                script: e.script.script,
                leafVersion: e.script.leafVersion))
            .toList();
      }
    }
    address ??=
        BitcoinScriptUtils.generateAddressFromScriptPubKey(scriptPubKey);
    return PsbtTransactionInput._(
        scriptPubKey: scriptPubKey,
        txInput: TxInput(txId: txId, txIndex: outIndex, sequance: sequence),
        witnessUtxo:
            PsbtInputWitnessUtxo(amount: amount!, scriptPubKey: scriptPubKey),
        bip32derivationPath: bip32derivationPath,
        taprootInternalKey: PsbtInputTaprootInternalKey(xOnlyOrInternalPubKey),
        taprootLeafScript: leafScripts,
        taprootKeySpendSignature: taprootKeySpendSignature,
        taprootScriptSpendSignature: taprootScriptSpendSignature,
        taprootMerkleRoot:
            merkleRoot == null ? null : PsbtInputTaprootMerkleRoot(merkleRoot),
        taprootKeyBip32DerivationPath: taprootKeyBip32DerivationPath,
        muSig2ParticipantPublicKeys: muSig2ParticipantPublicKeys,
        muSig2PublicNonce: muSig2PublicNonce,
        muSig2ParticipantPartialSignature: muSig2ParticipantPartialSignature,
        porCommitments: porCommitments,
        ripemd160: ripemd160,
        sha256: sha256,
        sigHashType: sigHashType == null ? null : PsbtInputSigHash(sigHashType),
        hash160: hash160,
        hash256: hash256,
        proprietaryUseType: proprietaryUseType,
        silentPaymentInputDLEQProof: silentPaymentInputDLEQProof,
        silentPaymentInputECDHShare: silentPaymentInputECDHShare,
        address: address);
  }
  factory PsbtTransactionInput.generateFromInput(
      {required int index,
      required PsbtInput input,
      required TxInput txInput}) {
    final scriptPubKey = PsbtUtils.getInputScriptPubKey(
        psbtInput: input, input: txInput, index: index);
    final address =
        BitcoinScriptUtils.generateAddressFromScriptPubKey(scriptPubKey);
    return PsbtTransactionInput._(
        txInput: txInput,
        bip32derivationPath:
            input.getInputs(index, PsbtInputTypes.bip32DerivationPath),
        hash160: input.getInputs(index, PsbtInputTypes.hash160),
        hash256: input.getInputs(index, PsbtInputTypes.hash256),
        muSig2ParticipantPartialSignature: input.getInputs(
            index, PsbtInputTypes.muSig2ParticipantPartialSignature),
        muSig2ParticipantPublicKeys:
            input.getInputs(index, PsbtInputTypes.muSig2ParticipantPublicKeys),
        muSig2PublicNonce:
            input.getInputs(index, PsbtInputTypes.muSig2PublicNonce),
        partialSigs: input.getInputs(index, PsbtInputTypes.partialSignature),
        nonWitnessUtxo: input.getInput(index, PsbtInputTypes.nonWitnessUTXO),
        porCommitments: input.getInput(index, PsbtInputTypes.porCommitments),
        redeemScript: input.getInput(index, PsbtInputTypes.redeemScript),
        ripemd160: input.getInputs(index, PsbtInputTypes.ripemd160),
        sha256: input.getInputs(index, PsbtInputTypes.sha256),
        proprietaryUseType:
            input.getInputs(index, PsbtInputTypes.proprietaryUseType),
        sigHashType: input.getInput(index, PsbtInputTypes.sighashType),
        taprootInternalKey:
            input.getInput(index, PsbtInputTypes.taprootInternalKey),
        taprootKeyBip32DerivationPath:
            input.getInputs(index, PsbtInputTypes.bip32DerivationPath),
        taprootLeafScript:
            input.getInputs(index, PsbtInputTypes.taprootLeafScript),
        taprootScriptSpendSignature:
            input.getInputs(index, PsbtInputTypes.taprootScriptSpentSignature),
        witnessUtxo: input.getInput(index, PsbtInputTypes.witnessUTXO),
        witnessScript: input.getInput(index, PsbtInputTypes.witnessScript),
        taprootMerkleRoot:
            input.getInput(index, PsbtInputTypes.taprootMerkleRoot),
        taprootKeySpendSignature:
            input.getInput(index, PsbtInputTypes.taprootKeySpentSignature),
        finalizedScriptSig:
            input.getInput(index, PsbtInputTypes.finalizedScriptSig),
        finalizedScriptWitness:
            input.getInput(index, PsbtInputTypes.finalizedWitness),
        address: address,
        scriptPubKey: scriptPubKey);
  }

  List<PsbtInputData> toPsbtInputs(PsbtVersion version) {
    final List<PsbtInputData?> inputs = [
      if (version == PsbtVersion.v2) ...[
        PsbtInputPreviousTXID.fromHex(txInput.txId),
        PsbtInputSpentOutputIndex(txInput.txIndex),
        silentPaymentInputDLEQProof,
        silentPaymentInputECDHShare,
        PsbtUtils.getPsbtSequenceInputData(txInput),
      ],
      sigHashType,
      nonWitnessUtxo,
      witnessUtxo,
      redeemScript,
      witnessScript,
      ...bip32derivationPath ?? [],
      taprootInternalKey,
      ...taprootLeafScript ?? [],
      taprootKeySpendSignature,
      ...taprootScriptSpendSignature ?? [],
      taprootMerkleRoot,
      ...taprootKeyBip32DerivationPath ?? [],
      ...muSig2ParticipantPublicKeys ?? [],
      ...muSig2PublicNonce ?? [],
      ...muSig2ParticipantPartialSignature ?? [],
      porCommitments,
      ...ripemd160 ?? [],
      ...sha256 ?? [],
      ...hash160 ?? [],
      ...hash256 ?? [],
      ...proprietaryUseType ?? []
    ];
    return inputs.whereType<PsbtInputData>().toList();
  }
}

class PsbtUtxo {
  /// The UTXO (Unspent Transaction Output) information.
  final BitcoinUtxo utxo;

  /// The full transaction that created this UTXO, if available.
  /// This is required for non-segwit inputs when signing.
  final BtcTransaction? tx;

  /// The scriptPubKey of the UTXO being spent.
  /// This represents the locking script that restricts spending.
  final Script scriptPubKey;

  /// The redeem script for a P2SH (Pay-to-Script-Hash) UTXO.
  /// This is required if the UTXO is wrapped in a P2SH script.
  final Script? p2shRedeemScript;

  /// The witness script for a P2WSH (Pay-to-Witness-Script-Hash) UTXO.
  /// This is required if the UTXO is a SegWit v0 P2WSH output.
  final Script? p2wshWitnessScript;

  /// The merkle proof for a Taproot UTXO, proving the inclusion of the
  /// spending script in the Taproot commitment.
  final TapLeafMerkleProof? merkleProof;

  /// The Taproot script tree containing the various spending conditions.
  /// This is used in Taproot scripts where multiple spending conditions exist.
  final TaprootTree? treeScript;

  /// The specific Taproot script leaf being used for spending.
  /// This is required when spending via a TapLeaf path.
  final TaprootLeaf? leafScript;

  /// The internal or x-only public key for Taproot UTXOs.
  /// This is the key used in key-path spends or as part of script-path spends.
  final List<int>? xOnlyOrInternalPubKey;

  /// The Merkle root of the Taproot script tree, proving the structure of the tree.
  /// Required for Taproot script-path spending.
  final List<int>? merkleRoot;

  /// The list of individual TapLeaf merkle proofs used in script-path spending.
  /// Each proof shows how a leaf is part of the Taproot commitment.
  final List<TapLeafMerkleProof>? leafScripts;
  final List<PsbtInputMuSig2ParticipantPublicKeys>? muSig2ParticipantPublicKeys;

  final List<PsbtInputRipemd160>? ripemd160;
  final List<PsbtInputSha256>? sha256;
  final List<PsbtInputHash160>? hash160;
  final List<PsbtInputHash256>? hash256;

  const PsbtUtxo(
      {required this.utxo,
      this.tx,
      required this.scriptPubKey,
      this.xOnlyOrInternalPubKey,
      this.p2shRedeemScript,
      this.p2wshWitnessScript,
      this.leafScripts,
      this.merkleRoot,
      this.leafScript,
      this.merkleProof,
      this.treeScript,
      this.muSig2ParticipantPublicKeys,
      this.ripemd160,
      this.hash160,
      this.hash256,
      this.sha256});
  factory PsbtUtxo.fromJson(Map<String, dynamic> json) {
    return PsbtUtxo(
        utxo: BitcoinUtxo.fromJson(json["utxo"]),
        tx: json["tx"] == null
            ? null
            : BtcTransaction.deserialize(BytesUtils.fromHexString(json["tx"])),
        scriptPubKey: Script.fromJson(json["scriptpubkey"]),
        p2shRedeemScript: json["p2sh_redeem_script"] == null
            ? null
            : Script.fromJson(json["p2sh_redeem_script"]),
        p2wshWitnessScript: json["p2wsh_witness_script"] == null
            ? null
            : Script.fromJson(json["p2wsh_witness_script"]),
        merkleProof: json["merkle_proof"] == null
            ? null
            : TapLeafMerkleProof.fromJson(json["merkle_proof"]),
        treeScript: json["tree_script"] == null
            ? null
            : TaprootTree.fromJson(json["tree_script"]),
        leafScript: json["leaf_script"] == null
            ? null
            : TaprootLeaf.fromJson(json["leaf_script"]),
        xOnlyOrInternalPubKey: BytesUtils.tryFromHexString(json["xonly"]),
        merkleRoot: BytesUtils.tryFromHexString(json["merkle_root"]),
        leafScripts: (json["leaf_scripts"] as List?)
            ?.map((e) => TapLeafMerkleProof.fromJson(e))
            .toList());
  }

  Map<String, dynamic> toJson() {
    return {
      "utxo": utxo.toJson(),
      "tx": tx?.toHex(),
      "scriptpubkey": scriptPubKey.toJson(),
      "p2sh_redeem_script": p2shRedeemScript?.toJson(),
      "p2wsh_witness_script": p2wshWitnessScript?.toJson(),
      "merkle_proof": merkleProof?.toJson(),
      "tree_script": treeScript?.toJson(),
      "leaf_script": leafScript?.toJson(),
      "xonly": BytesUtils.tryToHexString(xOnlyOrInternalPubKey),
      "merkle_root": BytesUtils.tryToHexString(merkleRoot),
      "leaf_scripts": leafScripts?.map((e) => e.toJson()).toList(),
    };
  }
}

class PsbtFinalizeParams {
  /// All related PSBT input data for this input.
  final PsbtTransactionInput inputData;

  /// The index of the input in the transaction.
  final int index;

  /// The `scriptPubKey` of the input.
  Script get scriptPubKey => inputData.scriptPubKey;

  /// The Bitcoin address derived from `scriptPubKey`.
  BitcoinBaseAddress get address => inputData.address;

  const PsbtFinalizeParams({required this.index, required this.inputData});
}

class PsbtFinalizeResponse {
  /// If you are spending a custom script, you must provide an
  /// to handle the finalization manually/
  final PsbtFinalizeInput? finalizeInput;

  /// The TapLeaf hash used when signing a Taproot script.
  /// - Required if the input is a Tapscript with multiple leaf scripts.
  /// - You must specify the correct leaf script to sign.
  final List<int>? tapleafHash;
  PsbtFinalizeResponse({
    this.finalizeInput,
    List<int>? tapleafHash,
  }) : tapleafHash = tapleafHash?.asImmutableBytes;
}

/// Represents the finalized script signature and witness data for a PSBT input.
///
/// This class is used when finalizing a PSBT input, allowing the user to provide
/// either a legacy/scriptSig-based signature or a SegWit/Taproot witness.
class PsbtFinalizeInput {
  final Script? scriptSig;
  final TxWitnessInput? witness;
  const PsbtFinalizeInput({this.scriptSig, this.witness});

  List<PsbtInputData> toPsbtInput() {
    return [
      if (scriptSig != null) PsbtInputFinalizedScriptSig(scriptSig!),
      if (witness != null) PsbtInputFinalizedScriptWitness(witness!),
    ];
  }
}

/// Represents a BIP32 or Taproot key derivation request in a PSBT transaction.
/// This class combines `PsbtInputBip32Derivation` and `PsbtInputTaprootBip32Derivation`
/// into a unified structure.
class BipOrTaprootKeyDerivationRequest {
  /// A compressed/uncompressed ECDSA public key (for BIP32 derivation),
  /// OR an x-only Taproot public key (for Taproot derivation).
  final List<int> pubKeyOrXonly;

  /// A list of BIP32 key indexes representing the derivation path.
  final List<Bip32KeyIndex> indexes;

  /// The BIP32 parent fingerprint of the key.
  final List<int> fingerprint;

  /// A list of Taproot leaf hashes (only required for Taproot derivation).
  final List<List<int>>? leavesHashes;
  String get path {
    return Bip32Path(elems: indexes).toString();
  }

  BipOrTaprootKeyDerivationRequest._(
      {required List<int> pubKeyOrXonly,
      required List<Bip32KeyIndex> indexes,
      required List<int> fingerprint,
      List<List<int>>? leavesHashes})
      : pubKeyOrXonly = pubKeyOrXonly.asImmutableBytes,
        indexes = indexes.immutable,
        fingerprint = fingerprint.asImmutableBytes,
        leavesHashes =
            leavesHashes?.map((e) => e.asImmutableBytes).toImutableList;
  factory BipOrTaprootKeyDerivationRequest(
      {required List<int> pubKeyOrXonly,
      required List<Bip32KeyIndex> indexes,
      required List<int> fingerprint,
      List<List<int>>? leavesHashes}) {
    if (leavesHashes != null) {
      if (pubKeyOrXonly.length != EcdsaKeysConst.pointCoordByteLen) {
        throw DartBitcoinPluginException("Invalid Public key XOnly key length.",
            details: {
              "excpected": EcdsaKeysConst.pointCoordByteLen,
              "length": pubKeyOrXonly.length
            });
      }
    } else if (pubKeyOrXonly.length != EcdsaKeysConst.pubKeyCompressedByteLen &&
        pubKeyOrXonly.length != EcdsaKeysConst.pubKeyUncompressedByteLen) {
      throw DartBitcoinPluginException("Invalid Public key length.", details: {
        "excpected": EcdsaKeysConst.pubKeyCompressedByteLen,
        "length": pubKeyOrXonly.length
      });
    }
    if (fingerprint.length != Bip32KeyDataConst.fingerprintByteLen) {
      throw DartBitcoinPluginException("Invalid Fingerprint key length.",
          details: {
            "excpected": Bip32KeyDataConst.fingerprintByteLen,
            "length": pubKeyOrXonly.length
          });
    }
    return BipOrTaprootKeyDerivationRequest._(
        pubKeyOrXonly: pubKeyOrXonly,
        indexes: indexes,
        fingerprint: fingerprint,
        leavesHashes: leavesHashes);
  }
  Bip32Slip10Secp256k1 derive(Bip32Slip10Secp256k1 masterKey) {
    if (masterKey.curveType != EllipticCurveTypes.secp256k1) {
      throw DartBitcoinPluginException("Invalid master key curve type.");
    }
    Bip32Slip10Secp256k1 key = masterKey;
    for (final i in indexes) {
      key = key.childKey(i);
    }
    if (pubKeyOrXonly.length == EcdsaKeysConst.pointCoordByteLen) {
      if (!BytesUtils.bytesEqual(pubKeyOrXonly,
          key.publicKey.key.point.cast<ProjectiveECCPoint>().toXonly())) {
        throw DartBitcoinPluginException(
            "Mismatch between derived key public key (x-only) and expected x-only.");
      }
    } else if (IPublicKey.fromBytes(
            pubKeyOrXonly, EllipticCurveTypes.secp256k1) !=
        key.publicKey.key) {
      throw DartBitcoinPluginException(
          "Mismatch between derived key public key and expected public key.");
    }
    return key;
  }
}

class PsbtSignerResponse {
  /// A list of signers required to sign the input.
  /// - If empty, the signing operation is rejected.
  final List<PsbtBtcSigner> signers;

  /// The SIGHASH flag used for signing.
  /// - If `null`, the default is applied:
  ///   - **Segwit/Legacy:** Uses `SIGHASH_ALL`
  ///   - **Taproot:** Uses `SIGHASH_DEFAULT`
  final int? sighash;

  /// The TapLeaf hash used when signing a Taproot script.
  /// - Required if the input is a Tapscript with multiple leaf scripts.
  /// - You must specify the correct leaf script to sign.
  final List<int>? tapleafHash;

  PsbtSignerResponse({
    required List<PsbtBtcSigner> signers,
    List<int>? tapleafHash,
    this.sighash,
  })  : signers = signers.immutable,
        tapleafHash = tapleafHash?.asImmutableBytes;
}

class PsbtSignerParams {
  /// The `scriptPubKey` of the input.
  final Script scriptPubKey;

  /// All related PSBT input data for this input.
  final PsbtTransactionInput inputData;

  /// The index of the input in the transaction.
  final int index;

  /// The Bitcoin address derived from `scriptPubKey`.
  final BitcoinBaseAddress address;

  PsbtSignerParams({
    required this.scriptPubKey,
    required this.inputData,
    required this.index,
    required this.address,
  });
}

class PsbtTransactionOutput {
  List<PsbtOutputData> toPsbtOutput(PsbtVersion version) {
    return [
      if (version.isV2) ...[
        PsbtOutputScript(scriptPubKey),
        PsbtOutputAmount(amount),
        silentPaymentData,
        silentPaymentLabel
      ],
      if (redeemScript != null) PsbtOutputRedeemScript(redeemScript!),
      if (witnessScript != null) PsbtOutputWitnessScript(witnessScript!),
      ...bip32derivationPath ?? [],
      if (taprootInternalKey != null)
        PsbtOutputTaprootInternalKey(taprootInternalKey!),
      ...taprootKeyBip32DerivationPath ?? [],
      ...muSig2ParticipantPublicKeys ?? [],
      ...proprietaryUseType ?? []
      // if(taprootTree!= null) PsbtOutputTaprootTree(taprootTrees)
    ].whereType<PsbtOutputData>().toList();
  }

  TxOutput toTxOutput() {
    return TxOutput(amount: amount, scriptPubKey: scriptPubKey);
  }

  final Script scriptPubKey;
  final BigInt amount;
  final BitcoinBaseAddress? address;
  final Script? redeemScript;
  final Script? witnessScript;
  final List<PsbtOutputBip32DerivationPath>? bip32derivationPath;
  final List<int>? taprootInternalKey;
  final List<PsbtTapTree>? taprootTree;
  final List<PsbtOutputTaprootKeyBip32DerivationPath>?
      taprootKeyBip32DerivationPath;
  final List<PsbtOutputMuSig2ParticipantPublicKeys>?
      muSig2ParticipantPublicKeys;
  final PsbtOutputBIP353DNSSECProof? proof;
  final List<PsbtOutputProprietaryUseType>? proprietaryUseType;
  final PsbtOutputSilentPaymentData? silentPaymentData;
  final PsbtOutputSilentPaymentLabel? silentPaymentLabel;

  factory PsbtTransactionOutput(
      {required BigInt amount,
      Script? scriptPubKey,
      BitcoinBaseAddress? address}) {
    scriptPubKey ??= address?.toScriptPubKey();
    if (scriptPubKey == null) {
      throw DartBitcoinPluginException(
          "Either scriptPubKey or address must be provided.");
    }
    address ??=
        BitcoinScriptUtils.tryGenerateAddressFromScriptPubKey(scriptPubKey);
    return PsbtTransactionOutput._(
        scriptPubKey: scriptPubKey, amount: amount, address: address);
  }

  PsbtTransactionOutput._(
      {required this.scriptPubKey,
      required this.amount,
      required this.address,
      this.redeemScript,
      this.witnessScript,
      this.bip32derivationPath,
      this.taprootInternalKey,
      this.taprootTree,
      this.taprootKeyBip32DerivationPath,
      this.muSig2ParticipantPublicKeys,
      this.proof,
      this.proprietaryUseType,
      this.silentPaymentData,
      this.silentPaymentLabel});

  // Factory constructor for Legacy outputs (P2PKH, P2SH)
  factory PsbtTransactionOutput.legacy({
    required BigInt amount,
    Script? scriptPubKey,
    BitcoinBaseAddress? address,
    Script? redeemScript,
    List<PsbtOutputBip32DerivationPath>? bip32derivationPath,
    PsbtOutputBIP353DNSSECProof? proof,
    List<PsbtOutputProprietaryUseType>? proprietaryUseType,
  }) {
    scriptPubKey ??= address?.toScriptPubKey();
    if (scriptPubKey == null) {
      throw DartBitcoinPluginException(
          "Either scriptPubKey or address must be provided.");
    }
    address ??=
        BitcoinScriptUtils.tryGenerateAddressFromScriptPubKey(scriptPubKey);
    if (redeemScript != null) {
      final p2shAddress = P2shAddress.fromScript(script: redeemScript);
      if (p2shAddress.toScriptPubKey() != scriptPubKey) {
        throw DartBitcoinPluginException(
            "scriptPubKey does not match redeemScript-derived script.");
      }
    }
    if (amount.isNegative) {
      throw DartBitcoinPluginException("Amount cannot be negative.");
    }
    if (address?.type.isSegwit ?? false) {
      throw DartBitcoinPluginException(
          "Invalid legacy address. Use the WitnessV0 or WitnessV1 factory constructor instead.");
    }

    return PsbtTransactionOutput._(
        scriptPubKey: scriptPubKey,
        amount: amount,
        redeemScript: redeemScript,
        bip32derivationPath: bip32derivationPath,
        proprietaryUseType: proprietaryUseType,
        address: address,
        proof: proof);
  }

  // Factory constructor for SegWit v0 outputs (P2WPKH, P2WSH, P2SH-P2WPKH, P2SH-P2WSH)
  factory PsbtTransactionOutput.witnessV0({
    required BigInt amount,
    BitcoinBaseAddress? address,
    Script? scriptPubKey,
    Script? redeemScript,
    Script? witnessScript,
    List<PsbtOutputBip32DerivationPath>? bip32derivationPath,
    List<PsbtOutputProprietaryUseType>? proprietaryUseType,
    PsbtOutputBIP353DNSSECProof? proof,
  }) {
    scriptPubKey ??= address?.toScriptPubKey();
    if (scriptPubKey == null) {
      throw DartBitcoinPluginException(
          "Either scriptPubKey or address must be provided.");
    }
    address ??=
        BitcoinScriptUtils.tryGenerateAddressFromScriptPubKey(scriptPubKey);
    if (amount.isNegative) {
      throw DartBitcoinPluginException("Amount cannot be negative.");
    }
    if (witnessScript != null) {
      final addr = P2wshAddress.fromScript(script: witnessScript);
      if (redeemScript != null) {
        if (addr.toScriptPubKey() != redeemScript) {
          throw DartBitcoinPluginException(
              "redeemScript does not match witnessScript-derived script.");
        }
      } else {
        if (addr.toScriptPubKey() != scriptPubKey) {
          throw DartBitcoinPluginException(
              "scriptPubKey does not match witnessScript-derived script.");
        }
      }
    }

    if (redeemScript != null) {
      final p2shAddress = P2shAddress.fromScript(script: redeemScript);
      if (p2shAddress.toScriptPubKey() != scriptPubKey) {
        throw DartBitcoinPluginException(
            "scriptPubKey does not match redeemScript-derived address.");
      }
    }
    if (address != null) {
      if (address.type.isP2tr) {
        throw DartBitcoinPluginException(
            "Invalid Witness V0 address. Use the witnessV1 factory constructor instead.");
      } else if (!address.type.isSegwit && !address.type.isP2sh) {
        throw DartBitcoinPluginException(
            "Invalid Witness V0 address. Use the legacy factory constructor instead.");
      }
    }

    return PsbtTransactionOutput._(
        scriptPubKey: scriptPubKey,
        amount: amount,
        redeemScript: redeemScript,
        witnessScript: witnessScript,
        bip32derivationPath: bip32derivationPath,
        proprietaryUseType: proprietaryUseType,
        address: address,
        proof: proof);
  }

  // Factory constructor for SegWit v1 (Taproot) outputs
  factory PsbtTransactionOutput.witnessV1({
    Script? scriptPubKey,
    BitcoinBaseAddress? address,
    required BigInt amount,
    List<int>? taprootInternalKey,
    List<PsbtTapTree>? taprootTree,
    List<PsbtOutputTaprootKeyBip32DerivationPath>?
        taprootKeyBip32DerivationPath,
    List<PsbtOutputMuSig2ParticipantPublicKeys>? muSig2ParticipantPublicKeys,
    PsbtOutputBIP353DNSSECProof? proof,
    List<PsbtOutputProprietaryUseType>? proprietaryUseType,
    PsbtOutputSilentPaymentData? silentPaymentData,
    PsbtOutputSilentPaymentLabel? silentPaymentLabel,
  }) {
    scriptPubKey ??= address?.toScriptPubKey();
    if (scriptPubKey == null) {
      throw DartBitcoinPluginException(
          "Either scriptPubKey or address must be provided.");
    }
    address ??=
        BitcoinScriptUtils.tryGenerateAddressFromScriptPubKey(scriptPubKey);
    if (amount.isNegative) {
      throw DartBitcoinPluginException("Amount cannot be negative.");
    }
    return PsbtTransactionOutput._(
        scriptPubKey: scriptPubKey,
        address: address,
        amount: amount,
        taprootInternalKey: taprootInternalKey,
        taprootTree: taprootTree,
        taprootKeyBip32DerivationPath: taprootKeyBip32DerivationPath,
        muSig2ParticipantPublicKeys: muSig2ParticipantPublicKeys,
        proof: proof,
        proprietaryUseType: proprietaryUseType,
        silentPaymentData: silentPaymentData,
        silentPaymentLabel: silentPaymentLabel);
  }

  factory PsbtTransactionOutput.generateFromOutput(
      {required PsbtOutput psbtOutput,
      required TxOutput output,
      required int index}) {
    return PsbtTransactionOutput._(
        scriptPubKey: output.scriptPubKey,
        amount: output.amount,
        address: BitcoinScriptUtils.tryGenerateAddressFromScriptPubKey(
            output.scriptPubKey),
        bip32derivationPath:
            psbtOutput.getOutputs(index, PsbtOutputTypes.bip32DerivationPath),
        muSig2ParticipantPublicKeys: psbtOutput.getOutputs(
            index, PsbtOutputTypes.muSig2ParticipantPublicKeys),
        taprootKeyBip32DerivationPath: psbtOutput.getOutputs(
            index, PsbtOutputTypes.taprootBip32Derivation),
        proprietaryUseType:
            psbtOutput.getOutputs(index, PsbtOutputTypes.proprietaryUseType),
        proof: psbtOutput.getOutput(index, PsbtOutputTypes.bip353DNSSECProof),
        redeemScript: psbtOutput
            .getOutput<PsbtOutputRedeemScript>(
                index, PsbtOutputTypes.redeemScript)
            ?.redeemScript,
        witnessScript: psbtOutput
            .getOutput<PsbtOutputWitnessScript>(
                index, PsbtOutputTypes.witnessScript)
            ?.witnessScript,
        silentPaymentData:
            psbtOutput.getOutput(index, PsbtOutputTypes.silentPaymentData),
        silentPaymentLabel:
            psbtOutput.getOutput(index, PsbtOutputTypes.silentPaymentLabel),
        taprootInternalKey: psbtOutput
            .getOutput<PsbtOutputTaprootInternalKey>(
                index, PsbtOutputTypes.taprootInternalKey)
            ?.xOnlyPubKey,
        taprootTree: psbtOutput
            .getOutput<PsbtOutputTaprootTree>(
                index, PsbtOutputTypes.taprootTree)
            ?.taprootTrees);
  }
}

enum PsbtTxType {
  legacy,
  witnessV0,
  witnessV1;

  bool get isLegacy => this == legacy;
  bool get isSegwit => this != legacy;
  bool get isP2tr => this == witnessV1;
}

class PsbtInputSighashInfo {
  final int inputIndex;
  final int sighashType;
  PsbtInputSighashInfo({required this.inputIndex, required this.sighashType});
  late final bool isSighashAll =
      PsbtUtils.isSighash(sighashType, BitcoinOpCodeConst.sighashAll);
  late final bool isSighashSingle =
      PsbtUtils.isSighash(sighashType, BitcoinOpCodeConst.sighashSingle);
  late final bool isSighashNone =
      PsbtUtils.isSighash(sighashType, BitcoinOpCodeConst.sighashNone);
  late final bool isAnyOneCanPay = PsbtUtils.isAnyoneCanPay(sighashType);

  @override
  String toString() {
    if (isSighashAll) {
      return "SIGHASH_ALL";
    }
    if (isSighashSingle) {
      return "SIGHASH_SINGLE";
    }
    if (isSighashNone) {
      return "SIGHASH_NONE";
    }
    return "0x${sighashType.toRadixString(16)}";
  }

  bool canModifyInput(int inputIndex) {
    if (isAnyOneCanPay) {
      return inputIndex != this.inputIndex;
    }
    return false;
  }

  bool canModifyOutput(
      {required int outputIndex,
      required bool isUpdate,
      required List<PsbtInputSighashInfo> allSigashes}) {
    if (isSighashAll) return false;
    if (isSighashNone) return true;
    if (isSighashSingle) {
      if (isUpdate) return outputIndex != inputIndex;
      final sighashes = allSigashes.where((e) => e.inputIndex > inputIndex);
      return sighashes.every((e) => e.isSighashNone);
    }
    return true;
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! PsbtInputSighashInfo) return false;
    return inputIndex == other.inputIndex && sighashType == other.sighashType;
  }

  @override
  int get hashCode =>
      HashCodeGenerator.generateHashCode([inputIndex, sighashType]);
}
