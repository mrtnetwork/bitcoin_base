import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Unsubscribe from a script hash, preventing future notifications if its status changes.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestScriptHashUnSubscribe extends ElectrumRequest<bool, bool> {
  ElectrumRequestScriptHashUnSubscribe({required this.scriptHash});

  /// The script hash as a hexadecimal string (BitcoinBaseAddress.pubKeyHash())
  final String scriptHash;

  /// blockchain.scripthash.unsubscribe
  @override
  String get method => ElectrumRequestMethods.scriptHashUnSubscribe.method;

  @override
  List toJson() {
    return [scriptHash];
  }

  /// Returns True if the scripthash was subscribed to,
  /// otherwise False. Note that False might be returned even
  /// for something subscribed to earlier, because the server can drop subscriptions in rare circumstances.
  @override
  bool onResonse(result) {
    return result;
  }
}
