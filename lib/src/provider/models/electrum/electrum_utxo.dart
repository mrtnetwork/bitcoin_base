import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/cash_token/cash_token.dart';
import 'package:bitcoin_base/src/provider/api_provider.dart';

class ElectrumUtxo implements UTXO {
  factory ElectrumUtxo.fromJson(Map<String, dynamic> json) {
    CashToken? token;
    if (json.containsKey('token_data')) {
      token = CashToken.fromJson(json['token_data']);
    }
    return ElectrumUtxo._(
        height: json['height'],
        txId: json['tx_hash'],
        vout: json['tx_pos'],
        value: BigInt.parse((json['value'].toString())),
        token: token);
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
}
