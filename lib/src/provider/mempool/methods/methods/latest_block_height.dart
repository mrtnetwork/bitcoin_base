import 'package:bitcoin_base/src/provider/mempool/core/methods.dart';
import 'package:bitcoin_base/src/provider/mempool/core/params.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

class MempoolRequestLatestBlockHeight extends MempoolRequest<int, String> {
  const MempoolRequestLatestBlockHeight();

  @override
  List<String> get parameters => [];

  @override
  MempoolRequestMethods get method => MempoolRequestMethods.latestBlockHeight;

  @override
  int onResonse(String result) {
    return IntUtils.parse(result);
  }
}
