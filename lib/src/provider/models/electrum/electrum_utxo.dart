import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/cash_token/cash_token.dart';
import 'package:bitcoin_base/src/provider/api_provider.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

class ElectrumUtxo implements UTXO {
  factory ElectrumUtxo.fromJson(Map<String, dynamic> json) {
    return ElectrumUtxo._(
        height: IntUtils.parse(json['height']),
        txId: json['tx_hash'],
        vout: IntUtils.parse(json['tx_pos']),
        value: BigintUtils.parse(json['value']),
        token: json["token_data"] == null
            ? null
            : CashToken.fromJson(json['token_data']));
  }
  const ElectrumUtxo._(
      {required this.height,
      required this.txId,
      required this.vout,
      required this.value,
      this.token});
  final int height;
  final String txId;
  final int vout;
  final BigInt value;
  final CashToken? token;

  @override
  BitcoinUtxo toUtxo(BitcoinAddressType addressType) {
    return BitcoinUtxo(
        txHash: txId,
        value: value,
        vout: vout,
        scriptType: addressType,
        blockHeight: height,
        token: token);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "token_data": token?.toJson(),
      "height": height,
      "tx_hash": txId,
      "tx_pos": vout,
      "value": value.toString()
    };
  }
}
