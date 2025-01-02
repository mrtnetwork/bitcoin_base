import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Returns the list of masternodes.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestMasternodeList
    extends ElectrumRequest<List<String>, List<dynamic>> {
  ElectrumRequestMasternodeList({required this.payees});

  /// An array of masternode payee addresses.
  final List<String> payees;

  /// masternode.list
  @override
  String get method => ElectrumRequestMethods.masternodeList.method;

  @override
  List toJson() {
    return [payees];
  }

  /// An array with the masternodes information.
  @override
  List<String> onResonse(result) {
    return List<String>.from(result);
  }
}
