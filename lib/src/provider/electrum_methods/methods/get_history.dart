import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Return the confirmed and unconfirmed history of a script hash.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestScriptHashGetHistory
    extends ElectrumRequest<List<Map<String, dynamic>>, List<dynamic>> {
  ElectrumRequestScriptHashGetHistory({required this.scriptHash});

  /// The script hash as a hexadecimal string (BitcoinBaseAddress.pubKeyHash())
  final String scriptHash;

  /// blockchain.scripthash.get_history
  @override
  String get method => ElectrumRequestMethods.getHistory.method;

  @override
  List toJson() {
    return [scriptHash];
  }

  /// A list of confirmed transactions in blockchain order,
  ///  with the output of blockchain.scripthash.get_mempool() appended to the list.
  ///  Each confirmed transaction is a dictionary
  @override
  List<Map<String, dynamic>> onResonse(List<dynamic> result) {
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
