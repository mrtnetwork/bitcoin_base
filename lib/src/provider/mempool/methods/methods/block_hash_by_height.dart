import 'package:bitcoin_base/src/provider/mempool/core/methods.dart';
import 'package:bitcoin_base/src/provider/mempool/core/params.dart';

class MempoolRequestGetBlockHashByHeight
    extends MempoolRequest<String, String> {
  final int height;
  const MempoolRequestGetBlockHashByHeight(this.height);

  @override
  List<String> get parameters => [height.toString()];

  @override
  MempoolRequestMethods get method => MempoolRequestMethods.blockHeight;
}
