import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';
import 'package:bitcoin_base/src/provider/models/electrum/models.dart';

/// Return the merkle branch to a confirmed transaction given its hash and height.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestGetMerkle
    extends ElectrumRequest<ElectrumGetMerkleResponse, Map<String, dynamic>> {
  ElectrumRequestGetMerkle(
      {required this.transactionHash, required this.height});

  /// The transaction hash as a hexadecimal string.
  final String transactionHash;

  /// he height at which it was confirmed.
  final int height;

  /// blockchain.transaction.get_merkle
  @override
  String get method => ElectrumRequestMethods.getMerkle.method;

  @override
  List toJson() {
    return [transactionHash, height];
  }

  @override
  ElectrumGetMerkleResponse onResonse(result) {
    return ElectrumGetMerkleResponse.fromJson(result);
  }
}
