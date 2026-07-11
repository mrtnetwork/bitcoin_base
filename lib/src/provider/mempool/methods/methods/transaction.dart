import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:bitcoin_base/src/provider/mempool/core/methods.dart';
import 'package:bitcoin_base/src/provider/mempool/core/params.dart';

class MempoolRequestGetTransaction
    extends MempoolRequest<MempoolTransaction, Map<String, dynamic>> {
  final String transactionId;
  const MempoolRequestGetTransaction(this.transactionId);

  @override
  List<String> get parameters => [transactionId];

  @override
  MempoolRequestMethods get method => MempoolRequestMethods.transaction;

  @override
  MempoolTransaction onResonse(Map<String, dynamic> result) {
    return MempoolTransaction.fromJson(result);
  }
}
