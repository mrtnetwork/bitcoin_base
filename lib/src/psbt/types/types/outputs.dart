import 'dart:typed_data';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/psbt/psbt_builder/types/types.dart';
import 'package:bitcoin_base/src/psbt/types/types/psbt.dart';
import 'package:bitcoin_base/src/psbt/types/types/types.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

enum PsbtOutputTypes {
  redeemScript(0x00, "PSBT_OUT_REDEEM_SCRIPT"),
  witnessScript(0x01, "PSBT_OUT_WITNESS_SCRIPT"),
  bip32DerivationPath(0x02, "PSBT_OUT_BIP32_DERIVATION"),
  amount(0x03, "PSBT_OUT_AMOUNT",
      required: true, allowedVersion: PsbtVersion.v2),
  script(0x04, "PSBT_OUT_SCRIPT",
      required: true, allowedVersion: PsbtVersion.v2),
  taprootInternalKey(0x05, "PSBT_OUT_TAP_INTERNAL_KEY"),
  taprootTree(0x06, "PSBT_OUT_TAP_TREE"),
  taprootBip32Derivation(0x07, "PSBT_OUT_TAP_BIP32_DERIVATION"),
  muSig2ParticipantPublicKeys(0x08, "PSBT_OUT_MUSIG2_PARTICIPANT_PUBKEYS"),
  silentPaymentData(0x09, "PSBT_OUT_SP_V0_INFO",
      allowedVersion: PsbtVersion.v2),
  silentPaymentLabel(0x0a, "PSBT_OUT_SP_V0_LABEL",
      allowedVersion: PsbtVersion.v2),
  bip353DNSSECProof(0x35, "PSBT_OUT_DNSSEC_PROOF"),
  proprietaryUseType(0xFC, "PSBT_OUT_PROPRIETARY"),
  unknown(null, "UNKNOWN");

  const PsbtOutputTypes(this.flag, this.psbtName,
      {this.allowedVersion, this.required = false});
  final int? flag;
  final String psbtName;
  final bool required;
  final PsbtVersion? allowedVersion;
  static PsbtOutputTypes find(int flag) {
    final type = values.firstWhereNullable((e) => e.flag == flag);
    if (type != null) return type;
    return unknown;
  }
}

/// Represents the output section of a PSBT (Partially Signed Bitcoin Transaction).
class PsbtOutput {
  /// The PSBT version associated with this intput section.
  final PsbtVersion version;

  /// The list of output PSBT entries.
  List<List<PsbtOutputData>> _entries;
  List<List<PsbtOutputData>> get entries => _entries;
  PsbtOutput._(
      {List<List<PsbtOutputData>> entries = const [], required this.version})
      : _entries = entries.map((e) => e.immutable).toImutableList;

  /// Constructs a [PsbtOutput] instance with a given version and output entries.
  ///
  /// Throws a [DartBitcoinPluginException] if any of the following conditions are met:
  /// - Duplicate entries are found.
  /// - A output entry is not allowed for the specified PSBT version.
  /// - A required output entry is missing for the PSBT version
  factory PsbtOutput(
      {List<List<PsbtOutputData>> entries = const [],
      required PsbtVersion version}) {
    final requiredFilds = PsbtOutputTypes.values.where((e) =>
        e.required &&
        (e.allowedVersion == null || e.allowedVersion == version));
    for (final e in entries) {
      final keys = e.map((e) => e.keyPair.key).toList();
      if (keys.toSet().length != keys.length) {
        throw DartBitcoinPluginException(
            "Invalid PSBT Output: Duplicate entry detected.");
      }
      for (final i in e) {
        if (i.type.allowedVersion == null) continue;
        if (version != i.type.allowedVersion) {
          throw DartBitcoinPluginException(
              "Invalid PSBT Output: ${i.type.psbtName} is not allowed in PSBT version ${version.name}.");
        }
      }
      for (final i in requiredFilds) {
        e.firstWhere((e) => e.type == i,
            orElse: () => throw DartBitcoinPluginException(
                "Invalid PSBT Output: Missing required field ${i.psbtName} for PSBT version ${version.name}."));
      }
    }
    return PsbtOutput._(version: version, entries: entries);
  }

  /// Validates if the provided entries is not duplicate and allowed by the PSBT version.
  void _itemsAllowed(List<PsbtOutputData> items) {
    final keys = items.map((e) => e.keyPair.key).toSet();
    if (keys.length != items.length) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Output: Duplicate entry detected.");
    }
    for (final i in items) {
      if (i.type.allowedVersion == null) continue;
      if (version != i.type.allowedVersion) {
        throw DartBitcoinPluginException(
            "Invalid PSBT Output: ${i.type.psbtName} is not allowed in PSBT version ${version.name}.");
      }
    }
  }

  /// Creates a [PsbtOutput] instance from a list of key pairs.
  factory PsbtOutput.fromKeyPairs(
      {List<List<PsbtKeyPair>> keypairs = const [],
      required PsbtVersion version}) {
    return PsbtOutput(
        entries: keypairs
            .map((e) => e.map(PsbtOutputData.deserialize).toList())
            .toList(),
        version: version);
  }

  /// Adds new output to the PSBT.
  void addOutputs(List<PsbtOutputData> outputs) {
    _itemsAllowed(outputs);
    _entries = [..._entries, outputs].toImutableList;
  }

  /// Replaces the output at the specified [index]
  void replaceOutput(int index, List<PsbtOutputData> outputs) {
    _itemsAllowed(outputs);
    final entries = _entries.clone();
    _validateIndex(index);
    entries[index] = outputs.toImutableList;
    _entries = entries.toImutableList;
  }

  int get length => _entries.length;

  List<PsbtOutputData> _validateIndex(int inputIndex) {
    if (inputIndex >= _entries.length) {
      throw DartBitcoinPluginException(
          "Invalid output index: $inputIndex. The index exceeds the number of available entries.");
    }
    return _entries[inputIndex].clone();
  }

  /// Retrieves a single entry of a specified type.
  T? getOutput<T extends PsbtOutputData>(int index, PsbtOutputTypes type) {
    final input = _validateIndex(index);
    final data = input.where((e) => e.type == type);
    if (data.isEmpty) return null;
    if (data.length != 1) {
      throw DartBitcoinPluginException(
          "Multiple inputs with type '${type.name}' found. Use 'getOutputs' to retrieve data for multiple outputs");
    }
    return data.first.cast();
  }

  /// Retrieves all entries of a specified type.
  List<T>? getOutputs<T extends PsbtOutputData>(
      int index, PsbtOutputTypes type) {
    final input = _validateIndex(index);
    final data = input.where((e) => e.type == type);
    if (data.isEmpty) return null;
    return data.toList().cast<T>();
  }

  /// remove the output at the specified [index]
  void removeOutput(int index) {
    _validateIndex(index);
    final entries = _entries.clone();
    entries.removeAt(index);
    _entries = entries.immutable;
  }

  /// Converts the entries to a list of key pairs.
  List<List<PsbtKeyPair>> toKeyPairs() {
    return _entries.map((e) => e.map((e) => e.keyPair).toList()).toList();
  }

  /// Converts the entries to json.
  Map<String, dynamic> toJson() {
    return {
      "entries": entries.map((e) => e.map((e) => e.toJson()).toList()).toList()
    };
  }

  /// Creates a deep copy of the [PsbtOutput] instance.
  PsbtOutput clone() {
    return PsbtOutput(
        version: version, entries: entries.map((e) => e.clone()).toList());
  }
}

abstract class PsbtOutputData {
  Map<String, dynamic> toJson();
  final PsbtOutputTypes type;
  final PsbtKeyPair keyPair;
  const PsbtOutputData({required this.type, required this.keyPair});
  factory PsbtOutputData.deserialize(PsbtKeyPair keypair) {
    final type = PsbtOutputTypes.find(keypair.key.type);
    return switch (type) {
      PsbtOutputTypes.redeemScript =>
        PsbtOutputRedeemScript.deserialize(keypair),
      PsbtOutputTypes.witnessScript =>
        PsbtOutputWitnessScript.deserialize(keypair),
      PsbtOutputTypes.bip32DerivationPath =>
        PsbtOutputBip32DerivationPath.deserialize(keypair),
      PsbtOutputTypes.amount => PsbtOutputAmount.deserialize(keypair),
      PsbtOutputTypes.script => PsbtOutputScript.deserialize(keypair),
      PsbtOutputTypes.taprootInternalKey =>
        PsbtOutputTaprootInternalKey.deserialize(keypair),
      PsbtOutputTypes.taprootTree => PsbtOutputTaprootTree.deserialize(keypair),
      PsbtOutputTypes.taprootBip32Derivation =>
        PsbtOutputTaprootKeyBip32DerivationPath.deserialize(keypair),
      PsbtOutputTypes.muSig2ParticipantPublicKeys =>
        PsbtOutputMuSig2ParticipantPublicKeys.deserialize(keypair),
      PsbtOutputTypes.silentPaymentData =>
        PsbtOutputSilentPaymentData.deserialize(keypair),
      PsbtOutputTypes.silentPaymentLabel =>
        PsbtOutputSilentPaymentLabel.deserialize(keypair),
      PsbtOutputTypes.bip353DNSSECProof =>
        PsbtOutputBIP353DNSSECProof.deserialize(keypair),
      PsbtOutputTypes.proprietaryUseType =>
        PsbtOutputProprietaryUseType.deserialize(keypair),
      PsbtOutputTypes.unknown => PsbtOutputUnknow(keypair),
    };
  }
  T cast<T extends PsbtOutputData>() {
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
}

class PsbtOutputRedeemScript extends PsbtOutputData {
  /// The redeemScript for this output if it has one.
  final Script redeemScript;
  PsbtOutputRedeemScript(this.redeemScript)
      : super(
            type: PsbtOutputTypes.redeemScript,
            keyPair: PsbtKeyPair(
                key: PsbtKey(PsbtOutputTypes.redeemScript.flag!),
                value: PsbtValue(redeemScript.toBytes())));
  PsbtOutputRedeemScript._({required this.redeemScript, required super.keyPair})
      : super(type: PsbtOutputTypes.redeemScript);
  factory PsbtOutputRedeemScript.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtOutputTypes.redeemScript.flag) {
      throw DartBitcoinPluginException("Invalid PSBT Redeem Script type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException("Invalid PSBT Redeem Script key data.");
    }
    try {
      return PsbtOutputRedeemScript._(
          redeemScript: Script.deserialize(bytes: keypair.value.data),
          keyPair: keypair);
    } catch (_) {
      throw DartBitcoinPluginException("Invalid PSBT Redeem Script data.");
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "redeemScript": redeemScript.toJson()};
  }
}

class PsbtOutputWitnessScript extends PsbtOutputData {
  /// The witnessScript for this output if it has one.
  final Script witnessScript;
  PsbtOutputWitnessScript(this.witnessScript)
      : super(
            type: PsbtOutputTypes.witnessScript,
            keyPair: PsbtKeyPair(
                key: PsbtKey(PsbtOutputTypes.witnessScript.flag!),
                value: PsbtValue(witnessScript.toBytes())));
  PsbtOutputWitnessScript._(
      {required this.witnessScript, required super.keyPair})
      : super(type: PsbtOutputTypes.witnessScript);
  factory PsbtOutputWitnessScript.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtOutputTypes.witnessScript.flag) {
      throw DartBitcoinPluginException("Invalid PSBT Witness Script type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException("Invalid PSBT Witness Script key data.");
    }
    try {
      return PsbtOutputWitnessScript._(
          witnessScript: Script.deserialize(bytes: keypair.value.data),
          keyPair: keypair);
    } catch (_) {
      throw DartBitcoinPluginException("Invalid PSBT Witness  Script data.");
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "witnessScript": witnessScript.toJson()};
  }
}

class PsbtOutputBip32DerivationPath extends PsbtOutputData {
  /// The master key fingerprint concatenated with the derivation path of the public key.
  /// The derivation path is represented as 32-bit little endian unsigned integer indexes
  /// concatenated with each other. Public keys are those needed to spend this output.
  final List<int> fingerprint;
  final List<Bip32KeyIndex> indexes;

  /// The public key
  final List<int> publicKey;

  PsbtOutputBip32DerivationPath._({
    required List<int> fingerprint,
    required List<Bip32KeyIndex> indexes,
    required List<int> publicKey,
    required super.keyPair,
  })  : fingerprint = fingerprint.asImmutableBytes,
        publicKey = publicKey.asImmutableBytes,
        indexes = indexes.immutable,
        super(type: PsbtOutputTypes.bip32DerivationPath);
  factory PsbtOutputBip32DerivationPath(
      {required List<int> fingerprint,
      required List<Bip32KeyIndex> indexes,
      required List<int> publicKey}) {
    if (fingerprint.length == Bip32KeyDataConst.fingerprintByteLen &&
        Secp256k1PublicKey.isValidBytes(publicKey)) {
      return PsbtOutputBip32DerivationPath._(
          fingerprint: fingerprint,
          indexes: indexes,
          publicKey: publicKey,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtOutputTypes.bip32DerivationPath.flag!,
                  extraData: publicKey),
              value: PsbtValue([
                ...fingerprint,
                ...indexes.map((e) => e.toBytes(Endian.little)).expand((e) => e)
              ])));
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT bip32 derivation path data.");
  }
  factory PsbtOutputBip32DerivationPath.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtOutputTypes.bip32DerivationPath.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT bip32 derivation path type flag");
    }
    if (keypair.key.extraData == null ||
        !Secp256k1PublicKey.isValidBytes(keypair.key.extraData!)) {
      throw DartBitcoinPluginException(
          "Invalid PSBT bip32 derivation public key.");
    }
    if (keypair.value.data.length < Bip32KeyDataConst.fingerprintByteLen ||
        keypair.value.data.length % Bip32KeyDataConst.keyIndexByteLen != 0) {
      throw DartBitcoinPluginException(
          "Invalid PSBT bip32 derivation fingerprint or bip32 index.");
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
          Secp256k1PublicKey.isValidBytes(keypair.key.extraData!)) {
        return PsbtOutputBip32DerivationPath._(
            fingerprint: fingerPrint,
            indexes: bip32Indexes,
            publicKey: keypair.key.extraData!,
            keyPair: keypair);
      }
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT bip32 derivation indexes.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "fingerprint": BytesUtils.toHexString(fingerprint),
      "indexes": indexes.map((e) => e.index).toList(),
      "public_key": BytesUtils.toHexString(publicKey)
    };
  }
}

class PsbtOutputAmount extends PsbtOutputData {
  /// 64 bit signed little endian integer representing the output's amount in satoshis.
  final BigInt amount;
  PsbtOutputAmount._({required BigInt amount, required super.keyPair})
      : amount = amount.asInt64,
        super(type: PsbtOutputTypes.amount);
  factory PsbtOutputAmount(BigInt amount) {
    return PsbtOutputAmount._(
        amount: amount,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtOutputTypes.amount.flag!),
            value: PsbtValue(
                BigintUtils.toBytes(amount, length: 8, order: Endian.little))));
  }
  factory PsbtOutputAmount.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtOutputTypes.amount.flag) {
      throw DartBitcoinPluginException("Invalid PSBT Output Amount type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException("Invalid PSBT Output Amount key data.");
    }
    try {
      if (keypair.value.data.length == 8) {
        final amount = BigintUtils.fromBytes(keypair.value.data,
            byteOrder: Endian.little, sign: true);
        return PsbtOutputAmount._(amount: amount, keyPair: keypair);
      }
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Output Amount data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "amount": amount.toString()};
  }
}

class PsbtOutputScript extends PsbtOutputData {
  /// The script for this output, also known as the scriptPubKey. Must be omitted in PSBTv0.
  /// Must be provided in PSBTv2 if not sending to a BIP352 silent payment address, otherwise may be omitted.
  final Script script;
  PsbtOutputScript._({required this.script, required super.keyPair})
      : super(type: PsbtOutputTypes.script);
  factory PsbtOutputScript(Script script) {
    return PsbtOutputScript._(
        script: script,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtOutputTypes.script.flag!),
            value: PsbtValue(script.toBytes())));
  }

  factory PsbtOutputScript.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtOutputTypes.script.flag) {
      throw DartBitcoinPluginException("Invalid PSBT Output Script type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException("Invalid PSBT Output Script key data.");
    }
    try {
      return PsbtOutputScript._(
          script: Script.deserialize(bytes: keypair.value.data),
          keyPair: keypair);
    } catch (_) {
      throw DartBitcoinPluginException("Invalid PSBT Output Script data.");
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "script": script.toJson()};
  }
}

class PsbtOutputTaprootInternalKey extends PsbtOutputData {
  /// The X-only pubkey used as the internal key in this output.
  final List<int> xOnlyPubKey;
  PsbtOutputTaprootInternalKey._(
      {required List<int> xOnlyPubKey, required super.keyPair})
      : xOnlyPubKey = xOnlyPubKey.asImmutableBytes,
        super(type: PsbtOutputTypes.taprootInternalKey);
  factory PsbtOutputTaprootInternalKey(List<int> xOnlyPubKey) {
    if (xOnlyPubKey.length == EcdsaKeysConst.pointCoordByteLen) {
      return PsbtOutputTaprootInternalKey._(
          xOnlyPubKey: xOnlyPubKey,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtOutputTypes.taprootInternalKey.flag!),
              value: PsbtValue(xOnlyPubKey)));
    }
    throw DartBitcoinPluginException("Invalid Taproot Internal Key data");
  }

  factory PsbtOutputTaprootInternalKey.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtOutputTypes.taprootInternalKey.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Internal Key type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Internal Key data.");
    }
    try {
      if (keypair.value.data.length == EcdsaKeysConst.pointCoordByteLen) {
        return PsbtOutputTaprootInternalKey._(
            xOnlyPubKey: keypair.value.data, keyPair: keypair);
      }
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Taproot Internal Key data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "xOnlyPubKey": BytesUtils.toHexString(xOnlyPubKey)
    };
  }
}

class PsbtOutputTaprootTree extends PsbtOutputData {
  /// One or more tuples representing the depth, leaf version, and script for a leaf in the Taproot tree,
  /// allowing the entire tree to be reconstructed. The tuples must be in depth first search
  /// order so that the tree is correctly reconstructed. Each tuple is an 8-bit unsigned
  /// integer representing the depth in the Taproot tree for this script, an 8-bit
  /// unsigned integer representing the leaf version, the length of the script
  /// as a compact size unsigned integer, and the script itself.
  final List<PsbtTapTree> taprootTrees;
  factory PsbtOutputTaprootTree(List<PsbtTapTree> taprootTrees) {
    return PsbtOutputTaprootTree._(
        taprootTrees: taprootTrees,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtOutputTypes.taprootTree.flag!),
            value: PsbtValue(taprootTrees
                .map((e) => e.serialize())
                .expand((e) => e)
                .toList())));
  }
  PsbtOutputTaprootTree._(
      {required List<PsbtTapTree> taprootTrees, required super.keyPair})
      : taprootTrees = taprootTrees.immutable,
        super(type: PsbtOutputTypes.taprootTree);

  factory PsbtOutputTaprootTree.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtOutputTypes.taprootTree.flag) {
      throw DartBitcoinPluginException("Invalid PSBT Taproot Tree type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException("Invalid PSBT Taproot Tree Key data.");
    }
    List<PsbtTapTree> taprootTrees = [];
    try {
      int offset = 0;
      final data = keypair.value.data;
      while (offset < data.length) {
        final depth = data[offset++];
        final leafVersion = data[offset++];
        final scriptLength = IntUtils.decodeVarint(data.sublist(offset));
        offset += scriptLength.item2;
        final script = Script.deserialize(
            bytes: data.sublist(offset, offset + scriptLength.item1));
        final tree =
            PsbtTapTree(depth: depth, leafVersion: leafVersion, script: script);
        taprootTrees.add(tree);
        offset += scriptLength.item1;
      }
      return PsbtOutputTaprootTree._(
          taprootTrees: taprootTrees, keyPair: keypair);
    } catch (_) {
      throw DartBitcoinPluginException(
          "Invalid Invalid PSBT Taproot Tree data.");
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "tree": taprootTrees.map((e) => e.toJson()).toList()
    };
  }
}

class PsbtOutputTaprootKeyBip32DerivationPath extends PsbtOutputData {
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
  final List<Bip32KeyIndex> derivationIndexes;

  String get path {
    return Bip32Path(elems: derivationIndexes).toString();
  }

  PsbtOutputTaprootKeyBip32DerivationPath._(
      {required List<int> xOnlyPubKey,
      required List<List<int>> leavesHashes,
      required List<int> fingerprint,
      required List<Bip32KeyIndex> derivationIndexes,
      required super.keyPair})
      : leavesHashes =
            leavesHashes.map((e) => e.asImmutableBytes).toImutableList,
        fingerprint = fingerprint.asImmutableBytes,
        derivationIndexes = derivationIndexes.immutable,
        xOnlyPubKey = xOnlyPubKey.asImmutableBytes,
        super(type: PsbtOutputTypes.taprootBip32Derivation);
  factory PsbtOutputTaprootKeyBip32DerivationPath(
      {required List<int> xOnlyPubKey,
      required List<List<int>> leavesHashes,
      required List<int> fingerprint,
      required List<Bip32KeyIndex> derivationIndexes}) {
    if (fingerprint.length == Bip32KeyDataConst.fingerprintByteLen &&
        xOnlyPubKey.length == EcdsaKeysConst.pointCoordByteLen &&
        leavesHashes.every(
            (element) => element.length == QuickCrypto.sha256DigestSize)) {
      return PsbtOutputTaprootKeyBip32DerivationPath._(
          xOnlyPubKey: xOnlyPubKey,
          leavesHashes: leavesHashes,
          fingerprint: fingerprint,
          derivationIndexes: derivationIndexes,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtOutputTypes.taprootBip32Derivation.flag!,
                  extraData: xOnlyPubKey),
              value: PsbtValue([
                ...IntUtils.encodeVarint(leavesHashes.length),
                ...leavesHashes.expand((e) => e),
                ...fingerprint,
                ...derivationIndexes
                    .map((e) => e.toBytes(Endian.little))
                    .expand((e) => e)
              ])));
    }
    throw DartBitcoinPluginException(
        "Invalid Taproot Key BIP 32 Derivation Path key data.");
  }
  factory PsbtOutputTaprootKeyBip32DerivationPath.deserialize(
      PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtOutputTypes.taprootBip32Derivation.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Taproot Key BIP 32 Derivation Path type flag");
    }
    if (keypair.key.extraData?.length != QuickCrypto.sha256DigestSize) {
      throw DartBitcoinPluginException(
          "Invalid Taproot Key BIP 32 Derivation Path key data.");
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
            keypair.key.extraData?.length == EcdsaKeysConst.pointCoordByteLen &&
            leavesHashes.every(
                (element) => element.length == QuickCrypto.sha256DigestSize)) {
          return PsbtOutputTaprootKeyBip32DerivationPath._(
              leavesHashes: leavesHashes,
              fingerprint: fingerprint,
              derivationIndexes: indexes,
              xOnlyPubKey: keypair.key.extraData!,
              keyPair: keypair);
        }
      }
    } catch (_) {}

    throw DartBitcoinPluginException(
        "Invalid Taproot Key BIP 32 Derivation Path data.");
  }

  factory PsbtOutputTaprootKeyBip32DerivationPath.fromBip32(
      {required Bip32Slip10Secp256k1 masterKey,
      required String path,
      TaprootTree? treeScript}) {
    final derive = masterKey.derivePath(path);
    final indexes = Bip32PathParser.parse(path).elems;
    return PsbtOutputTaprootKeyBip32DerivationPath(
      fingerprint: derive.fingerPrint.toBytes(),
      derivationIndexes: indexes,
      xOnlyPubKey: derive.publicKey.point.cast<ProjectiveECCPoint>().toXonly(),
      leavesHashes: treeScript == null
          ? []
          : TaprootUtils.extractLeafs(treeScript).map((e) => e.hash()).toList(),
    );
  }
  BipOrTaprootKeyDerivationRequest toKeyDerivation() {
    return BipOrTaprootKeyDerivationRequest(
        pubKeyOrXonly: xOnlyPubKey,
        indexes: derivationIndexes,
        fingerprint: fingerprint,
        leavesHashes: leavesHashes);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "xOnlyPubKey": BytesUtils.toHexString(xOnlyPubKey),
      "leavesHashes":
          leavesHashes.map((e) => BytesUtils.toHexString(e)).toList(),
      "fingerprint": BytesUtils.toHexString(fingerprint),
      "derivationIndexes": derivationIndexes.map((e) => e.index).toList()
    };
  }
}

class PsbtOutputMuSig2ParticipantPublicKeys extends PsbtOutputData {
  /// The MuSig2 aggregate plain public key from the KeyAgg algorithm. This key may or may not be in the script directly.
  /// It may instead be a parent public key from which the public keys in the script were derived.
  final List<int> aggregatePubKey;

  /// A list of the compressed public keys of the participants in the MuSig2 aggregate key in the order
  /// required for aggregation. If sorting was done, then the keys must be in the sorted order.
  final List<List<int>> pubKeys;
  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "aggregatePubKey": BytesUtils.toHexString(aggregatePubKey),
      "pubKeys": pubKeys.map((e) => BytesUtils.toHexString(e)).toList()
    };
  }

  PsbtOutputMuSig2ParticipantPublicKeys._(
      {required List<int> aggregatePubKey,
      required List<List<int>> pubKeys,
      required super.keyPair})
      : aggregatePubKey = aggregatePubKey.asImmutableBytes,
        pubKeys = pubKeys.map((e) => e.asImmutableBytes).toImutableList,
        super(type: PsbtOutputTypes.muSig2ParticipantPublicKeys);
  factory PsbtOutputMuSig2ParticipantPublicKeys(
      {required List<int> aggregatePubKey, required List<List<int>> pubKeys}) {
    if (Secp256k1PublicKey.isValidBytes(aggregatePubKey) &&
        pubKeys.every(Secp256k1PublicKey.isValidBytes)) {
      return PsbtOutputMuSig2ParticipantPublicKeys._(
          aggregatePubKey: aggregatePubKey,
          pubKeys: pubKeys,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtOutputTypes.muSig2ParticipantPublicKeys.flag!,
                  extraData: aggregatePubKey),
              value: PsbtValue(pubKeys.expand((e) => e).toList())));
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT MuSig2 Participant Public Keys data");
  }
  factory PsbtOutputMuSig2ParticipantPublicKeys.deserialize(
      PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtOutputTypes.muSig2ParticipantPublicKeys.flag) {
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
          final List<List<int>> pubKeys = [];
          for (int i = 0; i < pubkeysLength; i++) {
            final int offset = i * EcdsaKeysConst.pubKeyCompressedByteLen;
            final key = pubKeysData.sublist(
                offset, offset + EcdsaKeysConst.pubKeyCompressedByteLen);
            pubKeys.add(key);
          }
          if (Secp256k1PublicKey.isValidBytes(keypair.key.extraData!) &&
              pubKeys.every(Secp256k1PublicKey.isValidBytes)) {
            return PsbtOutputMuSig2ParticipantPublicKeys._(
                aggregatePubKey: keypair.key.extraData!,
                pubKeys: pubKeys,
                keyPair: keypair);
          }
        }
      } catch (_) {}
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT MuSig2 Participant Public Keys data");
  }
}

class PsbtOutputSilentPaymentData extends PsbtOutputData {
  /// The scan and spend public keys from the silent payments address.
  final List<int> scanKey;
  final List<int> spendKey;

  PsbtOutputSilentPaymentData._(
      {required List<int> scanKey,
      required List<int> spendKey,
      required super.keyPair})
      : scanKey = scanKey.asImmutableBytes,
        spendKey = spendKey.asImmutableBytes,
        super(type: PsbtOutputTypes.silentPaymentData);
  factory PsbtOutputSilentPaymentData(
      {required List<int> scanKey, required List<int> spendKey}) {
    if (scanKey.length == EcdsaKeysConst.pubKeyCompressedByteLen &&
        spendKey.length == EcdsaKeysConst.pubKeyCompressedByteLen) {
      return PsbtOutputSilentPaymentData._(
          scanKey: scanKey,
          spendKey: spendKey,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtOutputTypes.silentPaymentData.flag!),
              value: PsbtValue([...scanKey, ...spendKey])));
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT Silent Payment Input ECDH Share data");
  }
  factory PsbtOutputSilentPaymentData.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtOutputTypes.silentPaymentData.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Silent Payment Data type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Silent Payment Data key data.");
    }
    try {
      if (keypair.value.data.length ==
          (EcdsaKeysConst.pubKeyCompressedByteLen * 2)) {
        return PsbtOutputSilentPaymentData._(
            scanKey: keypair.value.data
                .sublist(0, EcdsaKeysConst.pubKeyCompressedByteLen),
            spendKey: keypair.value.data
                .sublist(EcdsaKeysConst.pubKeyCompressedByteLen),
            keyPair: keypair);
      }
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Silent Payment Data data");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "scanKey": BytesUtils.toHexString(scanKey),
      "spendKey": BytesUtils.toHexString(spendKey)
    };
  }
}

class PsbtOutputSilentPaymentLabel extends PsbtOutputData {
  /// The label to use to compute the spend key of the silent payments address to verify change.
  final int label;
  factory PsbtOutputSilentPaymentLabel(int label) {
    return PsbtOutputSilentPaymentLabel._(
        label: label,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtOutputTypes.silentPaymentLabel.flag!),
            value: PsbtValue(
                IntUtils.toBytes(label, length: 4, byteOrder: Endian.little))));
  }
  PsbtOutputSilentPaymentLabel._({required int label, required super.keyPair})
      : label = label.asUint32,
        super(type: PsbtOutputTypes.silentPaymentLabel);
  factory PsbtOutputSilentPaymentLabel.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtOutputTypes.silentPaymentLabel.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Silent Payment Label type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Silent Payment Label key data.");
    }
    try {
      if (keypair.value.data.length == 4) {
        final int label =
            IntUtils.fromBytes(keypair.value.data, byteOrder: Endian.little);
        return PsbtOutputSilentPaymentLabel._(label: label, keyPair: keypair);
      }
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Silent Payment Label data");
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "label": label};
  }
}

class PsbtOutputBIP353DNSSECProof extends PsbtOutputData {
  /// A BIP 353 human-readable name (without the ₿ prefix), prefixed by a 1-byte length.
  /// Followed by an RFC 9102 DNSSEC AuthenticationChain (i.e. a series of DNS
  /// Resource Records in no particular order) providing a DNSSEC proof to a BIP 353 DNS TXT record.
  final String name;
  final List<int> proof;

  PsbtOutputBIP353DNSSECProof._(
      {required List<int> proof, required this.name, required super.keyPair})
      : proof = proof.asImmutableBytes,
        super(type: PsbtOutputTypes.bip353DNSSECProof);
  factory PsbtOutputBIP353DNSSECProof(
      {required List<int> proof, required String name}) {
    final lenBytes = StringUtils.encode(name).length;
    if (lenBytes > 255) {
      throw DartBitcoinPluginException("The provided name is too large.");
    }
    return PsbtOutputBIP353DNSSECProof._(
        proof: proof,
        name: name,
        keyPair: () {
          final nameBytes = StringUtils.encode(name);
          return PsbtKeyPair(
              key: PsbtKey(PsbtOutputTypes.bip353DNSSECProof.flag!),
              value: PsbtValue([nameBytes.length, ...nameBytes, ...proof]));
        }());
  }
  factory PsbtOutputBIP353DNSSECProof.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtOutputTypes.bip353DNSSECProof.flag) {
      throw DartBitcoinPluginException(
          "Invalid BIP 353 DNSSEC proof type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid BIP 353 DNSSEC proof key data.");
    }
    try {
      final int nameLength = keypair.value.data[0];
      final name =
          StringUtils.decode(keypair.value.data.sublist(1, nameLength));
      final proof = keypair.value.data.sublist(1 + nameLength);
      return PsbtOutputBIP353DNSSECProof._(
          proof: proof, name: name, keyPair: keypair);
    } on DartBitcoinPluginException {
      rethrow;
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid BIP 353 DNSSEC proof data");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "name": name,
      "proof": BytesUtils.toHexString(proof)
    };
  }
}

class PsbtOutputProprietaryUseType extends PsbtOutputData {
  /// Compact size unsigned integer of the length of the identifier,
  /// followed by identifier prefix, followed by a compact size unsigned
  /// integer subtype, followed by the key data itself.
  final List<int> identifier;
  final List<int> subkeydata;

  /// Any value data as defined by the proprietary type user.
  final List<int> data;

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "subkeydata": BytesUtils.toHexString(subkeydata),
      "identifier": BytesUtils.toHexString(identifier),
      "data": BytesUtils.toHexString(data),
    };
  }

  factory PsbtOutputProprietaryUseType(
      {required List<int> identifier,
      required List<int> subkeydata,
      required List<int> data}) {
    return PsbtOutputProprietaryUseType._(
        identifier: identifier,
        subkeydata: subkeydata,
        data: data,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtOutputTypes.proprietaryUseType.flag!, extraData: [
              ...IntUtils.prependVarint(identifier),
              ...IntUtils.prependVarint(subkeydata)
            ]),
            value: PsbtValue(data)));
  }
  PsbtOutputProprietaryUseType._(
      {required List<int> identifier,
      required List<int> subkeydata,
      required List<int> data,
      required super.keyPair})
      : identifier = identifier.asImmutableBytes,
        subkeydata = subkeydata.asImmutableBytes,
        data = data.asImmutableBytes,
        super(type: PsbtOutputTypes.proprietaryUseType);

  factory PsbtOutputProprietaryUseType.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtOutputTypes.proprietaryUseType.flag) {
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
      return PsbtOutputProprietaryUseType._(
          identifier: identifier,
          subkeydata: subkeydata,
          data: keypair.value.data,
          keyPair: keypair);
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Proprietary Use Type data");
  }
}

class PsbtOutputUnknow extends PsbtOutputData {
  PsbtOutputUnknow._(PsbtKeyPair keyPair)
      : super(type: PsbtOutputTypes.unknown, keyPair: keyPair);
  factory PsbtOutputUnknow(PsbtKeyPair keyPair) {
    return PsbtOutputUnknow._(keyPair);
  }

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
