import 'dart:typed_data';
import 'package:bitcoin_base/src/cash_token/cash_token.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Represents a transaction output.
///
/// [amount] the value we want to send to this output in satoshis
/// [scriptPubKey] the script that will lock this amount
class TxOutput {
  const TxOutput(
      {required this.amount, required this.scriptPubKey, this.cashToken});
  final CashToken? cashToken;
  final BigInt amount;
  final Script scriptPubKey;

  ///  creates a copy of the object
  TxOutput copy() {
    return TxOutput(
        amount: amount,
        scriptPubKey: Script(script: List.from(scriptPubKey.script)),
        cashToken: cashToken);
  }

  List<int> toBytes() {
    final amountBytes =
        BigintUtils.toBytes(amount, length: 8, order: Endian.little);
    List<int> scriptBytes = [
      ...cashToken?.toBytes() ?? <int>[],
      ...scriptPubKey.toBytes()
    ];
    final data = [
      ...amountBytes,
      ...IntUtils.encodeVarint(scriptBytes.length),
      ...scriptBytes
    ];
    return data;
  }

  static Tuple<TxOutput, int> fromRaw(
      {required String raw, required int cursor, bool hasSegwit = false}) {
    final txBytes = BytesUtils.fromHexString(raw);
    final value = BigintUtils.fromBytes(txBytes.sublist(cursor, cursor + 8),
            byteOrder: Endian.little)
        .toSigned(64);
    cursor += 8;

    final vi = IntUtils.decodeVarint(txBytes.sublist(cursor, cursor + 9));
    cursor += vi.item2;
    final token = CashToken.fromRaw(txBytes.sublist(cursor));
    List<int> lockScript =
        txBytes.sublist(cursor + token.item2, cursor + vi.item1);
    cursor += vi.item1;
    return Tuple(
        TxOutput(
            amount: value,
            cashToken: token.item1,
            scriptPubKey: Script.fromRaw(
                hexData: BytesUtils.toHexString(lockScript),
                hasSegwit: hasSegwit)),
        cursor);
  }

  @override
  String toString() {
    return "TxOutput{cashToken: ${cashToken?.toString()}}, amount: $amount, script: ${scriptPubKey.toString()}}";
  }
}
