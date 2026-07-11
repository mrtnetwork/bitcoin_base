import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:bitcoin_base/src/provider/mempool/core/methods.dart';
import 'package:bitcoin_base/src/provider/mempool/core/params.dart';

class MempoolRequestGetAccountTransactions
    extends
        MempoolRequest<List<MempoolTransaction>, List<Map<String, dynamic>>> {
  final String address;
  const MempoolRequestGetAccountTransactions(this.address);

  @override
  List<String> get parameters => [address];

  @override
  MempoolRequestMethods get method => MempoolRequestMethods.transactions;

  @override
  List<MempoolTransaction> onResonse(List<Map<String, dynamic>> result) {
    return result.map((e) => MempoolTransaction.fromJson(e)).toList();
  }
}
