import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// A newly-started server uses this call to get itself into other servers’ peers lists.
/// It should not be used by wallet clients.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestAddPeer extends ElectrumRequest<bool, bool> {
  ElectrumRequestAddPeer({required this.features});

  /// The same information that a call to the sender’s server.features() RPC call would return.
  final Map<String, dynamic> features;

  /// server.add_peer
  @override
  String get method => ElectrumRequestMethods.serverAddPeer.method;

  @override
  List toJson() {
    return [features];
  }

  /// A boolean indicating whether the request was tentatively accepted
  /// The requesting server will appear in server.peers.subscribe() when further sanity checks complete successfully.
  @override
  bool onResonse(result) {
    return result;
  }
}
