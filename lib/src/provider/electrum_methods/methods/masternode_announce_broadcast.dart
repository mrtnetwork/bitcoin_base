import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Pass through the masternode announce message to be broadcast by the daemon.
/// Whenever a masternode comes online or a client is syncing,
/// they will send this message which describes the masternode entry and how to validate messages from it.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestMasternodeAnnounceBroadcast
    extends ElectrumRequest<bool, bool> {
  ElectrumRequestMasternodeAnnounceBroadcast({required this.signmnb});
  final String signmnb;

  /// masternode.announce.broadcast
  @override
  String get method =>
      ElectrumRequestMethods.masternodeAnnounceBroadcast.method;

  @override
  List toJson() {
    return [signmnb];
  }

  /// true if the message was broadcasted successfully otherwise false.
  @override
  bool onResonse(result) {
    return result;
  }
}
