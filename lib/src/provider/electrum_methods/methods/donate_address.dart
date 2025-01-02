import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Return a server donation address.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestDonationAddress extends ElectrumRequest<String, String> {
  /// server.donation_address
  @override
  String get method => ElectrumRequestMethods.serverDontionAddress.method;

  @override
  List toJson() {
    return [];
  }

  @override
  String onResonse(result) {
    return result;
  }
}
