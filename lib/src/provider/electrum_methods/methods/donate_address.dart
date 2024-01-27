import 'package:bitcoin_base/src/provider/api_provider.dart';

/// Return a server donation address.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumDonationAddress extends ElectrumRequest<String, String> {
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
