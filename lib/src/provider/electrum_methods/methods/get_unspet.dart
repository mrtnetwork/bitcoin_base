import 'package:bitcoin_base/src/provider/models/electrum/electrum_utxo.dart';
import 'package:bitcoin_base/src/provider/service/electrum/methods.dart';
import 'package:bitcoin_base/src/provider/service/electrum/params.dart';

/// Return an ordered list of UTXOs sent to a script hash.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumScriptHashListUnspent
    extends ElectrumRequest<List<ElectrumUtxo>, List<dynamic>> {
  ElectrumScriptHashListUnspent(
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
    return [scriptHash, if (includeTokens) "include_tokens"];
  }

  /// A list of unspent outputs in blockchain order.
  /// This function takes the mempool into account.
  /// Mempool transactions paying to the address are included at the end of the list in an undefined order.
  /// Any output that is spent in the mempool does not appear.
  @override
  List<ElectrumUtxo> onResonse(result) {
    final List<ElectrumUtxo> utxos =
        result.map((e) => ElectrumUtxo.fromJson(e)).toList();
    return utxos;
  }
}
