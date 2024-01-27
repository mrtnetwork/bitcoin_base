import 'package:bitcoin_base/src/provider/service/electrum/methods.dart';
import 'package:bitcoin_base/src/provider/service/electrum/params.dart';

/// Return the confirmed and unconfirmed balances of a script hash.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumGetScriptHashBalance
    extends ElectrumRequest<Map<String, dynamic>, Map<String, dynamic>> {
  ElectrumGetScriptHashBalance({required this.scriptHash});

  /// The script hash as a hexadecimal string (BitcoinBaseAddress.pubKeyHash())
  final String scriptHash;

  /// blockchain.scripthash.get_balance
  @override
  String get method => ElectrumRequestMethods.getBalance.method;

  @override
  List toJson() {
    return [scriptHash];
  }

  /// A dictionary with keys confirmed and unconfirmed.
  /// The value of each is the appropriate balance in minimum coin units (satoshis).
  @override
  Map<String, dynamic> onResonse(Map<String, dynamic> result) {
    return result;
  }
}
