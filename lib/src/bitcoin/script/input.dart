import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:blockchain_utils/binary/binary_operation.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/numbers/int_utils.dart';
import 'script.dart';

/// A transaction input requires a transaction id of a UTXO and the index of that UTXO.
///
/// [txId] the transaction id as a hex string
/// [txIndex] the index of the UTXO that we want to spend
/// [scriptSig] the script that satisfies the locking conditions
/// [sequence] the input sequence (for timelocks, RBF, etc.)
class TxInput {
  TxInput(
      {required this.txId, required this.txIndex, Script? sig, List<int>? sq})
      : sequence = sq ?? BitcoinOpCodeConst.DEFAULT_TX_SEQUENCE,

        /// ignore: prefer_const_constructors
        scriptSig = sig ?? Script(script: []);
  final String txId;
  final int txIndex;
  Script scriptSig;
  List<int> sequence;

  /// creates a copy of the object
  TxInput copy() {
    return TxInput(txId: txId, txIndex: txIndex, sig: scriptSig, sq: sequence);
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

  static (TxInput, int) fromRaw(
      {required String raw, int cursor = 0, bool hasSegwit = false}) {
    final txInputRaw = BytesUtils.fromHexString(raw);
    List<int> inpHash =
        txInputRaw.sublist(cursor, cursor + 32).reversed.toList();
    if (inpHash.isEmpty) {
      throw ArgumentError(
          "Input transaction hash not found. Probably malformed raw transaction");
    }
    List<int> outputN =
        txInputRaw.sublist(cursor + 32, cursor + 36).reversed.toList();
    cursor += 36;
    final vi = IntUtils.decodeVarint(txInputRaw.sublist(cursor, cursor + 9));
    cursor += vi.$2;
    List<int> unlockingScript = txInputRaw.sublist(cursor, cursor + vi.$1);
    cursor += vi.$1;
    List<int> sequenceNumberData = txInputRaw.sublist(cursor, cursor + 4);
    cursor += 4;
    return (
      TxInput(
          txId: BytesUtils.toHexString(inpHash),
          txIndex: int.parse(BytesUtils.toHexString(outputN), radix: 16),
          sig: Script.fromRaw(
              hexData: BytesUtils.toHexString(unlockingScript),
              hasSegwit: hasSegwit),
          sq: sequenceNumberData),
      cursor
    );
  }
}
