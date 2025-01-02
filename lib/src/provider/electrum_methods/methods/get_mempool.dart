import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Return the unconfirmed transactions of a script hash.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestScriptHashGetMempool
    extends ElectrumRequest<List<Map<String, dynamic>>, List<dynamic>> {
  ElectrumRequestScriptHashGetMempool({required this.scriptHash});

  /// The script hash as a hexadecimal string (BitcoinBaseAddress.pubKeyHash())
  final String scriptHash;

  /// blockchain.scripthash.get_mempool
  @override
  String get method => ElectrumRequestMethods.getMempool.method;

  @override
  List toJson() {
    return [scriptHash];
  }

  /// A list of mempool transactions in arbitrary order. Each mempool transaction is a dictionary
  @override
  List<Map<String, dynamic>> onResonse(List<dynamic> result) {
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
