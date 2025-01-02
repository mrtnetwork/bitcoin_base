import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Return a raw transaction.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestGetTransaction extends ElectrumRequest<dynamic, dynamic> {
  ElectrumRequestGetTransaction(
      {required this.transactionHash, this.verbose = false});

  /// The transaction hash as a hexadecimal string.
  final String transactionHash;

  /// Whether a verbose coin-specific response is required.
  final bool verbose;

  /// blockchain.transaction.get
  @override
  String get method => ElectrumRequestMethods.getTransaction.method;

  @override
  List toJson() {
    return [transactionHash, verbose];
  }

  /// If verbose is false:
  /// The raw transaction as a hexadecimal string.
  ///
  /// If verbose is true:
  /// The result is a coin-specific dictionary – whatever the coin daemon returns when asked for a verbose form of the raw transaction.
  @override
  dynamic onResonse(result) {
    return result;
  }
}
