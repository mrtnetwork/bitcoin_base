import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';
import 'package:bitcoin_base/src/provider/models/electrum/models.dart';

/// Return a raw transaction.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestGetVerboseTransaction
    extends ElectrumRequest<ElectrumVerbosTxResponse, Map<String, dynamic>> {
  ElectrumRequestGetVerboseTransaction(this.transactionHash);

  /// The transaction hash as a hexadecimal string.
  final String transactionHash;

  /// blockchain.transaction.get
  @override
  String get method => ElectrumRequestMethods.getTransaction.method;

  @override
  List toJson() {
    return [transactionHash, true];
  }

  /// If verbose is false:
  /// The raw transaction as a hexadecimal string.
  ///
  /// If verbose is true:
  /// The result is a coin-specific dictionary – whatever the coin daemon returns when asked for a verbose form of the raw transaction.
  @override
  ElectrumVerbosTxResponse onResonse(result) {
    return ElectrumVerbosTxResponse.fromJson(result);
  }
}
