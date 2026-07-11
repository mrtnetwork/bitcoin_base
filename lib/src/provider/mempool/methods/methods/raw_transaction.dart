import 'package:bitcoin_base/src/bitcoin/script/transaction.dart';
import 'package:bitcoin_base/src/provider/mempool/core/methods.dart';
import 'package:bitcoin_base/src/provider/mempool/core/params.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

class MempoolRequestGetRawTransaction
    extends MempoolRequest<BtcTransaction, String> {
  final String transactionId;
  const MempoolRequestGetRawTransaction(this.transactionId);

  @override
  List<String> get parameters => [transactionId];

  @override
  MempoolRequestMethods get method => MempoolRequestMethods.rawTransaction;

  @override
  BtcTransaction onResonse(String result) {
    return BtcTransaction.deserialize(BytesUtils.fromHexString(result));
  }
}
