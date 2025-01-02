import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Return a banner to be shown in the Electrum console.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestServerBanner extends ElectrumRequest<String, dynamic> {
  @override
  String get method => ElectrumRequestMethods.serverBanner.method;

  @override
  List toJson() {
    return [];
  }

  @override
  String onResonse(result) {
    return result.toString();
  }
}
