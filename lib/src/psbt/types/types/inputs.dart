import 'dart:math';
import 'dart:typed_data';
import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/bitcoin/script/transaction.dart';
import 'package:bitcoin_base/src/bitcoin/script/witness.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/psbt/psbt_builder/types/types.dart';
import 'package:bitcoin_base/src/psbt/types/types/psbt.dart';
import 'package:bitcoin_base/src/psbt/utils/utils.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

enum PsbtInputTypes {
  nonWitnessUTXO(0x00, "PSBT_IN_NON_WITNESS_UTXO"),
  witnessUTXO(0x01, "PSBT_IN_WITNESS_UTXO"),
  partialSignature(0x02, "PSBT_IN_PARTIAL_SIG"),
  sighashType(0x03, "PSBT_IN_SIGHASH_TYPE"),
  redeemScript(0x04, "PSBT_IN_REDEEM_SCRIPT"),
  witnessScript(0x05, "PSBT_IN_WITNESS_SCRIPT"),
  bip32DerivationPath(0x06, "PSBT_IN_BIP32_DERIVATION"),
  finalizedScriptSig(0x07, "PSBT_IN_FINAL_SCRIPTSIG"),
  finalizedWitness(0x08, "PSBT_IN_FINAL_SCRIPTWITNESS"),
  porCommitments(0x09, "PSBT_IN_POR_COMMITMENT"),
  ripemd160(0x0a, "PSBT_IN_RIPEMD160"),
  sha256(0x0b, "PSBT_IN_SHA256"),
  hash160(0x0c, "PSBT_IN_HASH160"),
  hash256(0x0d, "PSBT_IN_HASH256"),
  previousTxId(0x0e, "PSBT_IN_PREVIOUS_TXID",
      allowedVersion: PsbtVersion.v2, required: true),
  spentOutputIndex(0x0f, "PSBT_IN_OUTPUT_INDEX",
      allowedVersion: PsbtVersion.v2, required: true),
  sequenceNumber(0x10, "PSBT_IN_SEQUENCE", allowedVersion: PsbtVersion.v2),
  requiredTimeBasedLockTime(0x11, "PSBT_IN_REQUIRED_TIME_LOCKTIME",
      allowedVersion: PsbtVersion.v2),
  requiredHeightBasedLockTime(0x12, "PSBT_IN_REQUIRED_HEIGHT_LOCKTIME",
      allowedVersion: PsbtVersion.v2),
  taprootKeySpentSignature(0x13, "PSBT_IN_TAP_KEY_SIG"),
  taprootScriptSpentSignature(0x14, "PSBT_IN_TAP_SCRIPT_SIG"),
  taprootInternalKey(0x17, "PSBT_IN_TAP_INTERNAL_KEY"),
  taprootMerkleRoot(0x18, "PSBT_IN_TAP_MERKLE_ROOT"),
  taprootLeafScript(0x15, "PSBT_IN_TAP_LEAF_SCRIPT"),
  taprootBip32Derivation(0x16, "PSBT_IN_TAP_BIP32_DERIVATION"),
  muSig2ParticipantPublicKeys(0x1a, "PSBT_IN_MUSIG2_PARTICIPANT_PUBKEYS"),
  muSig2PublicNonce(0x1b, "PSBT_IN_MUSIG2_PUB_NONCE"),
  muSig2ParticipantPartialSignature(0x1c, "PSBT_IN_MUSIG2_PARTIAL_SIG"),
  silentPaymentInputECDHShare(0x1d, "PSBT_IN_SP_ECDH_SHARE",
      allowedVersion: PsbtVersion.v2),
  silentPaymentInputDLEQProof(0x1e, "PSBT_IN_SP_DLEQ",
      allowedVersion: PsbtVersion.v2),
  proprietaryUseType(0xFC, "PSBT_IN_PROPRIETARY"),
  unknown(null, "UNKNOWN");

  const PsbtInputTypes(this.flag, this.psbtName,
      {this.allowedVersion, this.required = false});
  final String psbtName;
  final bool required;
  final PsbtVersion? allowedVersion;
  final int? flag;
  static PsbtInputTypes find(int flag) {
    final type = values.firstWhereNullable((e) => e.flag == flag);
    if (type != null) return type;
    return unknown;
  }
}

/// Represents the input section of a PSBT (Partially Signed Bitcoin Transaction).
class PsbtInput {
  /// The PSBT version associated with this input section.
  final PsbtVersion version;

  /// The list of input PSBT entries.
  List<List<PsbtInputData>> _entries;
  List<List<PsbtInputData>> get entries => _entries;
  PsbtInput._(
      {List<List<PsbtInputData>> entries = const [], required this.version})
      : _entries = entries.map((e) => e.immutable).toImutableList;

  /// Constructs a [PsbtInput] instance with a given version and input entries.
  ///
  /// Throws a [DartBitcoinPluginException] if any of the following conditions are met:
  /// - Duplicate entries are found.
  /// - A input entry is not allowed for the specified PSBT version.
  /// - A required input entry is missing for the PSBT version
  factory PsbtInput(
      {List<List<PsbtInputData>> entries = const [],
      required PsbtVersion version}) {
    final requiredFilds = PsbtInputTypes.values.where((e) =>
        e.required &&
        (e.allowedVersion == null || e.allowedVersion == version));
    for (final e in entries) {
      final keys = e.map((e) => e.keyPair.key).toList();
      if (keys.toSet().length != keys.length) {
        throw DartBitcoinPluginException(
            "Invalid PSBT Input: Duplicate entry detected.");
      }
      for (final i in e) {
        if (i.type.allowedVersion == null) continue;
        if (version != i.type.allowedVersion) {
          throw DartBitcoinPluginException(
              "Invalid PSBT Input: ${i.type.psbtName} is not allowed in PSBT version ${version.name}.");
        }
      }

      for (final i in requiredFilds) {
        e.firstWhere((e) => e.type == i,
            orElse: () => throw DartBitcoinPluginException(
                "Invalid PSBT Input: Missing required field ${i.psbtName} for PSBT version ${version.name}."));
      }
    }
    return PsbtInput._(version: version, entries: entries);
  }

  /// Creates a [PsbtInput] instance from a list of key pairs.
  factory PsbtInput.fromKeyPairs(
      {List<List<PsbtKeyPair>> keypairs = const [],
      required PsbtVersion version}) {
    return PsbtInput(
        entries: keypairs
            .map((e) => e.map(PsbtInputData.deserialize).toList())
            .toList(),
        version: version);
  }

  int get length => _entries.length;

  /// Validates if the provided entries is not duplicate and allowed by the PSBT version.
  void _itemsAllowed(List<PsbtInputData> items) {
    final keys = items.map((e) => e.keyPair.key).toSet();
    if (keys.length != items.length) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Input: Duplicate entry detected.");
    }
    for (final i in items) {
      if (i.type.allowedVersion == null) continue;
      if (version != i.type.allowedVersion) {
        throw DartBitcoinPluginException(
            "Invalid PSBT Input: ${i.type.psbtName} is not allowed in PSBT version ${version.name}.");
      }
    }
  }

  /// Adds new input to the PSBT.
  void addInputs(List<PsbtInputData> inputs) {
    _itemsAllowed(inputs);
    _entries = [..._entries, inputs].toImutableList;
  }

  List<PsbtInputData> _validateIndex(int inputIndex) {
    if (inputIndex >= _entries.length) {
      throw DartBitcoinPluginException(
          "Invalid input index: $inputIndex. The index exceeds the number of available entries.");
    }
    return _entries[inputIndex].clone();
  }

  /// Retrieves a single entry of a specified type.
  T? getInput<T extends PsbtInputData>(int index, PsbtInputTypes type) {
    final input = _validateIndex(index);
    final data = input.where((e) => e.type == type);
    if (data.isEmpty) return null;
    if (data.length != 1) {
      throw DartBitcoinPluginException(
          "Multiple inputs with type '${type.name}' found. Use 'getInputs' to retrieve data for multiple globals");
    }
    return data.first.cast();
  }

  bool hasInput(int index, PsbtInputTypes type) {
    final input = _validateIndex(index);
    return input.any((e) => e.type == type);
  }

  /// Retrieves all entries of a specified type.
  List<T>? getInputs<T extends PsbtInputData>(int index, PsbtInputTypes type) {
    final input = _validateIndex(index);
    final data = input.where((e) => e.type == type);

    if (data.isEmpty) return null;
    return data.toList().cast<T>();
  }

  /// Replaces the input at the specified [index]
  void replaceInput(int index, List<PsbtInputData> inputs) {
    _itemsAllowed(inputs);
    final entries = _entries.clone();
    _validateIndex(index);
    entries[index] = inputs.toImutableList;
    _entries = entries.toImutableList;
  }

  /// Updates the entries with new data.
  void updateInputs(int index, List<PsbtInputData> inputs) {
    _itemsAllowed(inputs);
    final entries = _entries.clone();
    final entry = _validateIndex(index);
    for (final i in inputs) {
      entry.removeWhere((e) => e.keyPair.key == i.keyPair.key);
      entry.add(i);
    }

    entries[index] = entry.toImutableList;
    _entries = entries.toImutableList;
  }

  /// remove the input data from given types at the specified [index]
  void removeInputKeys(int index, List<PsbtInputTypes> types) {
    final entry = _validateIndex(index);
    final entries = _entries.clone();
    entry.removeWhere((e) => types.contains(e.type));
    entries[index] = entry.toImutableList;
    _entries = entries.toImutableList;
  }

  /// Adds new input to the PSBT.
  void addInput(PsbtInputData input) {
    _itemsAllowed([input]);
    _entries = [
      ..._entries,
      [input].toImutableList
    ].toImutableList;
  }

  /// remove the input at the specified [index]
  void removeInput(int index) {
    _validateIndex(index);
    final entries = _entries.clone();
    entries.removeAt(index);
    _entries = entries.immutable;
  }

  /// Converts the entries to json.
  Map<String, dynamic> toJson() {
    return {
      "entries": entries.map((e) => e.map((e) => e.toJson()).toList()).toList()
    };
  }

  /// Converts the entries to a list of key pairs.
  List<List<PsbtKeyPair>> toKeyPairs() {
    return _entries.map((e) => e.map((e) => e.keyPair).toList()).toList();
  }

  /// Creates a deep copy of the [PsbtInput] instance.
  PsbtInput clone() {
    return PsbtInput(
        entries: entries.map((e) => e.clone()).toList(), version: version);
  }

  @override
  String toString() {
    return "inputs: ${_entries.join(", ")}";
  }
}

abstract class PsbtInputData {
  final PsbtInputTypes type;
  final PsbtKeyPair keyPair;
  int get flag => type.flag!;
  PsbtInputData({required this.type, required this.keyPair});
  factory PsbtInputData.deserialize(PsbtKeyPair keypair) {
    final type = PsbtInputTypes.find(keypair.key.type);
    return switch (type) {
      PsbtInputTypes.nonWitnessUTXO =>
        PsbtInputNonWitnessUtxo.deserialize(keypair),
      PsbtInputTypes.witnessUTXO => PsbtInputWitnessUtxo.deserialize(keypair),
      PsbtInputTypes.partialSignature =>
        PsbtInputPartialSig.deserialize(keypair),
      PsbtInputTypes.sighashType => PsbtInputSigHash.deserialize(keypair),
      PsbtInputTypes.redeemScript => PsbtInputRedeemScript.deserialize(keypair),
      PsbtInputTypes.witnessScript =>
        PsbtInputWitnessScript.deserialize(keypair),
      PsbtInputTypes.bip32DerivationPath =>
        PsbtInputBip32DerivationPath.deserialize(keypair),
      PsbtInputTypes.finalizedScriptSig =>
        PsbtInputFinalizedScriptSig.deserialize(keypair),
      PsbtInputTypes.finalizedWitness =>
        PsbtInputFinalizedScriptWitness.deserialize(keypair),
      PsbtInputTypes.porCommitments =>
        PsbtInputPorCommitments.deserialize(keypair),
      PsbtInputTypes.ripemd160 => PsbtInputRipemd160.deserialize(keypair),
      PsbtInputTypes.sha256 => PsbtInputSha256.deserialize(keypair),
      PsbtInputTypes.hash160 => PsbtInputHash160.deserialize(keypair),
      PsbtInputTypes.hash256 => PsbtInputHash256.deserialize(keypair),
      PsbtInputTypes.previousTxId => PsbtInputPreviousTXID.deserialize(keypair),
      PsbtInputTypes.spentOutputIndex =>
        PsbtInputSpentOutputIndex.deserialize(keypair),
      PsbtInputTypes.sequenceNumber =>
        PsbtInputSequenceNumber.deserialize(keypair),
      PsbtInputTypes.requiredTimeBasedLockTime =>
        PsbtInputRequiredTimeBasedLockTime.deserialize(keypair),
      PsbtInputTypes.requiredHeightBasedLockTime =>
        PsbtInputRequiredHeightBasedLockTime.deserialize(keypair),
      PsbtInputTypes.taprootKeySpentSignature =>
        PsbtInputTaprootKeySpendSignature.deserialize(keypair),
      PsbtInputTypes.taprootScriptSpentSignature =>
        PsbtInputTaprootScriptSpendSignature.deserialize(keypair),
      PsbtInputTypes.taprootLeafScript =>
        PsbtInputTaprootLeafScript.deserialize(keypair),
      PsbtInputTypes.taprootBip32Derivation =>
        PsbtInputTaprootKeyBip32DerivationPath.deserialize(keypair),
      PsbtInputTypes.taprootInternalKey =>
        PsbtInputTaprootInternalKey.deserialize(keypair),
      PsbtInputTypes.taprootMerkleRoot =>
        PsbtInputTaprootMerkleRoot.deserialize(keypair),
      PsbtInputTypes.muSig2ParticipantPublicKeys =>
        PsbtInputMuSig2ParticipantPublicKeys.deserialize(keypair),
      PsbtInputTypes.muSig2PublicNonce =>
        PsbtInputMuSig2PublicNonce.deserialize(keypair),
      PsbtInputTypes.muSig2ParticipantPartialSignature =>
        PsbtInputMuSig2ParticipantPartialSignature.deserialize(keypair),
      PsbtInputTypes.silentPaymentInputECDHShare =>
        PsbtInputSilentPaymentInputECDHShare.deserialize(keypair),
      PsbtInputTypes.silentPaymentInputDLEQProof =>
        PsbtInputSilentPaymentInputDLEQProof.deserialize(keypair),
      PsbtInputTypes.proprietaryUseType =>
        PsbtInputProprietaryUseType.deserialize(keypair),
      PsbtInputTypes.unknown => PsbtInputUnknow(keypair),
    };
  }

  T cast<T extends PsbtInputData>() {
    if (this is! T) {
      throw DartBitcoinPluginException(
          "Invalid cast: expected ${T.runtimeType}, but found $runtimeType.",
          details: {"expected": "$T", "type": runtimeType.toString()});
    }
    return this as T;
  }

  @override
  String toString() {
    return type.name;
  }

  Map<String, dynamic> toJson();
}

class PsbtInputNonWitnessUtxo extends PsbtInputData {
  /// The transaction in network serialization format the current input spends from.
  /// This should be present for inputs that spend non-segwit outputs and can be present
  /// for inputs that spend segwit outputs. An input can have both PSBT_IN_NON_WITNESS_UTXO and PSBT_IN_WITNESS_UTXO.
  final BtcTransaction transaction;
  PsbtInputNonWitnessUtxo._({required this.transaction, required super.keyPair})
      : super(type: PsbtInputTypes.nonWitnessUTXO);
  PsbtInputNonWitnessUtxo(this.transaction)
      : super(
            type: PsbtInputTypes.nonWitnessUTXO,
            keyPair: PsbtKeyPair(
                key: PsbtKey(PsbtInputTypes.nonWitnessUTXO.flag!),
                value: PsbtValue(transaction.toBytes())));
  factory PsbtInputNonWitnessUtxo.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.nonWitnessUTXO.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Non-Witness UTXO type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Non-Witness UTXO key data.");
    }
    try {
      final transaction = BtcTransaction.deserialize(keypair.value.data);
      return PsbtInputNonWitnessUtxo._(
          transaction: transaction, keyPair: keypair);
    } catch (_) {
      throw DartBitcoinPluginException("Invalid PSBT Non-Witness UTXO data.");
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "transaction": transaction.toJson(),
    };
  }
}

class PsbtInputWitnessUtxo extends PsbtInputData {
  /// The entire transaction output in network serialization which the current input spends from.
  /// This should only be present for inputs which spend segwit outputs, including P2SH embedded ones.
  /// An input can have both PSBT_IN_NON_WITNESS_UTXO and PSBT_IN_WITNESS_UTXO
  final BigInt amount;
  final Script scriptPubKey;
  PsbtInputWitnessUtxo._(
      {required BigInt amount,
      required this.scriptPubKey,
      required super.keyPair})
      : amount = amount.asUint64,
        super(type: PsbtInputTypes.witnessUTXO);
  factory PsbtInputWitnessUtxo(
      {required BigInt amount, required Script scriptPubKey}) {
    return PsbtInputWitnessUtxo._(
        amount: amount,
        scriptPubKey: scriptPubKey,
        keyPair: () {
          final amountBytes =
              BigintUtils.toBytes(amount, length: 8, order: Endian.little);
          final scriptBytes = IntUtils.prependVarint(scriptPubKey.toBytes());
          return PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.witnessUTXO.flag!),
              value: PsbtValue([...amountBytes, ...scriptBytes]));
        }());
  }

  factory PsbtInputWitnessUtxo.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.witnessUTXO.flag) {
      throw DartBitcoinPluginException("Invalid PSBT Witness UTXO type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException("Invalid PSBT Witness UTXO key data.");
    }
    final bytes = keypair.value.data;
    final amount =
        BigintUtils.fromBytes(bytes.sublist(0, 8), byteOrder: Endian.little);
    final scriptLength = IntUtils.decodeVarint(bytes.sublist(8));
    final int offset = 8 + scriptLength.item2;
    final int length = scriptLength.item1;
    final script =
        Script.deserialize(bytes: bytes.sublist(offset, offset + length));
    return PsbtInputWitnessUtxo._(
        amount: amount, scriptPubKey: script, keyPair: keypair);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "amount": amount.toString(),
      "scriptPubKey": scriptPubKey.toJson()
    };
  }
}

class PsbtInputPartialSig extends PsbtInputDataSignature {
  /// The public key which corresponds to this signature.
  final ECPublic publicKey;
  final List<int> publicKeyBytes;

  final PubKeyModes mode;

  PsbtInputPartialSig._(
      {required super.signature,
      required this.publicKey,
      required this.mode,
      required super.keyPair,
      required List<int> publicKeyBytes})
      : publicKeyBytes = publicKeyBytes.asImmutableBytes,
        super._(type: PsbtInputTypes.partialSignature);
  factory PsbtInputPartialSig(
      {required List<int> signature, required List<int> publicKey}) {
    if (PsbtUtils.isValidBitcoinDERSignature(signature)) {
      final pubKey = ECPublic.fromBytes(publicKey);
      final mode = publicKey.length == EcdsaKeysConst.pubKeyCompressedByteLen
          ? PubKeyModes.compressed
          : PubKeyModes.uncompressed;
      return PsbtInputPartialSig._(
          signature: signature,
          publicKey: pubKey,
          publicKeyBytes: publicKey,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.partialSignature.flag!,
                  extraData: pubKey.toBytes(mode: mode)),
              value: PsbtValue(signature)),
          mode: mode);
    }
    throw DartBitcoinPluginException("Invalid PSBT Partial Signature data.");
  }

  factory PsbtInputPartialSig.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.partialSignature.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Partial Signature type flag.");
    }
    if (PsbtUtils.isValidBitcoinDERSignature(keypair.value.data)) {
      try {
        final mode = keypair.key.extraData?.length ==
                EcdsaKeysConst.pubKeyCompressedByteLen
            ? PubKeyModes.compressed
            : PubKeyModes.uncompressed;
        return PsbtInputPartialSig._(
            signature: keypair.value.data,
            publicKey: ECPublic.fromBytes(keypair.key.extraData!),
            publicKeyBytes: keypair.key.extraData!,
            mode: mode,
            keyPair: keypair);
      } catch (_) {}
    }
    throw DartBitcoinPluginException("Invalid PSBT Partial Signature data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "signature": BytesUtils.toHexString(signature),
      "publicKey": publicKey.toHex(mode: mode)
    };
  }
}

class PsbtInputSigHash extends PsbtInputData {
  /// The 32-bit unsigned integer specifying the sighash type to be used for this input.
  /// Signatures for this input must use the sighash type, finalizers must fail to finalize
  /// inputs which have signatures that do not match the specified sighash type.
  /// Signers who cannot produce signatures with the sighash type must not provide a signature.
  final int sighash;
  PsbtInputSigHash._({required int sighash, required super.keyPair})
      : sighash = sighash.asUint32,
        super(type: PsbtInputTypes.sighashType);
  factory PsbtInputSigHash(int sighash) {
    return PsbtInputSigHash._(
        sighash: sighash,
        keyPair: () {
          final sighashBytes = IntUtils.toBytes(sighash,
              length: BitcoinOpCodeConst.sighashByteLength,
              byteOrder: Endian.little);
          return PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.sighashType.flag!),
              value: PsbtValue(sighashBytes));
        }());
  }
  factory PsbtInputSigHash.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.sighashType.flag) {
      throw DartBitcoinPluginException("Invalid PSBT sighash type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException("Invalid PSBT sighash type key data.");
    }

    try {
      if (keypair.value.data.length == BitcoinOpCodeConst.sighashByteLength) {
        return PsbtInputSigHash._(
            sighash:
                IntUtils.fromBytes(keypair.value.data, byteOrder: Endian.little)
                    .asUint32,
            keyPair: keypair);
      }
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT sighash type data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "sighash": sighash};
  }
}

/// The redeemScript for this input if it has one.
class PsbtInputRedeemScript extends PsbtInputData {
  final Script redeemScript;
  PsbtInputRedeemScript._({required this.redeemScript, required super.keyPair})
      : super(type: PsbtInputTypes.redeemScript);
  PsbtInputRedeemScript(this.redeemScript)
      : super(
            type: PsbtInputTypes.redeemScript,
            keyPair: PsbtKeyPair(
                key: PsbtKey(PsbtInputTypes.redeemScript.flag!),
                value: PsbtValue(redeemScript.toBytes())));
  factory PsbtInputRedeemScript.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.redeemScript.flag) {
      throw DartBitcoinPluginException("Invalid PSBT Redeem Script type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException("Invalid PSBT Redeem Script key data.");
    }
    Script redeemScript;
    try {
      redeemScript = Script.deserialize(bytes: keypair.value.data);
    } catch (_) {
      throw DartBitcoinPluginException("Invalid PSBT Redeem Script data.");
    }
    return PsbtInputRedeemScript._(
        keyPair: keypair, redeemScript: redeemScript);
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "redeemScript": redeemScript.toJson()};
  }
}

class PsbtInputWitnessScript extends PsbtInputData {
  /// The witnessScript for this input if it has one.
  final Script witnessScript;
  PsbtInputWitnessScript._(
      {required this.witnessScript, required super.keyPair})
      : super(type: PsbtInputTypes.witnessScript);
  PsbtInputWitnessScript(this.witnessScript)
      : super(
            type: PsbtInputTypes.witnessScript,
            keyPair: PsbtKeyPair(
                key: PsbtKey(PsbtInputTypes.witnessScript.flag!),
                value: PsbtValue(witnessScript.toBytes())));
  factory PsbtInputWitnessScript.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.witnessScript.flag) {
      throw DartBitcoinPluginException("Invalid PSBT Witness Script type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException("Invalid PSBT Witness Script key data.");
    }
    Script witnessScript;
    try {
      witnessScript = Script.deserialize(bytes: keypair.value.data);
    } catch (_) {
      throw DartBitcoinPluginException("Invalid PSBT Witness Script data.");
    }
    return PsbtInputWitnessScript._(
        witnessScript: witnessScript, keyPair: keypair);
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "witnessScript": witnessScript.toJson()};
  }
}

class PsbtInputBip32DerivationPath extends PsbtInputData {
  /// The master key fingerprint as defined by BIP 32 concatenated with the derivation path of the public key.
  /// The derivation path is represented as 32 bit unsigned integer indexes concatenated with each other.
  /// Public keys are those that will be needed to sign this input.
  final List<int> fingerprint;
  final List<Bip32KeyIndex> indexes;

  /// The public key
  final List<int> publicKey;

  String get path {
    return Bip32Path(elems: indexes).toString();
  }

  BipOrTaprootKeyDerivationRequest toKeyDerivation() {
    return BipOrTaprootKeyDerivationRequest(
        pubKeyOrXonly: publicKey, indexes: indexes, fingerprint: fingerprint);
  }

  PsbtInputBip32DerivationPath._({
    required List<int> fingerprint,
    required List<Bip32KeyIndex> indexes,
    required List<int> publicKey,
    required super.keyPair,
  })  : fingerprint = fingerprint.asImmutableBytes,
        publicKey = publicKey.asImmutableBytes,
        indexes = indexes.immutable,
        super(type: PsbtInputTypes.bip32DerivationPath);
  factory PsbtInputBip32DerivationPath({
    required List<int> fingerprint,
    required List<Bip32KeyIndex> indexes,
    required List<int> publicKey,
  }) {
    if (fingerprint.length == Bip32KeyDataConst.fingerprintByteLen &&
        Secp256k1PublicKeyEcdsa.isValidBytes(publicKey)) {
      return PsbtInputBip32DerivationPath._(
          fingerprint: fingerprint,
          indexes: indexes,
          publicKey: publicKey,
          keyPair: () {
            final List<int> indexesBytes = indexes
                .map((e) => e.toBytes(Endian.little))
                .expand((e) => e)
                .toList();
            return PsbtKeyPair(
                key: PsbtKey(PsbtInputTypes.bip32DerivationPath.flag!,
                    extraData: publicKey),
                value: PsbtValue([...fingerprint, ...indexesBytes]));
          }());
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT BIP 32 Derivation Path data.");
  }

  factory PsbtInputBip32DerivationPath.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.bip32DerivationPath.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT BIP 32 Derivation Path type flag");
    }
    if (keypair.value.data.length < Bip32KeyDataConst.fingerprintByteLen ||
        keypair.value.data.length % Bip32KeyDataConst.fingerprintByteLen != 0) {
      throw DartBitcoinPluginException(
          "Invalid PSBT BIP 32 Derivation Path fingerprint or bip32 index.");
    }
    final List<int> fingerPrint =
        keypair.value.data.sublist(0, Bip32KeyDataConst.fingerprintByteLen);
    final indexesBytes =
        keypair.value.data.sublist(Bip32KeyDataConst.fingerprintByteLen);
    final indexCount = indexesBytes.length ~/ Bip32KeyDataConst.keyIndexByteLen;
    final List<Bip32KeyIndex> bip32Indexes;
    try {
      bip32Indexes = List.generate(indexCount, (i) {
        final offset = i * Bip32KeyDataConst.keyIndexByteLen;
        return Bip32KeyIndex.fromBytes(indexesBytes.sublist(
            offset, offset + Bip32KeyDataConst.keyIndexByteLen));
      });
      if (fingerPrint.length == Bip32KeyDataConst.fingerprintByteLen &&
          Secp256k1PublicKeyEcdsa.isValidBytes(keypair.key.extraData ?? [])) {
        return PsbtInputBip32DerivationPath._(
            fingerprint: fingerPrint,
            indexes: bip32Indexes,
            publicKey: keypair.key.extraData ?? [],
            keyPair: keypair);
      }
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid BIP 32 Derivation Path indexes.");
  }

  factory PsbtInputBip32DerivationPath.fromBip32(
      {required Bip32Slip10Secp256k1 masterKey, required String path}) {
    final derive = masterKey.derivePath(path);
    final indexes = Bip32PathParser.parse(path).elems;
    return PsbtInputBip32DerivationPath(
        fingerprint: derive.fingerPrint.toBytes(),
        indexes: indexes,
        publicKey: derive.publicKey.compressed);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "fingerprint": BytesUtils.toHexString(fingerprint),
      "indexes": indexes.map((e) => e.index).toList(),
      "publicKey": BytesUtils.toHexString(publicKey)
    };
  }
}

class PsbtInputFinalizedScriptSig extends PsbtInputData {
  /// The Finalized scriptSig contains a fully constructed scriptSig with signatures and any other scripts necessary
  /// for the input to pass validation.
  final Script finalizedScriptSig;
  PsbtInputFinalizedScriptSig._(
      {required this.finalizedScriptSig, required super.keyPair})
      : super(type: PsbtInputTypes.finalizedScriptSig);
  PsbtInputFinalizedScriptSig(this.finalizedScriptSig)
      : super(
            type: PsbtInputTypes.finalizedScriptSig,
            keyPair: PsbtKeyPair(
                key: PsbtKey(PsbtInputTypes.finalizedScriptSig.flag!),
                value: PsbtValue(finalizedScriptSig.toBytes())));
  factory PsbtInputFinalizedScriptSig.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.finalizedScriptSig.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Finalized scriptSig type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Finalized scriptSig key data.");
    }
    try {
      final finalizedScriptSig = Script.deserialize(bytes: keypair.value.data);
      return PsbtInputFinalizedScriptSig._(
          keyPair: keypair, finalizedScriptSig: finalizedScriptSig);
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Finalized scriptSig data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "finalizedScriptSig": finalizedScriptSig.toJson()
    };
  }
}

class PsbtInputFinalizedScriptWitness extends PsbtInputData {
  /// The Finalized scriptWitness contains a fully constructed scriptWitness with
  /// signatures and any other scripts necessary for the input to pass validation.
  final TxWitnessInput finalizedScriptWitness;
  PsbtInputFinalizedScriptWitness._(
      {required this.finalizedScriptWitness, required super.keyPair})
      : super(type: PsbtInputTypes.finalizedWitness);
  PsbtInputFinalizedScriptWitness(this.finalizedScriptWitness)
      : super(
            type: PsbtInputTypes.finalizedWitness,
            keyPair: PsbtKeyPair(
                key: PsbtKey(PsbtInputTypes.finalizedWitness.flag!),
                value: PsbtValue(finalizedScriptWitness.toBytes())));
  factory PsbtInputFinalizedScriptWitness.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.finalizedWitness.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Finalized scriptWitness type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Finalized scriptWitness key data.");
    }
    try {
      final finalizedScriptWitness =
          TxWitnessInput.deserialize(keypair.value.data);
      return PsbtInputFinalizedScriptWitness._(
          finalizedScriptWitness: finalizedScriptWitness, keyPair: keypair);
    } catch (_) {}
    throw DartBitcoinPluginException(
        "Invalid PSBT Finalized scriptWitness data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "finalizedScriptWitness": finalizedScriptWitness.toJson()
    };
  }
}

/// The UTF-8 encoded commitment message string for the proof-of-reserves.
/// See BIP 127 for more information.
class PsbtInputPorCommitments extends PsbtInputData {
  final String commitmentMessage;
  PsbtInputPorCommitments._(
      {required this.commitmentMessage, required super.keyPair})
      : super(type: PsbtInputTypes.porCommitments);
  PsbtInputPorCommitments(this.commitmentMessage)
      : super(
            type: PsbtInputTypes.porCommitments,
            keyPair: PsbtKeyPair(
                key: PsbtKey(PsbtInputTypes.porCommitments.flag!),
                value: PsbtValue(StringUtils.encode(commitmentMessage))));
  factory PsbtInputPorCommitments.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.porCommitments.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Proof-of-reserves commitment type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Proof-of-reserves commitment key data.");
    }
    try {
      final message = StringUtils.decode(keypair.value.data);
      return PsbtInputPorCommitments._(
          commitmentMessage: message, keyPair: keypair);
    } catch (_) {}
    throw DartBitcoinPluginException(
        "Invalid PSBT Proof-of-reserves commitment data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "commitmentMessage": commitmentMessage};
  }
}

class PsbtInputRipemd160 extends PsbtInputData {
  /// The hash preimage, encoded as a byte vector, which must equal the key when run through the RIPEMD160 algorithm
  final List<int> preimage;

  /// The resulting hash of the preimage
  final List<int> hash;
  String preImageHex() {
    return BytesUtils.toHexString(preimage);
  }

  PsbtInputRipemd160._(
      {required List<int> preimage,
      required List<int> hash,
      required super.keyPair})
      : preimage = preimage.asImmutableBytes,
        hash = hash.asImmutableBytes,
        super(type: PsbtInputTypes.ripemd160);
  factory PsbtInputRipemd160(
      {required List<int> preimage, required List<int> hash}) {
    if (hash.length == QuickCrypto.hash160DigestSize) {
      return PsbtInputRipemd160._(
          preimage: preimage,
          hash: hash,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.ripemd160.flag!, extraData: hash),
              value: PsbtValue(preimage)));
    }
    throw DartBitcoinPluginException("Invalid PSBT RIPEMD160 hash length.");
  }
  factory PsbtInputRipemd160.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.ripemd160.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT RIPEMD160 preimage type flag");
    }
    if (keypair.key.extraData?.length == QuickCrypto.hash160DigestSize) {
      return PsbtInputRipemd160._(
          hash: keypair.key.extraData ?? [],
          preimage: keypair.value.data,
          keyPair: keypair);
    }
    throw DartBitcoinPluginException("Invalid PSBT RIPEMD160 preimage date");
  }

  factory PsbtInputRipemd160.fromPreImage(List<int> preimage) {
    return PsbtInputRipemd160(
        preimage: preimage, hash: QuickCrypto.ripemd160Hash(preimage));
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "preimage": BytesUtils.toHexString(preimage),
      "hash": BytesUtils.toHexString(hash)
    };
  }
}

class PsbtInputSha256 extends PsbtInputData {
  /// The hash preimage, encoded as a byte vector, which must equal the key when run through the SHA256 algorithm
  final List<int> preimage;

  /// The resulting hash of the preimage
  final List<int> hash;

  String preImageHex() {
    return BytesUtils.toHexString(preimage);
  }

  PsbtInputSha256._({
    required List<int> preimage,
    required List<int> hash,
    required super.keyPair,
  })  : preimage = preimage.asImmutableBytes,
        hash = hash.asImmutableBytes,
        super(type: PsbtInputTypes.sha256);
  factory PsbtInputSha256(
      {required List<int> preimage, required List<int> hash}) {
    if (hash.length == QuickCrypto.sha256DigestSize) {
      return PsbtInputSha256._(
          preimage: preimage,
          hash: hash,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.sha256.flag!, extraData: hash),
              value: PsbtValue(preimage)));
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT SHA256 preimage hash length.");
  }
  factory PsbtInputSha256.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.sha256.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT SHA256 preimage type flag");
    }
    if (keypair.key.extraData?.length == QuickCrypto.sha256DigestSize) {
      return PsbtInputSha256._(
          hash: keypair.key.extraData!,
          preimage: keypair.value.data,
          keyPair: keypair);
    }
    throw DartBitcoinPluginException("Invalid PSBT SHA256 preimage data");
  }
  factory PsbtInputSha256.fromPreImage(List<int> preimage) {
    return PsbtInputSha256(
        preimage: preimage, hash: QuickCrypto.sha256Hash(preimage));
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "preimage": BytesUtils.toHexString(preimage),
      "hash": BytesUtils.toHexString(hash)
    };
  }
}

class PsbtInputHash160 extends PsbtInputData {
  /// The hash preimage, encoded as a byte vector, which must equal the key when run through the
  ///  SHA256 algorithm followed by the RIPEMD160 algorithm
  final List<int> preimage;

  /// The resulting hash of the preimage
  final List<int> hash;
  String preImageHex() {
    return BytesUtils.toHexString(preimage);
  }

  PsbtInputHash160._({
    required List<int> preimage,
    required List<int> hash,
    required super.keyPair,
  })  : preimage = preimage.asImmutableBytes,
        hash = hash.asImmutableBytes,
        super(type: PsbtInputTypes.hash160);
  factory PsbtInputHash160(
      {required List<int> preimage, required List<int> hash}) {
    if (hash.length == QuickCrypto.hash160DigestSize) {
      return PsbtInputHash160._(
          preimage: preimage,
          hash: hash,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.hash160.flag!, extraData: hash),
              value: PsbtValue(preimage)));
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT HASH160 preimage hash length.");
  }
  factory PsbtInputHash160.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.hash160.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT HASH160 preimage type flag");
    }
    if (keypair.key.extraData?.length == QuickCrypto.hash160DigestSize) {
      return PsbtInputHash160._(
          hash: keypair.key.extraData!,
          preimage: keypair.value.data,
          keyPair: keypair);
    }

    throw DartBitcoinPluginException("Invalid PSBT HASH160 preimage type flag");
  }
  factory PsbtInputHash160.fromPreImage(List<int> preimage) {
    return PsbtInputHash160(
        preimage: preimage, hash: QuickCrypto.hash160(preimage));
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "preimage": BytesUtils.toHexString(preimage),
      "hash": BytesUtils.toHexString(hash)
    };
  }
}

class PsbtInputHash256 extends PsbtInputData {
  /// The hash preimage, encoded as a byte vector, which must equal the key when run through the SHA256 algorithm twice
  final List<int> preimage;

  /// The resulting hash of the preimage
  final List<int> hash;
  String preImageHex() {
    return BytesUtils.toHexString(preimage);
  }

  PsbtInputHash256._({
    required List<int> preimage,
    required List<int> hash,
    required super.keyPair,
  })  : preimage = preimage.asImmutableBytes,
        hash = hash.asImmutableBytes,
        super(type: PsbtInputTypes.hash256);
  factory PsbtInputHash256(
      {required List<int> preimage, required List<int> hash}) {
    if (hash.length == QuickCrypto.sha256DigestSize) {
      return PsbtInputHash256._(
          preimage: preimage,
          hash: hash,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.hash256.flag!, extraData: hash),
              value: PsbtValue(preimage)));
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT HASH256 preimage hash length.");
  }
  factory PsbtInputHash256.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.hash256.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT HASH256 preimage type flag");
    }
    if (keypair.key.extraData?.length == QuickCrypto.sha256DigestSize) {
      return PsbtInputHash256._(
          hash: keypair.key.extraData ?? [],
          preimage: keypair.value.data,
          keyPair: keypair);
    }
    throw DartBitcoinPluginException("Invalid PSBT HASH256 preimage data.");
  }
  factory PsbtInputHash256.fromPreImage(List<int> preimage) {
    return PsbtInputHash256(
        preimage: preimage, hash: QuickCrypto.sha256DoubleHash(preimage));
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "preimage": BytesUtils.toHexString(preimage),
      "hash": BytesUtils.toHexString(hash)
    };
  }
}

class PsbtInputPreviousTXID extends PsbtInputData {
  /// 32 byte txid of the previous transaction whose output at PSBT_IN_OUTPUT_INDEX is being spent.
  final List<int> txId;
  PsbtInputPreviousTXID._({
    required List<int> txId,
    required super.keyPair,
  })  : txId = txId.asImmutableBytes,
        super(type: PsbtInputTypes.previousTxId);
  factory PsbtInputPreviousTXID(List<int> txId) {
    if (txId.length == QuickCrypto.sha256DigestSize) {
      return PsbtInputPreviousTXID._(
          txId: txId,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.previousTxId.flag!),
              value: PsbtValue(txId)));
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT Previous TXID transaction id bytes length.");
  }
  factory PsbtInputPreviousTXID.fromHex(String txId) {
    return PsbtInputPreviousTXID(
        BytesUtils.fromHexString(txId).reversed.toList());
  }
  factory PsbtInputPreviousTXID.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.previousTxId.flag) {
      throw DartBitcoinPluginException("Invalid PSBT Previous TXID type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException("Invalid PSBT Previous TXID key data.");
    }
    if (keypair.value.data.length == QuickCrypto.sha256DigestSize) {
      return PsbtInputPreviousTXID._(
          keyPair: keypair, txId: keypair.value.data);
    }
    throw DartBitcoinPluginException("Invalid PSBT Previous TXID key data.");
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is PsbtInputPreviousTXID &&
        BytesUtils.bytesEqual(other.txId, txId)) {
      return true;
    }
    return false;
  }

  String txIdHex() {
    return BytesUtils.toHexString(txId.reversed.toList());
  }

  @override
  int get hashCode => HashCodeGenerator.generateBytesHashCode(txId, [type]);
  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "txId": txIdHex()};
  }
}

/// 32 bit little endian integer representing the index of
/// the output being spent in the transaction with the txid of PSBT_IN_PREVIOUS_TXID.
class PsbtInputSpentOutputIndex extends PsbtInputData {
  final int index;
  PsbtInputSpentOutputIndex._({required int index, required super.keyPair})
      : index = index.asUint32,
        super(type: PsbtInputTypes.spentOutputIndex);
  factory PsbtInputSpentOutputIndex(int index) {
    return PsbtInputSpentOutputIndex._(
        index: index,
        keyPair: () {
          final indexBytes = IntUtils.toBytes(index,
              length: BitcoinOpCodeConst.outputIndexBytesLength,
              byteOrder: Endian.little);
          return PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.spentOutputIndex.flag!),
              value: PsbtValue(indexBytes));
        }());
  }
  factory PsbtInputSpentOutputIndex.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.spentOutputIndex.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Spent Output Index type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Spent Output Index key data.");
    }
    try {
      if (keypair.value.data.length ==
          BitcoinOpCodeConst.outputIndexBytesLength) {
        return PsbtInputSpentOutputIndex(
            IntUtils.fromBytes(keypair.value.data, byteOrder: Endian.little)
                .asUint32);
      }
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Spent Output Index data.");
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is PsbtInputSpentOutputIndex && index == other.index) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([index, type]);
  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "index": index};
  }
}

class PsbtInputSequenceNumber extends PsbtInputData {
  /// The 32 bit unsigned little endian integer for the sequence number of this input.
  /// If omitted, the sequence number is assumed to be the final sequence number (0xffffffff).
  final int sequence;
  PsbtInputSequenceNumber._({required int sequence, required super.keyPair})
      : sequence = sequence.asUint32,
        super(type: PsbtInputTypes.sequenceNumber);
  factory PsbtInputSequenceNumber(int sequence) {
    return PsbtInputSequenceNumber._(
        sequence: sequence,
        keyPair: () {
          final sequenceBytes = IntUtils.toBytes(sequence,
              length: BitcoinOpCodeConst.sequenceLengthInBytes,
              byteOrder: Endian.little);
          return PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.sequenceNumber.flag!),
              value: PsbtValue(sequenceBytes));
        }());
  }
  factory PsbtInputSequenceNumber.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.sequenceNumber.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Sequence Number type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Sequence Number key data.");
    }
    try {
      if (keypair.value.data.length ==
          BitcoinOpCodeConst.sequenceLengthInBytes) {
        return PsbtInputSequenceNumber(
            IntUtils.fromBytes(keypair.value.data, byteOrder: Endian.little)
                .asUint32);
      }
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Sequence Number data.");
  }

  List<int> sequenceBytes() {
    return IntUtils.toBytes(sequence,
        length: BitcoinOpCodeConst.locktimeLengthInBytes,
        byteOrder: Endian.little);
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "sequence": sequence};
  }
}

class PsbtInputRequiredTimeBasedLockTime extends PsbtInputData {
  /// endian uint locktime>	32 bit unsigned little endian integer greater than or equal to 500000000 representing
  /// the minimum Unix timestamp that this input requires to be set as the transaction's lock time.
  final int locktime;

  PsbtInputRequiredTimeBasedLockTime._(
      {required int locktime, required super.keyPair})
      : locktime = locktime.asUint32,
        super(type: PsbtInputTypes.requiredTimeBasedLockTime);
  factory PsbtInputRequiredTimeBasedLockTime(int locktime) {
    if (locktime < 500000000 || locktime > maxUint32) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Required Time-based Locktime data.");
    }
    return PsbtInputRequiredTimeBasedLockTime._(
        locktime: locktime,
        keyPair: () {
          final locktimeBytes = IntUtils.toBytes(locktime,
              length: BitcoinOpCodeConst.locktimeLengthInBytes,
              byteOrder: Endian.little);
          return PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.requiredTimeBasedLockTime.flag!),
              value: PsbtValue(locktimeBytes));
        }());
  }
  factory PsbtInputRequiredTimeBasedLockTime.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.requiredTimeBasedLockTime.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Required Time-based Locktime type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Required Time-based Locktime key data.");
    }
    try {
      if (keypair.value.data.length ==
          BitcoinOpCodeConst.locktimeLengthInBytes) {
        final locktime =
            IntUtils.fromBytes(keypair.value.data, byteOrder: Endian.little)
                .asUint32;
        if (locktime < 500000000 || locktime > maxUint32) {
          throw DartBitcoinPluginException(
              "Invalid PSBT Required Time-based Locktime data.");
        }
        return PsbtInputRequiredTimeBasedLockTime._(
            locktime: locktime, keyPair: keypair);
      }
    } catch (_) {}
    throw DartBitcoinPluginException(
        "Invalid PSBT Required Time-based Locktime data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "locktime": locktime};
  }

  List<int> sequenceBytes() {
    return IntUtils.toBytes(locktime,
        length: BitcoinOpCodeConst.sequenceLengthInBytes,
        byteOrder: Endian.little);
  }
}

class PsbtInputRequiredHeightBasedLockTime extends PsbtInputData {
  /// 32 bit unsigned little endian integer less than 500000000 representing the minimum
  /// block height that this input requires to be set as the transaction's lock time.
  final int height;

  PsbtInputRequiredHeightBasedLockTime._(
      {required int height, required super.keyPair})
      : height = height.asUint32,
        super(
          type: PsbtInputTypes.requiredHeightBasedLockTime,
        );
  factory PsbtInputRequiredHeightBasedLockTime(int height) {
    if (height.isNegative || height >= 500000000) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Required Height-based Locktime data.");
    }
    return PsbtInputRequiredHeightBasedLockTime._(
        height: height,
        keyPair: () {
          final locktimeBytes = IntUtils.toBytes(height,
              length: BitcoinOpCodeConst.locktimeLengthInBytes,
              byteOrder: Endian.little);
          return PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.requiredHeightBasedLockTime.flag!),
              value: PsbtValue(locktimeBytes));
        }());
  }
  factory PsbtInputRequiredHeightBasedLockTime.deserialize(
      PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.requiredHeightBasedLockTime.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Required Height-based Locktime type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Required Height-based Locktime key data.");
    }
    try {
      if (keypair.value.data.length ==
          BitcoinOpCodeConst.locktimeLengthInBytes) {
        final height =
            IntUtils.fromBytes(keypair.value.data, byteOrder: Endian.little)
                .asUint32;
        if (height.isNegative || height >= 500000000) {
          throw DartBitcoinPluginException(
              "Invalid PSBT Required Height-based Locktime data.");
        }
        return PsbtInputRequiredHeightBasedLockTime._(
            height: height, keyPair: keypair);
      }
    } catch (_) {}
    throw DartBitcoinPluginException(
        "Invalid PSBT Required Height-based Locktime data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "height": height};
  }

  List<int> sequenceBytes() {
    return IntUtils.toBytes(height,
        length: BitcoinOpCodeConst.locktimeLengthInBytes,
        byteOrder: Endian.little);
  }
}

abstract class PsbtInputDataSignature extends PsbtInputData {
  final List<int> signature;
  PsbtInputDataSignature._(
      {required List<int> signature,
      required super.type,
      required super.keyPair})
      : signature = signature.asImmutableBytes;
  String signatureHex() {
    return BytesUtils.toHexString(signature);
  }
}

/// The 64 or 65 byte Schnorr signature for key path spending a Taproot output.
/// Finalizers should remove this field after PSBT_IN_FINAL_SCRIPTWITNESS is constructed.
class PsbtInputTaprootKeySpendSignature extends PsbtInputDataSignature {
  PsbtInputTaprootKeySpendSignature._(
      {required super.signature, required super.keyPair})
      : super._(type: PsbtInputTypes.taprootKeySpentSignature);
  factory PsbtInputTaprootKeySpendSignature(List<int> signature) {
    if (!CryptoSignatureUtils.isValidSchnorrSignature(signature)) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Key Spend Signature data.");
    }
    return PsbtInputTaprootKeySpendSignature._(
        signature: signature,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtInputTypes.taprootKeySpentSignature.flag!),
            value: PsbtValue(signature)));
  }
  factory PsbtInputTaprootKeySpendSignature.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.taprootKeySpentSignature.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Key Spend Signature type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Key Spend Signature key data.");
    }
    if (!CryptoSignatureUtils.isValidSchnorrSignature(keypair.value.data)) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Key Spend Signature data.");
    }
    return PsbtInputTaprootKeySpendSignature._(
        signature: keypair.value.data, keyPair: keypair);
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "signature": BytesUtils.toHexString(signature)};
  }
}

class PsbtInputTaprootScriptSpendSignature extends PsbtInputDataSignature {
  /// A 32 byte X-only public key involved in a leaf script concatenated with the 32 byte hash of the leaf it is part of.
  final List<int> xOnlyPubKey;
  final List<int> leafHash;

  late final String xOnlyPubKeyHex = BytesUtils.toHexString(xOnlyPubKey);

  PsbtInputTaprootScriptSpendSignature._(
      {required super.signature,
      required List<int> xOnlyPubKey,
      required List<int> leafHash,
      required super.keyPair})
      : xOnlyPubKey = xOnlyPubKey.asImmutableBytes,
        leafHash = leafHash.asImmutableBytes,
        super._(type: PsbtInputTypes.taprootScriptSpentSignature);
  factory PsbtInputTaprootScriptSpendSignature(
      {required List<int> signature,
      required List<int> xOnlyPubKey,
      required List<int> leafHash}) {
    if (xOnlyPubKey.length != EcdsaKeysConst.pointCoordByteLen ||
        leafHash.length != QuickCrypto.sha256DigestSize ||
        !CryptoSignatureUtils.isValidSchnorrSignature(signature)) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Script Spend Signature data.");
    }
    return PsbtInputTaprootScriptSpendSignature._(
        signature: signature,
        xOnlyPubKey: xOnlyPubKey,
        leafHash: leafHash,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtInputTypes.taprootScriptSpentSignature.flag!,
                extraData: [...xOnlyPubKey, ...leafHash]),
            value: PsbtValue(signature)));
  }
  factory PsbtInputTaprootScriptSpendSignature.deserialize(
      PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.taprootScriptSpentSignature.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Script Spend Signature type flag");
    }
    final signature = keypair.value.data;
    if (keypair.key.extraData?.length == EcdsaKeysConst.pointCoordByteLen * 2 &&
        CryptoSignatureUtils.isValidSchnorrSignature(signature)) {
      final key = keypair.key.extraData!;
      return PsbtInputTaprootScriptSpendSignature._(
          xOnlyPubKey: key.sublist(0, EcdsaKeysConst.pointCoordByteLen),
          leafHash: key.sublist(EcdsaKeysConst.pointCoordByteLen),
          signature: signature,
          keyPair: keypair);
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT Taproot Script Spend Signature data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "signature": BytesUtils.toHexString(signature),
      "xOnlyPubKey": BytesUtils.toHexString(xOnlyPubKey),
      "leafHash": BytesUtils.toHexString(leafHash)
    };
  }
}

/// The script for this leaf as would be provided in the witness stack followed by the single byte leaf version. Note that the leaves included in this field should be those that the signers of this input are expected to be able to sign for.
/// Finalizers should remove this field after PSBT_IN_FINAL_SCRIPTWITNESS is constructed.
class PsbtInputTaprootLeafScript extends PsbtInputData {
  /// The control block for this leaf as specified in BIP 341.
  /// The control block contains the merkle tree path to this leaf.
  final List<int> controllBlock;

  /// The script for this leaf as would be provided in the witness stack followed by the single byte leaf version.
  /// Note that the leaves included in this field should be those that the signers of this
  /// input are expected to be able to sign for. Finalizers should remove this field after
  /// PSBT_IN_FINAL_SCRIPTWITNESS is constructed.
  final Script script;
  final int leafVersion;

  final TaprootLeaf leafScript;

  late final String controllBlockHex = BytesUtils.toHexString(controllBlock);

  PsbtInputTaprootLeafScript._({
    required List<int> controllBlock,
    required this.script,
    required super.keyPair,
    required int leafVersion,
  })  : controllBlock = controllBlock.asImmutableBytes,
        leafVersion = leafVersion.asUint8,
        leafScript = TaprootLeaf(script: script, leafVersion: leafVersion),
        super(type: PsbtInputTypes.taprootLeafScript);
  factory PsbtInputTaprootLeafScript(
      {required List<int> controllBlock,
      required Script script,
      required int leafVersion}) {
    try {
      return PsbtInputTaprootLeafScript._(
          controllBlock:
              TaprootControlBlock.deserialize(controllBlock).toBytes(),
          script: script,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.taprootLeafScript.flag!,
                  extraData: controllBlock),
              value: PsbtValue([...script.toBytes(), leafVersion])),
          leafVersion: leafVersion);
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Taproot Leaf Script key.");
  }

  factory PsbtInputTaprootLeafScript.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.taprootLeafScript.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Leaf Script type flag");
    }
    if (keypair.key.extraData == null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Leaf Script key data.");
    }
    try {
      final script = Script.deserialize(
          bytes: keypair.value.data.sublist(0, keypair.value.data.length - 1));
      final version = keypair.value.data.last;
      return PsbtInputTaprootLeafScript._(
          controllBlock:
              TaprootControlBlock.deserialize(keypair.key.extraData!).toBytes(),
          script: script,
          keyPair: keypair,
          leafVersion: version);
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Taproot Leaf Script data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "controllBlock": BytesUtils.toHexString(controllBlock),
      "script": script.toJson(),
      "leafVersion": leafVersion
    };
  }
}

class PsbtInputTaprootKeyBip32DerivationPath extends PsbtInputData {
  /// A 32 byte X-only public key involved in this input. It may be the output key,
  /// the internal key, or a key present in a leaf script.
  final List<int> xOnlyPubKey;

  /// A compact size unsigned integer representing the number of leaf hashes,
  /// followed by a list of leaf hashes, followed by the 4 byte master key
  /// fingerprint concatenated with the derivation path of the public key.
  /// The derivation path is represented as 32-bit little endian unsigned integer indexes concatenated with each other.
  /// Public keys are those needed to spend this output. The leaf hashes are of the leaves which involve this public key.
  /// The internal key does not have leaf hashes, so can be indicated with a hashes len of 0.
  /// Finalizers should remove this field after PSBT_IN_FINAL_SCRIPTWITNESS is constructed.
  final List<List<int>> leavesHashes;
  final List<int> fingerprint;
  final List<Bip32KeyIndex> indexes;
  String get path {
    return Bip32Path(elems: indexes).toString();
  }

  BipOrTaprootKeyDerivationRequest toKeyRequest() {
    return BipOrTaprootKeyDerivationRequest(
        pubKeyOrXonly: xOnlyPubKey,
        indexes: indexes,
        fingerprint: fingerprint,
        leavesHashes: leavesHashes);
  }

  PsbtInputTaprootKeyBip32DerivationPath._({
    required List<int> xOnlyPubKey,
    required List<List<int>> leavesHashes,
    required List<int> fingerprint,
    required List<Bip32KeyIndex> indexes,
    required super.keyPair,
  })  : leavesHashes =
            leavesHashes.map((e) => e.asImmutableBytes).toImutableList,
        fingerprint = fingerprint.asImmutableBytes,
        indexes = indexes.immutable,
        xOnlyPubKey = xOnlyPubKey.asImmutableBytes,
        super(type: PsbtInputTypes.taprootBip32Derivation);
  factory PsbtInputTaprootKeyBip32DerivationPath({
    required List<int> xOnlyPubKey,
    required List<List<int>> leavesHashes,
    required List<int> fingerprint,
    required List<Bip32KeyIndex> indexes,
  }) {
    if (fingerprint.length == Bip32KeyDataConst.fingerprintByteLen &&
        xOnlyPubKey.length == QuickCrypto.sha256DigestSize &&
        leavesHashes.every(
            (element) => element.length == QuickCrypto.sha256DigestSize)) {
      final encodeLenght = IntUtils.encodeVarint(leavesHashes.length);
      return PsbtInputTaprootKeyBip32DerivationPath._(
          xOnlyPubKey: xOnlyPubKey,
          leavesHashes: leavesHashes,
          fingerprint: fingerprint,
          indexes: indexes,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.taprootBip32Derivation.flag!,
                  extraData: xOnlyPubKey),
              value: PsbtValue([
                ...encodeLenght,
                ...leavesHashes.expand((e) => e),
                ...fingerprint,
                ...indexes.map((e) => e.toBytes(Endian.little)).expand((e) => e)
              ])));
    }
    throw DartBitcoinPluginException(
        "Invalid Taproot Key BIP 32 Derivation Path data.");
  }
  factory PsbtInputTaprootKeyBip32DerivationPath.deserialize(
      PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.taprootBip32Derivation.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Key BIP 32 Derivation Path type flag");
    }
    try {
      final vlen = IntUtils.decodeVarint(keypair.value.data);
      final int length = vlen.item1;
      final data = keypair.value.data.sublist(vlen.item2);
      final leavesHashes = List.generate(length, (i) {
        final int offset = i * QuickCrypto.sha256DigestSize;
        return data.sublist(offset, offset + QuickCrypto.sha256DigestSize);
      });
      final int fingerprintOffset =
          leavesHashes.length * QuickCrypto.sha256DigestSize;
      final List<int> fingerprint = data.sublist(fingerprintOffset,
          fingerprintOffset + Bip32KeyDataConst.fingerprintByteLen);
      final List<int> indexesBytes = data
          .sublist(fingerprintOffset + Bip32KeyDataConst.fingerprintByteLen);
      if (indexesBytes.length % Bip32KeyDataConst.keyIndexByteLen == 0) {
        final inIndexesCount =
            indexesBytes.length ~/ Bip32KeyDataConst.keyIndexByteLen;
        final List<Bip32KeyIndex> indexes = List.generate(inIndexesCount, (i) {
          final offset = i * Bip32KeyDataConst.keyIndexByteLen;
          return Bip32KeyIndex.fromBytes(indexesBytes.sublist(
              offset, offset + Bip32KeyDataConst.keyIndexByteLen));
        });
        if (fingerprint.length == Bip32KeyDataConst.fingerprintByteLen &&
            keypair.key.extraData?.length == QuickCrypto.sha256DigestSize &&
            leavesHashes.every(
                (element) => element.length == QuickCrypto.sha256DigestSize)) {
          return PsbtInputTaprootKeyBip32DerivationPath._(
              xOnlyPubKey: keypair.key.extraData!,
              leavesHashes: leavesHashes,
              fingerprint: fingerprint,
              indexes: indexes,
              keyPair: keypair);
        }
      }
    } catch (_) {}

    throw DartBitcoinPluginException(
        "Invalid Taproot Key BIP 32 Derivation Path data.");
  }
  factory PsbtInputTaprootKeyBip32DerivationPath.fromBip32(
      {required Bip32Slip10Secp256k1 masterKey,
      required String path,
      required List<List<int>> leavesHashes}) {
    final indexes = Bip32PathParser.parse(path).elems;
    return PsbtInputTaprootKeyBip32DerivationPath(
      fingerprint: masterKey.fingerPrint.toBytes(),
      indexes: indexes,
      leavesHashes: leavesHashes,
      xOnlyPubKey:
          masterKey.publicKey.point.cast<ProjectiveECCPoint>().toXonly(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "xOnlyPubKey": BytesUtils.toHexString(xOnlyPubKey),
      "fingerprint": BytesUtils.toHexString(fingerprint),
      "leavesHashes":
          leavesHashes.map((e) => BytesUtils.toHexString(e)).toList(),
      "indexes": indexes.map((e) => e.index).toList()
    };
  }
}

class PsbtInputTaprootInternalKey extends PsbtInputData {
  /// The X-only pubkey used as the internal key in this output.
  /// Finalizers should remove this field after PSBT_IN_FINAL_SCRIPTWITNESS is constructed.
  final List<int> xOnlyPubKey;

  PsbtInputTaprootInternalKey._({
    required List<int> xOnlyPubKey,
    required super.keyPair,
  })  : xOnlyPubKey = xOnlyPubKey.asImmutableBytes,
        super(type: PsbtInputTypes.taprootInternalKey);
  factory PsbtInputTaprootInternalKey(List<int> xOnlyPubKey) {
    if (xOnlyPubKey.length != QuickCrypto.sha256DigestSize) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Internal Key data.");
    }
    return PsbtInputTaprootInternalKey._(
        xOnlyPubKey: xOnlyPubKey,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtInputTypes.taprootInternalKey.flag!),
            value: PsbtValue(xOnlyPubKey)));
  }
  factory PsbtInputTaprootInternalKey.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.taprootInternalKey.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Internal Key type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Internal key key data.");
    }
    if (keypair.value.data.length != QuickCrypto.sha256DigestSize) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Internal Key data.");
    }
    return PsbtInputTaprootInternalKey._(
        xOnlyPubKey: keypair.value.data, keyPair: keypair);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "xOnlyPubKey": BytesUtils.toHexString(xOnlyPubKey)
    };
  }
}

class PsbtInputTaprootMerkleRoot extends PsbtInputData {
  /// The 32 byte Merkle root hash. Finalizers should remove this field after PSBT_IN_FINAL_SCRIPTWITNESS is constructed.
  final List<int> hash;

  PsbtInputTaprootMerkleRoot._({
    required List<int> hash,
    required super.keyPair,
  })  : hash = hash.asImmutableBytes,
        super(type: PsbtInputTypes.taprootMerkleRoot);
  factory PsbtInputTaprootMerkleRoot(List<int> hash) {
    if (hash.length != QuickCrypto.sha256DigestSize) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Merkle Root data.");
    }
    return PsbtInputTaprootMerkleRoot._(
        hash: hash,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtInputTypes.taprootMerkleRoot.flag!),
            value: PsbtValue(hash)));
  }
  factory PsbtInputTaprootMerkleRoot.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.taprootMerkleRoot.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Merkle Root type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Merkle Root key data.");
    }
    if (keypair.value.data.length != QuickCrypto.sha256DigestSize) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Merkle Root data.");
    }
    return PsbtInputTaprootMerkleRoot._(
        hash: keypair.value.data, keyPair: keypair);
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "hash": BytesUtils.toHexString(hash)};
  }
}

class PsbtInputMuSig2ParticipantPublicKeys extends PsbtInputData {
  /// The MuSig2 aggregate plain public key from the KeyAgg algorithm.
  /// This key may or may not be in the script directly (as x-only).
  /// It may instead be a parent public key from which the public keys in the script were derived.
  final ECPublic aggregatePubKey;

  /// A list of the compressed public keys of the participants in the
  /// MuSig2 aggregate key in the order required for aggregation.
  /// If sorting was done, then the keys must be in the sorted order.
  final List<ECPublic> pubKeys;

  PsbtInputMuSig2ParticipantPublicKeys._({
    required this.aggregatePubKey,
    required List<ECPublic> pubKeys,
    required super.keyPair,
  })  : pubKeys = pubKeys.toImutableList,
        super(type: PsbtInputTypes.muSig2ParticipantPublicKeys);
  factory PsbtInputMuSig2ParticipantPublicKeys(
      {required ECPublic aggregatePubKey, required List<ECPublic> pubKeys}) {
    return PsbtInputMuSig2ParticipantPublicKeys._(
        aggregatePubKey: aggregatePubKey,
        pubKeys: pubKeys,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtInputTypes.muSig2ParticipantPublicKeys.flag!,
                extraData:
                    aggregatePubKey.toBytes(mode: PubKeyModes.compressed)),
            value: PsbtValue(pubKeys
                .expand((e) => e.toBytes(mode: PubKeyModes.compressed))
                .toList())));
  }
  factory PsbtInputMuSig2ParticipantPublicKeys.deserialize(
      PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.muSig2ParticipantPublicKeys.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT MuSig2 Participant Public Keys type flag");
    }
    if (keypair.key.extraData?.length ==
        EcdsaKeysConst.pubKeyCompressedByteLen) {
      try {
        final pubKeysData = keypair.value.data;
        if (pubKeysData.length % EcdsaKeysConst.pubKeyCompressedByteLen == 0) {
          final pubkeysLength =
              pubKeysData.length ~/ EcdsaKeysConst.pubKeyCompressedByteLen;
          final List<ECPublic> pubKeys = [];
          for (int i = 0; i < pubkeysLength; i++) {
            final int offset = i * EcdsaKeysConst.pubKeyCompressedByteLen;
            final key = pubKeysData
                .sublist(
                    offset, offset + EcdsaKeysConst.pubKeyCompressedByteLen)
                .asImmutableBytes;
            pubKeys.add(ECPublic.fromBytes(key));
          }
          return PsbtInputMuSig2ParticipantPublicKeys._(
              aggregatePubKey: ECPublic.fromBytes(keypair.key.extraData!),
              pubKeys: pubKeys,
              keyPair: keypair);
        }
      } catch (_) {}
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT MuSig2 Participant Public Keys data");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "aggregatePubKey": aggregatePubKey.toHex(),
      "pubKeys": pubKeys.map((e) => e.toHex()).toList()
    };
  }
}

class PsbtInputMuSig2PublicNonce extends PsbtInputData {
  /// The compressed public key of the participant providing this nonce,
  /// followed by the plain public key the participant is providing the nonce for,
  /// followed by the BIP 341 tapleaf hash of the Taproot leaf script that will be signed.
  /// If the aggregate key is the taproot internal key or the taproot output key,
  /// then the tapleaf hash must be omitted. The plain public key must be the key found in
  /// the script and not the aggregate public key that it was derived from, if it was derived from an aggregate key.
  final ECPublic publicKey;
  final ECPublic plainPublicKey;
  final List<int>? tapleafHash;

  /// The public nonce produced by the NonceGen algorithm.
  final List<int> publicNonce;

  PsbtInputMuSig2PublicNonce._(
      {required this.publicKey,
      required this.plainPublicKey,
      required List<int>? tapleafHash,
      required List<int> publicNonce,
      required super.keyPair})
      : tapleafHash = tapleafHash?.asImmutableBytes,
        publicNonce = publicNonce.asImmutableBytes,
        super(type: PsbtInputTypes.muSig2PublicNonce);
  factory PsbtInputMuSig2PublicNonce(
      {required ECPublic publicKey,
      required ECPublic plainPublicKey,
      List<int>? tapleafHash,
      required List<int> publicNonce}) {
    if ((tapleafHash == null ||
            tapleafHash.length == QuickCrypto.sha256DigestSize) &&
        publicNonce.length == EcdsaKeysConst.pubKeyCompressedByteLen * 2) {
      return PsbtInputMuSig2PublicNonce._(
          publicKey: publicKey,
          plainPublicKey: plainPublicKey,
          tapleafHash: tapleafHash,
          publicNonce: publicNonce,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.muSig2PublicNonce.flag!, extraData: [
                ...publicKey.toBytes(mode: PubKeyModes.compressed),
                ...plainPublicKey.toBytes(mode: PubKeyModes.compressed),
                ...tapleafHash ?? []
              ]),
              value: PsbtValue(publicNonce)));
    }
    throw DartBitcoinPluginException("Invalid PSBT MuSig2 Public Nonce data");
  }
  factory PsbtInputMuSig2PublicNonce.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.muSig2PublicNonce.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT MuSig2 Public Nonce type flag");
    }
    if (keypair.key.extraData?.length ==
            (EcdsaKeysConst.pubKeyCompressedByteLen * 2) ||
        keypair.key.extraData?.length ==
                (EcdsaKeysConst.pubKeyCompressedByteLen * 2) +
                    QuickCrypto.sha256DigestSize &&
            keypair.value.data.length == 66) {
      try {
        final publicKey = keypair.key.extraData!
            .sublist(0, EcdsaKeysConst.pubKeyCompressedByteLen);
        final plainPublicKey = keypair.key.extraData!.sublist(
            EcdsaKeysConst.pubKeyCompressedByteLen,
            EcdsaKeysConst.pubKeyCompressedByteLen * 2);
        final hash = keypair.key.extraData!.length ==
                EcdsaKeysConst.pubKeyCompressedByteLen * 2
            ? null
            : keypair.key.extraData!
                .sublist(EcdsaKeysConst.pubKeyCompressedByteLen * 2);
        if (publicKey.length == EcdsaKeysConst.pubKeyCompressedByteLen &&
            Secp256k1PublicKeyEcdsa.isValidBytes(publicKey) &&
            plainPublicKey.length == EcdsaKeysConst.pubKeyCompressedByteLen &&
            Secp256k1PublicKeyEcdsa.isValidBytes(plainPublicKey) &&
            (hash == null || hash.length == QuickCrypto.sha256DigestSize) &&
            keypair.value.data.length ==
                EcdsaKeysConst.pubKeyCompressedByteLen * 2) {
          return PsbtInputMuSig2PublicNonce._(
              publicKey: ECPublic.fromBytes(publicKey),
              plainPublicKey: ECPublic.fromBytes(plainPublicKey),
              tapleafHash: hash,
              publicNonce: keypair.value.data,
              keyPair: keypair);
        }
      } catch (_) {}
    }
    throw DartBitcoinPluginException("Invalid PSBT MuSig2 Public Nonce data");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "publicKey": publicKey.toHex(),
      "plainPublicKey": plainPublicKey.toHex(),
      "tapleafHash": BytesUtils.tryToHexString(tapleafHash),
      "publicNonce": BytesUtils.toHexString(publicNonce)
    };
  }
}

class PsbtInputMuSig2ParticipantPartialSignature
    extends PsbtInputDataSignature {
  /// The compressed public key of the participant providing this partial signature,
  /// followed by the plain public key the participant is providing the signature for,
  /// followed by the BIP 341 tapleaf hash of the Taproot leaf script that will be signed.
  /// If the aggregate key is the taproot internal key or the taproot output key, t
  /// hen the tapleaf hash must be omitted. Note that the plain public key must be the key found in the script
  /// and not the aggregate public key that it was derived from, if it was derived from an aggregate key.
  final ECPublic publicKey;
  final ECPublic plainPublicKey;
  final List<int>? tapleafHash;

  PsbtInputMuSig2ParticipantPartialSignature._(
      {required this.publicKey,
      required this.plainPublicKey,
      required List<int>? tapleafHash,
      required super.signature,
      required super.keyPair})
      : tapleafHash = tapleafHash?.asImmutableBytes,
        super._(type: PsbtInputTypes.muSig2ParticipantPartialSignature);
  factory PsbtInputMuSig2ParticipantPartialSignature(
      {required ECPublic publicKey,
      required ECPublic plainPublicKey,
      required List<int>? tapleafHash,
      required List<int> partialSignature}) {
    if ((tapleafHash == null ||
            tapleafHash.length == QuickCrypto.sha256DigestSize) &&
        partialSignature.length == QuickCrypto.sha256DigestSize) {
      return PsbtInputMuSig2ParticipantPartialSignature._(
          publicKey: publicKey,
          plainPublicKey: plainPublicKey,
          tapleafHash: tapleafHash,
          signature: partialSignature,
          keyPair: PsbtKeyPair(
              key: PsbtKey(
                  PsbtInputTypes.muSig2ParticipantPartialSignature.flag!,
                  extraData: [
                    ...publicKey.toBytes(mode: PubKeyModes.compressed),
                    ...plainPublicKey.toBytes(mode: PubKeyModes.compressed),
                    ...tapleafHash ?? []
                  ]),
              value: PsbtValue(partialSignature)));
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT MuSig2 Participant Partial Signature data");
  }
  factory PsbtInputMuSig2ParticipantPartialSignature.deserialize(
      PsbtKeyPair keypair) {
    if (keypair.key.type !=
        PsbtInputTypes.muSig2ParticipantPartialSignature.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT MuSig2 Participant Partial Signature type flag");
    }
    if (keypair.key.extraData?.length ==
            (EcdsaKeysConst.pubKeyCompressedByteLen * 2) ||
        keypair.key.extraData?.length ==
            (EcdsaKeysConst.pubKeyCompressedByteLen * 2) +
                QuickCrypto.sha256DigestSize) {
      try {
        final publicKey = keypair.key.extraData!
            .sublist(0, EcdsaKeysConst.pubKeyCompressedByteLen);
        final plainPublicKey = keypair.key.extraData!.sublist(
            EcdsaKeysConst.pubKeyCompressedByteLen,
            EcdsaKeysConst.pubKeyCompressedByteLen * 2);
        final hash = keypair.key.extraData!.length ==
                EcdsaKeysConst.pubKeyCompressedByteLen * 2
            ? null
            : keypair.key.extraData!.sublist(66);
        if (publicKey.length == EcdsaKeysConst.pubKeyCompressedByteLen &&
            Secp256k1PublicKeyEcdsa.isValidBytes(publicKey) &&
            plainPublicKey.length == EcdsaKeysConst.pubKeyCompressedByteLen &&
            Secp256k1PublicKeyEcdsa.isValidBytes(plainPublicKey) &&
            (hash == null || hash.length == QuickCrypto.sha256DigestSize) &&
            keypair.value.data.length == QuickCrypto.sha256DigestSize) {
          return PsbtInputMuSig2ParticipantPartialSignature._(
              publicKey: ECPublic.fromBytes(publicKey),
              plainPublicKey: ECPublic.fromBytes(plainPublicKey),
              tapleafHash: hash,
              signature: keypair.value.data,
              keyPair: keypair);
        }
      } catch (_) {}
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT MuSig2 Participant Partial Signature data");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "publicKey": publicKey.toHex(),
      "plainPublicKey": plainPublicKey.toHex(),
      "tapleafHash": BytesUtils.tryToHexString(tapleafHash),
      "partialSignature": BytesUtils.toHexString(signature)
    };
  }
}

class PsbtInputSilentPaymentInputECDHShare extends PsbtInputData {
  /// The scan key that this ECDH share is for.
  final List<int> scanKey;

  /// An ECDH share for a scan key. The ECDH shared is computed with a * B_scan,
  /// where a is the private key of the corresponding prevout public key, and B_scan is the scan key of a recipient.
  final List<int> share;

  PsbtInputSilentPaymentInputECDHShare._({
    required List<int> scanKey,
    required List<int> share,
    required super.keyPair,
  })  : scanKey = scanKey.asImmutableBytes,
        share = share.asImmutableBytes,
        super(type: PsbtInputTypes.silentPaymentInputECDHShare);
  factory PsbtInputSilentPaymentInputECDHShare(
      {required List<int> scanKey, required List<int> share}) {
    if (scanKey.length == EcdsaKeysConst.pubKeyCompressedByteLen &&
        share.length == EcdsaKeysConst.pubKeyCompressedByteLen) {
      return PsbtInputSilentPaymentInputECDHShare._(
          scanKey: scanKey,
          share: share,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.silentPaymentInputECDHShare.flag!,
                  extraData: scanKey),
              value: PsbtValue(share)));
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT Silent Payment Input ECDH Share data");
  }
  factory PsbtInputSilentPaymentInputECDHShare.deserialize(
      PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.silentPaymentInputECDHShare.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Silent Payment Input ECDH Share type flag");
    }
    if (keypair.key.extraData?.length ==
            EcdsaKeysConst.pubKeyCompressedByteLen &&
        keypair.value.data.length == EcdsaKeysConst.pubKeyCompressedByteLen) {
      return PsbtInputSilentPaymentInputECDHShare._(
          scanKey: keypair.key.extraData ?? [],
          share: keypair.value.data,
          keyPair: keypair);
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT Silent Payment Input ECDH Share type");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "scanKey": BytesUtils.toHexString(scanKey),
      "share": BytesUtils.toHexString(share)
    };
  }
}

class PsbtInputSilentPaymentInputDLEQProof extends PsbtInputData {
  /// The scan key that this proof covers.
  final List<int> scanKey;

  /// A BIP374 DLEQ proof computed for the matching ECDH share.
  final List<int> proof;

  PsbtInputSilentPaymentInputDLEQProof._({
    required List<int> scanKey,
    required List<int> proof,
    required super.keyPair,
  })  : scanKey = scanKey.asImmutableBytes,
        proof = proof.asImmutableBytes,
        super(type: PsbtInputTypes.silentPaymentInputDLEQProof);
  factory PsbtInputSilentPaymentInputDLEQProof(
      {required List<int> scanKey, required List<int> proof}) {
    if (scanKey.length == EcdsaKeysConst.pubKeyCompressedByteLen &&
        proof.length == QuickCrypto.sha512DeigestLength) {
      return PsbtInputSilentPaymentInputDLEQProof._(
          scanKey: scanKey,
          proof: proof,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtInputTypes.silentPaymentInputDLEQProof.flag!,
                  extraData: scanKey),
              value: PsbtValue(proof)));
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT Silent Payment Input DLEQ Proof data");
  }
  factory PsbtInputSilentPaymentInputDLEQProof.deserialize(
      PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.silentPaymentInputDLEQProof.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Silent Payment Input DLEQ Proof type flag");
    }
    if (keypair.key.extraData?.length ==
            EcdsaKeysConst.pubKeyCompressedByteLen &&
        keypair.value.data.length == QuickCrypto.sha512DeigestLength) {
      return PsbtInputSilentPaymentInputDLEQProof._(
          scanKey: keypair.key.extraData!,
          proof: keypair.value.data,
          keyPair: keypair);
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT Silent Payment Input DLEQ Proof data");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "scanKey": BytesUtils.toHexString(scanKey),
      "proof": BytesUtils.toHexString(proof)
    };
  }
}

class PsbtInputProprietaryUseType extends PsbtInputData {
  /// Compact size unsigned integer of the length of the identifier, followed by identifier prefix, followed by a compact size unsigned integer subtype, followed by the key data itself.
  final List<int> identifier;
  final List<int> subkeydata;

  /// Any value data as defined by the proprietary type user.
  final List<int> data;

  PsbtInputProprietaryUseType._({
    required List<int> identifier,
    required List<int> subkeydata,
    required List<int> data,
    required super.keyPair,
  })  : identifier = identifier.asImmutableBytes,
        subkeydata = subkeydata.asImmutableBytes,
        data = data.asImmutableBytes,
        super(type: PsbtInputTypes.proprietaryUseType);
  factory PsbtInputProprietaryUseType({
    required List<int> identifier,
    required List<int> subkeydata,
    required List<int> data,
  }) {
    final identifierBytes = IntUtils.prependVarint(identifier);
    final subkeyData = IntUtils.prependVarint(subkeydata);
    return PsbtInputProprietaryUseType._(
        identifier: identifier,
        subkeydata: subkeydata,
        data: data,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtInputTypes.proprietaryUseType.flag!,
                extraData: [...identifierBytes, ...subkeyData]),
            value: PsbtValue(data)));
  }
  factory PsbtInputProprietaryUseType.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtInputTypes.proprietaryUseType.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Proprietary Use Type type flag");
    }
    try {
      final keyBytes = keypair.key.extraData!;
      final identifierSize = IntUtils.decodeVarint(keyBytes);
      final identifier = keyBytes.sublist(
          identifierSize.item2, identifierSize.item1 + identifierSize.item2);
      final subtypeOffset = identifierSize.item1 + identifierSize.item2;
      final subkeydata = keyBytes.sublist(subtypeOffset);
      return PsbtInputProprietaryUseType._(
          identifier: identifier,
          subkeydata: subkeydata,
          data: keypair.value.data,
          keyPair: keypair);
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Proprietary Use Type data");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "identifier": BytesUtils.toHexString(identifier),
      "subkeydata": BytesUtils.toHexString(subkeydata),
      "data": BytesUtils.toHexString(data),
    };
  }
}

class PsbtInputUnknow extends PsbtInputData {
  PsbtInputUnknow._(PsbtKeyPair keyPair)
      : super(type: PsbtInputTypes.unknown, keyPair: keyPair);
  factory PsbtInputUnknow(PsbtKeyPair keyPair) {
    return PsbtInputUnknow._(keyPair);
  }
  @override
  int get flag => keyPair.key.type;

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "key": {
        "keyType": keyPair.key.type,
        "keyData": BytesUtils.tryToHexString(keyPair.key.extraData)
      },
      "value": {"data": BytesUtils.toHexString(keyPair.value.data)},
    };
  }
}
