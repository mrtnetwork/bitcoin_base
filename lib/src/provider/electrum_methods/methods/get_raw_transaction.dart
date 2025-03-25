import 'package:bitcoin_base/src/bitcoin/script/transaction.dart';
import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

/// Return a raw transaction.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestGetRawTransaction
    extends ElectrumRequest<BtcTransaction, String> {
  ElectrumRequestGetRawTransaction(this.transactionHash);

  /// The transaction hash as a hexadecimal string.
  final String transactionHash;

  /// blockchain.transaction.get
  @override
  String get method => ElectrumRequestMethods.getTransaction.method;

  @override
  List toJson() {
    return [transactionHash, false];
  }

  @override
  BtcTransaction onResonse(String result) {
    final txBytes = BytesUtils.fromHexString(result);
    final tx = BtcTransaction.deserialize(txBytes);
    assert(BytesUtils.bytesEqual(tx.toBytes(), txBytes), result);
    return tx;
  }
}
