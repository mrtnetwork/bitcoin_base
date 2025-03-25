import 'dart:typed_data';

import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'script.dart';

/// A transaction input requires a transaction id of a UTXO and the index of that UTXO.
///
/// [txId] the transaction id as a hex string
/// [txIndex] the index of the UTXO that we want to spend
/// [scriptSig] the script that satisfies the locking conditions
/// [sequence] the input sequence (for timelocks, RBF, etc.)
class TxInput {
  TxInput._(
      {required this.txId,
      required this.txIndex,
      Script? scriptSig,
      List<int>? sequance})
      : sequence =
            (sequance ?? BitcoinOpCodeConst.defaultTxSequence).asImmutableBytes,
        scriptSig = scriptSig ?? Script(script: []);
  factory TxInput(
      {required String txId,
      required int txIndex,
      Script? scriptSig,
      List<int>? sequance}) {
    if (sequance != null &&
        sequance.length != BitcoinOpCodeConst.sequenceLengthInBytes) {
      throw DartBitcoinPluginException(
          "Invalid sequence length: expected ${BitcoinOpCodeConst.sequenceLengthInBytes}, but got ${sequance.length}.");
    }
    final txBytes = BytesUtils.tryFromHexString(txId);
    if (txBytes?.length != QuickCrypto.sha256DigestSize) {
      throw DartBitcoinPluginException(
          "Invalid transaction ID: Expected ${QuickCrypto.sha256DigestSize} bytes, but received a different length.",
          details: {"transactionID": txId});
    }
    return TxInput._(
        txId: StringUtils.strip0x(txId.toLowerCase()),
        txIndex: txIndex,
        sequance: sequance,
        scriptSig: scriptSig);
  }
  TxInput copyWith(
      {String? txId, int? txIndex, Script? scriptSig, List<int>? sequence}) {
    return TxInput(
        txId: txId ?? this.txId,
        txIndex: txIndex ?? this.txIndex,
        scriptSig: scriptSig ?? this.scriptSig,
        sequance: sequence ?? this.sequence);
  }

  final String txId;
  final int txIndex;
  Script scriptSig;
  List<int> sequence;

  /// creates a copy of the object
  TxInput clone() {
    return TxInput(
        txId: txId, txIndex: txIndex, scriptSig: scriptSig, sequance: sequence);
  }

  /// serializes TxInput to bytes
  List<int> toBytes() {
    final txidBytes = BytesUtils.fromHexString(txId).reversed.toList();
    final txoutBytes =
        IntUtils.toBytes(txIndex, length: 4, byteOrder: Endian.little);
    final scriptSigBytes = scriptSig.toBytes();
    final scriptSigLengthVarint = IntUtils.encodeVarint(scriptSigBytes.length);
    final data = List<int>.from([
      ...txidBytes,
      ...txoutBytes,
      ...scriptSigLengthVarint,
      ...scriptSigBytes,
      ...sequence
    ]);
    return data;
  }

  static Tuple<TxInput, int> deserialize(
      {required List<int> bytes, int cursor = 0}) {
    final inpHash = bytes.sublist(cursor, cursor + 32).reversed.toList();
    cursor += 32;
    final outputN = IntUtils.fromBytes(bytes.sublist(cursor, cursor + 4),
        byteOrder: Endian.little);
    cursor += 4;
    final vi = IntUtils.decodeVarint(bytes.sublist(cursor));
    cursor += vi.item2;
    final unlockingScript = bytes.sublist(cursor, cursor + vi.item1);
    cursor += vi.item1;
    final sequenceNumberData = bytes.sublist(cursor, cursor + 4);
    cursor += 4;
    return Tuple(
        TxInput(
            txId: BytesUtils.toHexString(inpHash),
            txIndex: outputN,
            scriptSig: Script.deserialize(bytes: unlockingScript),
            sequance: sequenceNumberData),
        cursor);
  }

  List<int> txIdBytes() {
    return BytesUtils.fromHexString(txId).reversed.toList();
  }

  int sequenceAsNumber() {
    return IntUtils.fromBytes(sequence, byteOrder: Endian.little);
  }

  Map<String, dynamic> toJson() {
    return {
      'txid': txId,
      'txIndex': txIndex,
      'scriptSig': scriptSig.toJson(),
      'sequance': BytesUtils.toHexString(sequence),
    };
  }

  @override
  String toString() {
    return 'TxInput{txId: $txId, txIndex: $txIndex, scriptSig: $scriptSig, sequence: ${BytesUtils.toHexString(sequence)}}';
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! TxInput) return false;
    return txIndex == other.txIndex &&
        txId == other.txId &&
        BytesUtils.bytesEqual(sequence, other.sequence);
  }

  @override
  int get hashCode =>
      HashCodeGenerator.generateHashCode([txIndex, txId, sequence]);
}
