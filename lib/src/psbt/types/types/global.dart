import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/bitcoin/script/transaction.dart';
import 'package:bitcoin_base/src/psbt/types/types/psbt.dart';
import 'dart:typed_data';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// PSBT GLOBAL TYPES
enum PsbtGlobalTypes {
  unsignedTx(0x00, "PSBT_GLOBAL_UNSIGNED_TX",
      allowedVersion: PsbtVersion.v0, required: true),
  xpub(0x01, "PSBT_GLOBAL_XPUB"),
  version(0x02, "PSBT_GLOBAL_TX_VERSION",
      allowedVersion: PsbtVersion.v2, required: true),
  fallBackLockTime(0x03, "PSBT_GLOBAL_FALLBACK_LOCKTIME",
      allowedVersion: PsbtVersion.v2),
  inputCount(0x04, "PSBT_GLOBAL_INPUT_COUNT",
      allowedVersion: PsbtVersion.v2, required: true),
  outputCount(0x05, "PSBT_GLOBAL_OUTPUT_COUNT",
      allowedVersion: PsbtVersion.v2, required: true),
  txModifiable(0x06, "PSBT_GLOBAL_TX_MODIFIABLE",
      allowedVersion: PsbtVersion.v2),
  spEcdhShare(0x07, "PSBT_GLOBAL_SP_ECDH_SHARE",
      allowedVersion: PsbtVersion.v2),
  spDLEQ(0x08, "PSBT_GLOBAL_SP_DLEQ", allowedVersion: PsbtVersion.v2),
  psbtVersion(0xFB, "PSBT_GLOBAL_VERSION"),
  proprietary(0xFC, "PSBT_GLOBAL_PROPRIETARY"),
  unknown(null, "PSBT_GLOBAL_UNKNOWN");

  const PsbtGlobalTypes(this.flag, this.psbtName,
      {this.allowedVersion, this.required = false});

  final int? flag;
  final String psbtName;
  final bool required;
  final PsbtVersion? allowedVersion;
  static PsbtGlobalTypes find(int flag) {
    final type = values.firstWhereNullable((e) => e.flag == flag);
    if (type != null) return type;
    return unknown;
  }
}

/// Represents the global section of a PSBT (Partially Signed Bitcoin Transaction).
class PsbtGlobal {
  /// The list of global PSBT entries.
  List<PsbtGlobalData> _entries;
  List<PsbtGlobalData> get entries => _entries;

  /// The PSBT version associated with this global section.
  final PsbtVersion version;

  PsbtGlobal._({List<PsbtGlobalData> entries = const [], required this.version})
      : _entries = entries.immutable;

  /// Constructs a [PsbtGlobal] instance with a given version and global entries.
  ///
  /// Throws a [DartBitcoinPluginException] if any of the following conditions are met:
  /// - Duplicate entries are found.
  /// - A global entry is not allowed for the specified PSBT version.
  /// - A required global entry is missing for the PSBT version
  factory PsbtGlobal(
      {List<PsbtGlobalData> entries = const [], required PsbtVersion version}) {
    final keys = entries.map((e) => e.keyPair.key).toList();
    if (keys.toSet().length != keys.length) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Global: Duplicate entry detected.");
    }
    for (final i in entries) {
      if (i.type.allowedVersion == null) continue;
      if (version != i.type.allowedVersion) {
        throw DartBitcoinPluginException(
            "Invalid PSBT Global: ${i.type.psbtName} is not allowed in PSBT version ${version.name}.");
      }
    }
    final requiredFilds = PsbtGlobalTypes.values.where((e) =>
        e.required &&
        (e.allowedVersion == null || e.allowedVersion == version));
    for (final i in requiredFilds) {
      entries.firstWhere((e) => e.type == i,
          orElse: () => throw DartBitcoinPluginException(
              "Invalid PSBT global: Missing required field ${i.psbtName} for PSBT version ${version.name}."));
    }
    return PsbtGlobal._(version: version, entries: entries);
  }

  /// Creates a [PsbtGlobal] instance from a list of key pairs.
  factory PsbtGlobal.fromKeyPairs(
      {List<PsbtKeyPair> keypairs = const [], required PsbtVersion version}) {
    final inputs = keypairs.map(PsbtGlobalData.deserialize).toList();
    return PsbtGlobal(entries: inputs, version: version);
  }

  /// Converts the entries to a list of key pairs.
  List<PsbtKeyPair> toKeyPairs() {
    return _entries.map((e) => e.keyPair).toList();
  }

  /// Converts the entries to json.
  Map<String, dynamic> toJson() {
    return {"entries": entries.map((e) => e.toJson()).toList()};
  }

  /// Validates if the provided entries is not duplicate and allowed by the PSBT version.
  void _itemsAllowed(List<PsbtGlobalData> items) {
    final keys = items.map((e) => e.keyPair.key).toSet();
    if (keys.length != items.length) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Global: Duplicate entry detected.");
    }
    for (final i in items) {
      if (i.type.allowedVersion == null) continue;
      if (version != i.type.allowedVersion) {
        throw DartBitcoinPluginException(
            "Invalid PSBT Global: ${i.type.psbtName} is not allowed in PSBT version ${version.name}.");
      }
    }
  }

  /// Updates the entries with new data.
  void updateGlobals(List<PsbtGlobalData> data) {
    final entries = _entries.clone();
    for (final i in data) {
      entries.removeWhere((e) => e.type == i.type);
      entries.add(i);
    }
    _itemsAllowed(entries);
    _entries = entries.immutable;
  }

  /// Retrieves a single entry of a specified type.
  T? getGlobal<T extends PsbtGlobalData>(PsbtGlobalTypes type) {
    final data = _entries.where((e) => e.type == type);
    if (data.isEmpty) return null;
    if (data.length != 1) {
      throw DartBitcoinPluginException(
          "Multiple globals with type ${type.psbtName} found. Use 'getGlobals' to retrieve data for multiple globals");
    }
    return data.first.cast();
  }

  /// Retrieves all entries of a specified type.
  List<T>? getGlobals<T extends PsbtGlobalData>(
      int index, PsbtGlobalTypes type) {
    final data = _entries.where((e) => e.type == type);
    if (data.isEmpty) return null;
    return data.toList().cast<T>();
  }

  /// Creates a deep copy of the [PsbtGlobal] instance.
  PsbtGlobal clone() {
    return PsbtGlobal(entries: entries.clone(), version: version);
  }
}

abstract class PsbtGlobalData {
  final PsbtGlobalTypes type;
  final PsbtKeyPair keyPair;
  const PsbtGlobalData({required this.type, required this.keyPair});
  factory PsbtGlobalData.deserialize(PsbtKeyPair keypair) {
    final type = PsbtGlobalTypes.find(keypair.key.type);
    return switch (type) {
      PsbtGlobalTypes.unsignedTx =>
        PsbtGlobalUnsignedTransaction.deserialize(keypair),
      PsbtGlobalTypes.xpub => PsbtGlobalExtendedPublicKey.deserialize(keypair),
      PsbtGlobalTypes.version =>
        PsbtGlobalTransactionVersion.deserialize(keypair),
      PsbtGlobalTypes.fallBackLockTime =>
        PsbtGlobalFallbackLocktime.deserialize(keypair),
      PsbtGlobalTypes.inputCount => PsbtGlobalInputCount.deserialize(keypair),
      PsbtGlobalTypes.outputCount => PsbtGlobalOutputCount.deserialize(keypair),
      PsbtGlobalTypes.txModifiable =>
        PsbtGlobalTransactionModifiableFlags.deserialize(keypair),
      PsbtGlobalTypes.spEcdhShare =>
        PsbtGlobalSilentPaymentGlobalECDHShare.deserialize(keypair),
      PsbtGlobalTypes.spDLEQ =>
        PsbtGlobalSilentPaymentGlobalDLEQProof.deserialize(keypair),
      PsbtGlobalTypes.psbtVersion =>
        PsbtGlobalPSBTVersionNumber.deserialize(keypair),
      PsbtGlobalTypes.proprietary =>
        PsbtGlobalProprietaryUseType.deserialize(keypair),
      PsbtGlobalTypes.unknown => PsbtGlobalUnknow(keypair),
    };
  }
  T cast<T extends PsbtGlobalData>() {
    if (this is! T) {
      throw DartBitcoinPluginException(
          "Invalid cast: expected ${T.runtimeType}, but found $runtimeType.",
          details: {"expected": "$T", "type": runtimeType.toString()});
    }
    return this as T;
  }

  Map<String, dynamic> toJson();

  @override
  String toString() {
    return type.name;
  }
}

class PsbtGlobalUnsignedTransaction extends PsbtGlobalData {
  /// The transaction in network serialization. The scriptSigs and witnesses for each input must be empty.
  /// The transaction must be in the old serialization format (without witnesses).
  final BtcTransaction transaction;
  PsbtGlobalUnsignedTransaction._(
      {required this.transaction, required super.keyPair})
      : super(type: PsbtGlobalTypes.unsignedTx);
  factory PsbtGlobalUnsignedTransaction(BtcTransaction transaction) {
    return PsbtGlobalUnsignedTransaction._(
        transaction: transaction,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtGlobalTypes.unsignedTx.flag!),
            value: PsbtValue(transaction.toBytes(allowWitness: false))));
  }
  factory PsbtGlobalUnsignedTransaction.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtGlobalTypes.unsignedTx.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Unsigned Transaction type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Unsigned Transaction key data.");
    }
    try {
      final transaction =
          BtcTransaction.deserialize(keypair.value.data, allowWitness: false);
      if (transaction.witnesses.isEmpty &&
          transaction.inputs.every((e) => e.scriptSig == Script.empty)) {
        return PsbtGlobalUnsignedTransaction._(
            keyPair: keypair, transaction: transaction);
      }
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Unsigned Transaction data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "transaction": transaction.toJson()};
  }
}

class PsbtGlobalExtendedPublicKey extends PsbtGlobalData {
  /// The 78 byte serialized extended public key as defined by BIP 32.
  /// Extended public keys are those that can be used to derive public keys used in the
  /// inputs and outputs of this transaction. It should be the public key at the highest
  /// hardened derivation index so that the unhardened child keys used in the transaction can be derived.
  final List<int> xPub;

  /// The master key fingerprint as defined by BIP 32 concatenated
  /// with the derivation path of the public key. The derivation path
  /// is represented as 32-bit little endian unsigned integer indexes
  /// concatenated with each other. The number of 32 bit unsigned integer
  /// indexes must match the depth provided in the extended public key.
  final List<int> fingerprint;
  final List<Bip32KeyIndex> indexes;
  PsbtGlobalExtendedPublicKey._(
      {required List<int> xPub,
      required List<int> fingerprint,
      required List<Bip32KeyIndex> indexes,
      required super.keyPair})
      : xPub = xPub.asImmutableBytes,
        fingerprint = fingerprint.asImmutableBytes,
        indexes = indexes.immutable,
        super(type: PsbtGlobalTypes.xpub);
  factory PsbtGlobalExtendedPublicKey({
    required List<int> xPub,
    required List<int> fingerprint,
    required List<Bip32KeyIndex> indexes,
  }) {
    if (xPub.length == Bip32KeySerConst.serializedPubKeyByteLen &&
        fingerprint.length == Bip32KeyDataConst.fingerprintByteLen) {
      return PsbtGlobalExtendedPublicKey._(
          xPub: xPub,
          fingerprint: fingerprint,
          indexes: indexes,
          keyPair: () {
            final List<int> indexesBytes = indexes
                .map((e) => e.toBytes(Endian.little))
                .expand((e) => e)
                .toList();
            return PsbtKeyPair(
                key: PsbtKey(PsbtGlobalTypes.xpub.flag!, extraData: xPub),
                value: PsbtValue([...fingerprint, ...indexesBytes]));
          }());
    }
    throw DartBitcoinPluginException("Invalid PSBT Extended Public Key data.");
  }
  factory PsbtGlobalExtendedPublicKey.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtGlobalTypes.xpub.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Extended Public Key type flag");
    }

    try {
      final List<int> fingerPrint =
          keypair.value.data.sublist(0, Bip32KeyDataConst.fingerprintByteLen);
      final indexesBytes =
          keypair.value.data.sublist(Bip32KeyDataConst.fingerprintByteLen);
      final indexCount =
          indexesBytes.length ~/ Bip32KeyDataConst.keyIndexByteLen;
      final bip32Indexes = List.generate(indexCount, (i) {
        final offset = i * Bip32KeyDataConst.keyIndexByteLen;
        return Bip32KeyIndex.fromBytes(indexesBytes.sublist(
            offset, offset + Bip32KeyDataConst.keyIndexByteLen));
      });
      return PsbtGlobalExtendedPublicKey(
          xPub: keypair.key.extraData ?? [],
          fingerprint: fingerPrint,
          indexes: bip32Indexes);
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Extended Public Key data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "xPub": BytesUtils.toHexString(xPub),
      "fingerprint": BytesUtils.toHexString(fingerprint),
      "indexes": indexes.map((e) => e.index).toList()
    };
  }
}

class PsbtGlobalTransactionVersion extends PsbtGlobalData {
  /// The 32-bit little endian signed integer representing the
  /// version number of the transaction being created. Note that
  /// this is not the same as the PSBT version number
  /// specified by the PSBT_GLOBAL_VERSION field.
  final int version;

  PsbtGlobalTransactionVersion._({required int version, required super.keyPair})
      : version = version.asUint32,
        super(type: PsbtGlobalTypes.version);
  factory PsbtGlobalTransactionVersion(int version) {
    return PsbtGlobalTransactionVersion._(
        version: version,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtGlobalTypes.version.flag!),
            value: PsbtValue(IntUtils.toBytes(version,
                length: BitcoinOpCodeConst.versionLengthInBytes,
                byteOrder: Endian.little))));
  }
  factory PsbtGlobalTransactionVersion.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtGlobalTypes.version.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Transaction Version type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Transaction Version key data.");
    }
    if (keypair.value.data.length == BitcoinOpCodeConst.versionLengthInBytes) {
      try {
        final int version =
            IntUtils.fromBytes(keypair.value.data, byteOrder: Endian.little);
        return PsbtGlobalTransactionVersion._(
            version: version, keyPair: keypair);
      } catch (_) {}
    }

    throw DartBitcoinPluginException("Invalid PSBT Transaction Version data.");
  }

  List<int> versionBytes() {
    return IntUtils.toBytes(version,
        length: BitcoinOpCodeConst.versionLengthInBytes,
        byteOrder: Endian.little);
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "version": version};
  }
}

class PsbtGlobalFallbackLocktime extends PsbtGlobalData {
  /// The 32-bit little endian unsigned integer representing
  /// the transaction locktime to use if no inputs specify a required locktime.
  final int locktime;

  PsbtGlobalFallbackLocktime._({
    required int locktime,
    required super.keyPair,
  })  : locktime = locktime.asUint32,
        super(type: PsbtGlobalTypes.fallBackLockTime);
  factory PsbtGlobalFallbackLocktime(int locktime) {
    return PsbtGlobalFallbackLocktime._(
        locktime: locktime,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtGlobalTypes.fallBackLockTime.flag!),
            value: PsbtValue(IntUtils.toBytes(locktime,
                length: BitcoinOpCodeConst.locktimeLengthInBytes,
                byteOrder: Endian.little))));
  }
  factory PsbtGlobalFallbackLocktime.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtGlobalTypes.fallBackLockTime.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Fallback Locktime type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Fallback Locktime key data.");
    }
    if (keypair.value.data.length == BitcoinOpCodeConst.locktimeLengthInBytes) {
      try {
        final int locktime =
            IntUtils.fromBytes(keypair.value.data, byteOrder: Endian.little);
        return PsbtGlobalFallbackLocktime._(
            locktime: locktime, keyPair: keypair);
      } catch (_) {}
    }

    throw DartBitcoinPluginException("Invalid PSBT Fallback Locktime data.");
  }

  List<int> locktimeBytes() {
    return IntUtils.toBytes(locktime,
        length: BitcoinOpCodeConst.locktimeLengthInBytes,
        byteOrder: Endian.little);
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "locktime": locktime};
  }
}

class PsbtGlobalInputCount extends PsbtGlobalData {
  /// Compact size unsigned integer representing the number of inputs in this PSBT.
  final int count;
  PsbtGlobalInputCount._({required int count, required super.keyPair})
      : count = count.asUint32,
        super(type: PsbtGlobalTypes.inputCount);
  factory PsbtGlobalInputCount(int count) {
    return PsbtGlobalInputCount._(
        count: count,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtGlobalTypes.inputCount.flag!),
            value: PsbtValue(IntUtils.encodeVarint(count))));
  }
  factory PsbtGlobalInputCount.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtGlobalTypes.inputCount.flag) {
      throw DartBitcoinPluginException("Invalid PSBT Input Count type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException("Invalid PSBT Input Count key data.");
    }
    try {
      final int inputCount = IntUtils.decodeVarint(keypair.value.data).item1;
      return PsbtGlobalInputCount._(count: inputCount, keyPair: keypair);
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Input Count data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "count": count};
  }
}

class PsbtGlobalOutputCount extends PsbtGlobalData {
  /// Compact size unsigned integer representing the number of outputs in this PSBT.
  final int count;
  PsbtGlobalOutputCount._({required int count, required super.keyPair})
      : count = count.asUint32,
        super(type: PsbtGlobalTypes.outputCount);
  factory PsbtGlobalOutputCount(int count) {
    return PsbtGlobalOutputCount._(
        count: count,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtGlobalTypes.outputCount.flag!),
            value: PsbtValue(IntUtils.encodeVarint(count))));
  }
  factory PsbtGlobalOutputCount.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtGlobalTypes.outputCount.flag) {
      throw DartBitcoinPluginException("Invalid PSBT Output Count type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException("Invalid PSBT Output Count key data.");
    }
    try {
      final int outputCount = IntUtils.decodeVarint(keypair.value.data).item1;
      return PsbtGlobalOutputCount._(count: outputCount, keyPair: keypair);
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Output Count data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "count": count};
  }
}

class PsbtGlobalTransactionModifiableFlags extends PsbtGlobalData {
  /// An 8 bit little endian unsigned integer as a bitfield for various transaction modification flags.
  /// Bit 0 is the Inputs Modifiable Flag and indicates whether inputs can be modified.
  /// Bit 1 is the Outputs Modifiable Flag and indicates whether outputs can be modified.
  /// Bit 2 is the Has SIGHASH_SINGLE flag and indicates whether the transaction has a
  /// SIGHASH_SINGLE signature who's input and output pairing must be preserved.
  /// Bit 2 essentially indicates that the Constructor must iterate the inputs to determine whether and how to add an input.
  final int flags;
  PsbtGlobalTransactionModifiableFlags._(
      {required int flags, required super.keyPair})
      : flags = flags.asUint8,
        super(type: PsbtGlobalTypes.txModifiable);
  factory PsbtGlobalTransactionModifiableFlags(int flags) {
    return PsbtGlobalTransactionModifiableFlags._(
        flags: flags,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtGlobalTypes.txModifiable.flag!),
            value: PsbtValue([flags])));
  }
  factory PsbtGlobalTransactionModifiableFlags.deserialize(
      PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtGlobalTypes.txModifiable.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Transaction Modifiable Flags type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Transaction Modifiable Flags key data.");
    }
    if (keypair.value.data.length == 1) {
      return PsbtGlobalTransactionModifiableFlags._(
          flags: keypair.value.data.first, keyPair: keypair);
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT Transaction Modifiable Flags data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "flags": flags};
  }
}

class PsbtGlobalSilentPaymentGlobalECDHShare extends PsbtGlobalData {
  /// The scan key that this ECDH share is for.
  final List<int> scanKey;

  /// An ECDH share for a scan key. The ECDH shared is computed with a * B_scan,
  /// where a is the sum of all private keys of all eligible inputs, and B_scan is the scan key of a recipient.
  final List<int> share;

  PsbtGlobalSilentPaymentGlobalECDHShare._({
    required List<int> scanKey,
    required List<int> share,
    required super.keyPair,
  })  : scanKey = scanKey.asImmutableBytes,
        share = share.asImmutableBytes,
        super(type: PsbtGlobalTypes.spEcdhShare);
  factory PsbtGlobalSilentPaymentGlobalECDHShare(
      {required List<int> scanKey, required List<int> share}) {
    if (scanKey.length == EcdsaKeysConst.pubKeyCompressedByteLen &&
        share.length == EcdsaKeysConst.pubKeyCompressedByteLen) {
      return PsbtGlobalSilentPaymentGlobalECDHShare._(
          scanKey: scanKey,
          share: share,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtGlobalTypes.spEcdhShare.flag!,
                  extraData: scanKey),
              value: PsbtValue(share)));
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT Silent Payment Global ECDH Share data");
  }
  factory PsbtGlobalSilentPaymentGlobalECDHShare.deserialize(
      PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtGlobalTypes.spEcdhShare.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Silent Payment Global ECDH Share type flag");
    }
    if (keypair.key.extraData?.length ==
            EcdsaKeysConst.pubKeyCompressedByteLen &&
        keypair.value.data.length == EcdsaKeysConst.pubKeyCompressedByteLen) {
      return PsbtGlobalSilentPaymentGlobalECDHShare._(
          scanKey: keypair.key.extraData ?? [],
          share: keypair.value.data,
          keyPair: keypair);
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT Silent Payment Global ECDH Share data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "scanKey": BytesUtils.toHexString(scanKey),
      "share": BytesUtils.toHexString(share),
    };
  }
}

class PsbtGlobalSilentPaymentGlobalDLEQProof extends PsbtGlobalData {
  /// The scan key that this proof covers.
  final List<int> scanKey;

  /// A BIP374 DLEQ proof computed for the matching ECDH share.
  final List<int> proof;

  PsbtGlobalSilentPaymentGlobalDLEQProof._(
      {required List<int> scanKey,
      required List<int> proof,
      required super.keyPair})
      : scanKey = scanKey.asImmutableBytes,
        proof = proof.asImmutableBytes,
        super(type: PsbtGlobalTypes.spDLEQ);
  factory PsbtGlobalSilentPaymentGlobalDLEQProof(
      {required List<int> scanKey, required List<int> proof}) {
    if (scanKey.length == EcdsaKeysConst.pubKeyCompressedByteLen &&
        proof.length == QuickCrypto.sha512DeigestLength) {
      return PsbtGlobalSilentPaymentGlobalDLEQProof._(
          scanKey: scanKey,
          proof: proof,
          keyPair: PsbtKeyPair(
              key: PsbtKey(PsbtGlobalTypes.spDLEQ.flag!, extraData: scanKey),
              value: PsbtValue(proof)));
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT Silent Payment Global DLEQ Proof data");
  }
  factory PsbtGlobalSilentPaymentGlobalDLEQProof.deserialize(
      PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtGlobalTypes.spDLEQ.flag) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Silent Payment Global DLEQ Proof type flag");
    }
    if (keypair.key.extraData?.length ==
            EcdsaKeysConst.pubKeyCompressedByteLen &&
        keypair.value.data.length == QuickCrypto.sha512DeigestLength) {
      return PsbtGlobalSilentPaymentGlobalDLEQProof._(
          scanKey: keypair.key.extraData ?? [],
          proof: keypair.value.data,
          keyPair: keypair);
    }
    throw DartBitcoinPluginException(
        "Invalid PSBT Silent Payment Global DLEQ Proof data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "scanKey": BytesUtils.toHexString(scanKey),
      "proof": BytesUtils.toHexString(proof),
    };
  }
}

class PsbtGlobalPSBTVersionNumber extends PsbtGlobalData {
  /// The 32-bit little endian unsigned integer representing the version number of this PSBT.
  /// If omitted, the version number is 0.
  final PsbtVersion version;

  factory PsbtGlobalPSBTVersionNumber(PsbtVersion version) {
    return PsbtGlobalPSBTVersionNumber._(
        version: version,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtGlobalTypes.psbtVersion.flag!),
            value: PsbtValue(IntUtils.toBytes(version.version,
                length: BitcoinOpCodeConst.versionLengthInBytes,
                byteOrder: Endian.little))));
  }
  PsbtGlobalPSBTVersionNumber._({required this.version, required super.keyPair})
      : super(type: PsbtGlobalTypes.psbtVersion);
  factory PsbtGlobalPSBTVersionNumber.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtGlobalTypes.psbtVersion.flag) {
      throw DartBitcoinPluginException("Invalid PSBT Version Number type flag");
    }
    if (keypair.key.extraData != null) {
      throw DartBitcoinPluginException("Invalid PSBT Version Number key data.");
    }
    try {
      if (keypair.value.data.length ==
          BitcoinOpCodeConst.versionLengthInBytes) {
        final int version =
            IntUtils.fromBytes(keypair.value.data, byteOrder: Endian.little);
        return PsbtGlobalPSBTVersionNumber._(
            version: PsbtVersion.values.firstWhere(
              (e) => e.version == version,
              orElse: () => throw DartBitcoinPluginException(
                  "Unsported PSBT Version $version"),
            ),
            keyPair: keypair);
      }
    } on DartBitcoinPluginException {
      rethrow;
    } catch (_) {}
    throw DartBitcoinPluginException("Invalid PSBT Version Number data.");
  }

  @override
  Map<String, dynamic> toJson() {
    return {"type": type.name, "version": version.version};
  }
}

class PsbtGlobalProprietaryUseType extends PsbtGlobalData {
  /// Compact size unsigned integer of the length of the identifier, followed by identifier prefix,
  /// followed by a compact size unsigned integer subtype, followed by the key data itself.
  final List<int> identifier;
  final List<int> subkeydata;

  /// Any value data as defined by the proprietary type user.
  final List<int> data;

  PsbtGlobalProprietaryUseType._({
    required List<int> identifier,
    required List<int> subkeydata,
    required List<int> data,
    required super.keyPair,
  })  : identifier = identifier.asImmutableBytes,
        subkeydata = subkeydata.asImmutableBytes,
        data = data.asImmutableBytes,
        super(type: PsbtGlobalTypes.proprietary);
  factory PsbtGlobalProprietaryUseType({
    required List<int> identifier,
    required List<int> subkeydata,
    required List<int> data,
  }) {
    return PsbtGlobalProprietaryUseType._(
        identifier: identifier,
        subkeydata: subkeydata,
        data: data,
        keyPair: PsbtKeyPair(
            key: PsbtKey(PsbtGlobalTypes.proprietary.flag!, extraData: [
              ...IntUtils.prependVarint(identifier),
              ...IntUtils.prependVarint(subkeydata)
            ]),
            value: PsbtValue(data)));
  }

  factory PsbtGlobalProprietaryUseType.deserialize(PsbtKeyPair keypair) {
    if (keypair.key.type != PsbtGlobalTypes.proprietary.flag) {
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
      return PsbtGlobalProprietaryUseType._(
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

class PsbtGlobalUnknow extends PsbtGlobalData {
  PsbtGlobalUnknow._(PsbtKeyPair keyPair)
      : super(type: PsbtGlobalTypes.unknown, keyPair: keyPair);
  factory PsbtGlobalUnknow(PsbtKeyPair keyPair) {
    return PsbtGlobalUnknow._(keyPair);
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
