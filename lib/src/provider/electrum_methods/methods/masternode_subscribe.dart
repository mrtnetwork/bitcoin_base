import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Returns the status of masternode.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestMasternodeSubscribe
    extends ElectrumRequest<String, String> {
  ElectrumRequestMasternodeSubscribe({required this.collateral});

  /// The txId and the index of the collateral. Example ("8c59133e714797650cf69043d05e409bbf45670eed7c4e4a386e52c46f1b5e24-0")
  final String collateral;

  /// masternode.subscribe
  @override
  String get method => ElectrumRequestMethods.masternodeSubscribe.method;

  @override
  List toJson() {
    return [collateral];
  }

  /// As this is a subscription, the client will receive a notification when the masternode status changes.
  /// The status depends on the server the masternode is hosted,
  /// the internet connection, the offline time and even the collateral
  /// amount, so this subscription notice these changes to the user.
  @override
  String onResonse(result) {
    return result;
  }
}
