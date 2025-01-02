import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Return a list of peer servers. Despite the name this is not a subscription and the server must send no notifications..
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestServerPeersSubscribe
    extends ElectrumRequest<List<dynamic>, List<dynamic>> {
  /// server.peers.subscribe
  @override
  String get method => ElectrumRequestMethods.serverPeersSubscribe.method;

  @override
  List toJson() {
    return [];
  }

  /// An array of peer servers, each returned as a 3-element array
  @override
  List<dynamic> onResonse(result) {
    return result;
  }
}
