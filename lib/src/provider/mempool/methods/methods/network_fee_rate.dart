import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:bitcoin_base/src/provider/mempool/core/methods.dart';
import 'package:bitcoin_base/src/provider/mempool/core/params.dart';

class MempoolRequestGetNetworkFeeRate
    extends MempoolRequest<BitcoinFeeRate, Map<String, dynamic>> {
  const MempoolRequestGetNetworkFeeRate();

  @override
  List<String> get parameters => [];

  @override
  MempoolRequestMethods get method => MempoolRequestMethods.feeRecommended;

  @override
  BitcoinFeeRate onResonse(Map<String, dynamic> result) {
    return BitcoinFeeRate.fromMempool(result);
  }
}
