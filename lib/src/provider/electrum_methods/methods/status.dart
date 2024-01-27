import 'package:bitcoin_base/src/provider/api_provider.dart';

/// Subscribe to a script hash.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumScriptHashSubscribe
    extends ElectrumRequest<Map<String, dynamic>, dynamic> {
  ElectrumScriptHashSubscribe({required this.scriptHash});

  /// /// The script hash as a hexadecimal string (BitcoinBaseAddress.pubKeyHash())
  final String scriptHash;

  /// blockchain.scripthash.subscribe
  @override
  String get method => ElectrumRequestMethods.scriptHashSubscribe.method;

  @override
  List toJson() {
    return [scriptHash];
  }

  /// The status of the script hash.
  @override
  Map<String, dynamic> onResonse(result) {
    return Map<String, dynamic>.from(result);
  }
}
