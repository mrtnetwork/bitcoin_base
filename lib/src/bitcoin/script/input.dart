import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'script.dart';

/// A transaction input requires a transaction id of a UTXO and the index of that UTXO.
///
/// [txId] the transaction id as a hex string
/// [txIndex] the index of the UTXO that we want to spend
/// [scriptSig] the script that satisfies the locking conditions
/// [sequence] the input sequence (for timelocks, RBF, etc.)
class TxInput {
  TxInput(
      {required this.txId,
      required this.txIndex,
      Script? scriptSig,
      List<int>? sequance})
      : sequence = List.unmodifiable(
            sequance ?? BitcoinOpCodeConst.DEFAULT_TX_SEQUENCE),
        scriptSig = scriptSig ?? Script(script: []);
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
  TxInput copy() {
    return TxInput(
        txId: txId, txIndex: txIndex, scriptSig: scriptSig, sequance: sequence);
  }

  /// serializes TxInput to bytes
  List<int> toBytes() {
    final txidBytes = BytesUtils.fromHexString(txId).reversed.toList();

    final txoutBytes = List<int>.filled(4, 0);
    writeUint32LE(txIndex, txoutBytes);
    final scriptSigBytes = scriptSig.toBytes();

    final scriptSigLengthVarint = IntUtils.encodeVarint(scriptSigBytes.length);
    final data = List<int>.from([
      ...txidBytes,
      ...txoutBytes,
      ...scriptSigLengthVarint,
      ...scriptSigBytes,
      ...sequence,
    ]);
    return data;
  }

  static Tuple<TxInput, int> fromRaw(
      {required String raw, int cursor = 0, bool hasSegwit = false}) {
    final txInputRaw = BytesUtils.fromHexString(raw);
    List<int> inpHash =
        txInputRaw.sublist(cursor, cursor + 32).reversed.toList();
    if (inpHash.isEmpty) {
      throw const BitcoinBasePluginException(
          "Input transaction hash not found. Probably malformed raw transaction");
    }
    List<int> outputN =
        txInputRaw.sublist(cursor + 32, cursor + 36).reversed.toList();
    cursor += 36;
    final vi = IntUtils.decodeVarint(txInputRaw.sublist(cursor, cursor + 9));
    cursor += vi.item2;
    List<int> unlockingScript = txInputRaw.sublist(cursor, cursor + vi.item1);
    cursor += vi.item1;
    List<int> sequenceNumberData = txInputRaw.sublist(cursor, cursor + 4);
    cursor += 4;
    return Tuple(
        TxInput(
            txId: BytesUtils.toHexString(inpHash),
            txIndex: int.parse(BytesUtils.toHexString(outputN), radix: 16),
            scriptSig: Script.fromRaw(
                hexData: BytesUtils.toHexString(unlockingScript),
                hasSegwit: hasSegwit),
            sequance: sequenceNumberData),
        cursor);
  }

  @override
  String toString() {
    return "TxInput{txId: $txId, txIndex: $txIndex, scriptSig: $scriptSig, sequence: ${BytesUtils.toHexString(sequence)}}";
  }
}
