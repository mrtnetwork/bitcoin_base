import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';
import 'package:bitcoin_base/src/provider/models/electrum/models.dart';

/// Subscribe to receive block headers when a new block is found.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestHeaderSubscribe extends ElectrumRequest<
    ElectrumHeaderSubscribeResponse, Map<String, dynamic>> {
  @override
  String get method => ElectrumRequestMethods.headersSubscribe.method;

  @override
  List toJson() {
    return [];
  }

  /// The header of the current block chain tip.
  @override
  ElectrumHeaderSubscribeResponse onResonse(result) {
    return ElectrumHeaderSubscribeResponse.fromJson(result);
  }
}
