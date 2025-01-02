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

  Map<String, dynamic> toJson() {
    return {
      'cashToken': cashToken?.toJson(),
      'amount': amount.toString(),
      'scriptPubKey': scriptPubKey.script
    };
  }

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
    final scriptBytes = <int>[
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

  static Tuple<TxOutput, int> deserialize(
      {required List<int> bytes, required int cursor, bool hasSegwit = false}) {
    final value = BigintUtils.fromBytes(bytes.sublist(cursor, cursor + 8),
            byteOrder: Endian.little)
        .toSigned(64);
    cursor += 8;

    final vi = IntUtils.decodeVarint(bytes.sublist(cursor));
    cursor += vi.item2;
    final token = CashToken.fromRaw(bytes.sublist(cursor));

    final lockScript = bytes.sublist(cursor + token.item2, cursor + vi.item1);
    cursor += vi.item1;
    return Tuple(
        TxOutput(
            amount: value,
            cashToken: token.item1,
            scriptPubKey:
                Script.deserialize(bytes: lockScript, hasSegwit: hasSegwit)),
        cursor);
  }

  @override
  String toString() {
    return 'TxOutput{cashToken: ${cashToken?.toString()}}, amount: $amount, script: ${scriptPubKey.toString()}}';
  }
}
