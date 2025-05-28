import 'package:bitcoin_base/src/provider/models/electrum/models.dart';
import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Return an ordered list of UTXOs sent to a script hash.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestScriptHashListUnspent
    extends ElectrumRequest<List<ElectrumUtxo>, List<dynamic>> {
  ElectrumRequestScriptHashListUnspent(
      {required this.scriptHash, this.includeTokens = false});

  /// The script hash as a hexadecimal string (BitcoinBaseAddress.pubKeyHash())
  final String scriptHash;

  /// only work in bitcoin cash network
  final bool includeTokens;

  /// blockchain.scripthash.listunspent
  @override
  String get method => ElectrumRequestMethods.listunspent.method;

  @override
  List toJson() {
    return [scriptHash, if (includeTokens) 'include_tokens'];
  }

  /// A list of unspent outputs in blockchain order.
  /// This function takes the mempool into account.
  /// Mempool transactions paying to the address are included at the end of the list in an undefined order.
  /// Any output that is spent in the mempool does not appear.
  @override
  List<ElectrumUtxo> onResonse(result) {
    final utxos = result.map((e) => ElectrumUtxo.fromJson(e)).toList();
    return utxos;
  }
}
