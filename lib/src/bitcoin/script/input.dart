import 'dart:typed_data';
import 'package:bitcoin_base/src/bitcoin/constant/constant.dart';
import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';
import 'script.dart';

/// A transaction input requires a transaction id of a UTXO and the index of that UTXO.
///
/// [txId] the transaction id as a hex string
/// [txIndex] the index of the UTXO that we want to spend
/// [scriptSig] the script that satisfies the locking conditions
/// [sequence] the input sequence (for timelocks, RBF, etc.)
class TxInput {
  TxInput(
      {required this.txId, required this.txIndex, Script? sig, Uint8List? sq})
      : sequence = sq ?? Uint8List.fromList(DEFAULT_TX_SEQUENCE),

        /// ignore: prefer_const_constructors
        scriptSig = sig ?? Script(script: []);
  final String txId;
  final int txIndex;
  Script scriptSig;
  Uint8List sequence;

  /// creates a copy of the object
  TxInput copy() {
    return TxInput(txId: txId, txIndex: txIndex, sig: scriptSig, sq: sequence);
  }

  /// serializes TxInput to bytes
  Uint8List toBytes() {
    final txidBytes = Uint16List.fromList(hexToBytes(txId).reversed.toList());

    final txoutBytes = Uint8List(4);
    ByteData.view(txoutBytes.buffer).setUint32(0, txIndex, Endian.little);

    final scriptSigBytes = scriptSig.toBytes();

    final scriptSigLengthVarint = encodeVarint(scriptSigBytes.length);
    final data = Uint8List.fromList([
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
    final txInputRaw = hexToBytes(raw);
    Uint8List inpHash = Uint8List.fromList(
        txInputRaw.sublist(cursor, cursor + 32).reversed.toList());
    if (inpHash.isEmpty) {
      throw ArgumentError(
          "Input transaction hash not found. Probably malformed raw transaction");
    }
    Uint8List outputN = Uint8List.fromList(
        txInputRaw.sublist(cursor + 32, cursor + 36).reversed.toList());
    cursor += 36;
    final vi = viToInt(txInputRaw.sublist(cursor, cursor + 9));
    cursor += vi.$2;
    Uint8List unlockingScript = txInputRaw.sublist(cursor, cursor + vi.$1);
    cursor += vi.$1;
    Uint8List sequenceNumberData = txInputRaw.sublist(cursor, cursor + 4);
    cursor += 4;
    return (
      TxInput(
          txId: bytesToHex(inpHash),
          txIndex: int.parse(bytesToHex(outputN), radix: 16),
          sig: Script.fromRaw(
              hexData: bytesToHex(unlockingScript), hasSegwit: hasSegwit),
          sq: sequenceNumberData),
      cursor
    );
  }
}
