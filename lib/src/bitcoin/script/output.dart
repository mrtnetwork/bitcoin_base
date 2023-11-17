import 'dart:typed_data';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/numbers/bigint_utils.dart';
import 'package:blockchain_utils/numbers/int_utils.dart';

/// Represents a transaction output.
///
/// [amount] the value we want to send to this output in satoshis
/// [scriptPubKey] the script that will lock this amount
class TxOutput {
  TxOutput({required this.amount, required this.scriptPubKey});
  final BigInt amount;
  final Script scriptPubKey;

  ///  creates a copy of the object
  TxOutput copy() {
    return TxOutput(amount: amount, scriptPubKey: scriptPubKey);
  }

  /// serializes TxInput to bytes
  List<int> toBytes() {
    final amountBytes =
        BigintUtils.toBytes(amount, length: 8, order: Endian.little);
    List<int> scriptBytes = scriptPubKey.toBytes();
    final data = [
      ...amountBytes,
      ...IntUtils.encodeVarint(scriptBytes.length),
      ...scriptBytes
    ];
    return data;
  }

  static (TxOutput, int) fromRaw(
      {required String raw, required int cursor, bool hasSegwit = false}) {
    final txoutputraw = BytesUtils.fromHexString(raw);
    final value = BigintUtils.fromBytes(txoutputraw.sublist(cursor, cursor + 8),
            byteOrder: Endian.little)
        .toSigned(64);
    cursor += 8;

    final vi = IntUtils.decodeVarint(txoutputraw.sublist(cursor, cursor + 9));
    cursor += vi.$2;
    List<int> lockScript = txoutputraw.sublist(cursor, cursor + vi.$1);
    cursor += vi.$1;
    return (
      TxOutput(
          amount: value,
          scriptPubKey: Script.fromRaw(
              hexData: BytesUtils.toHexString(lockScript),
              hasSegwit: hasSegwit)),
      cursor
    );
  }
}
