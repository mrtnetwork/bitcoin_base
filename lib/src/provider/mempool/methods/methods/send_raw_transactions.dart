import 'package:bitcoin_base/src/provider/mempool/core/methods.dart';
import 'package:bitcoin_base/src/provider/mempool/core/params.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:blockchain_utils/utils/utils.dart';

class MempoolRequestSendRawTransaction extends MempoolRequest<String, String> {
  final String digest;
  const MempoolRequestSendRawTransaction(this.digest);

  @override
  MempoolRequestMethods get method => MempoolRequestMethods.sendTransact;

  @override
  RequestMethod get requestMethod => RequestMethod.post;

  @override
  List<int>? get body => StringUtils.encode(digest);
}
