import 'package:bitcoin_base/src/provider/models/block_cypher/block_cypher_models.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:bitcoin_base/src/provider/block_cypher/core/methods.dart';
import 'package:bitcoin_base/src/provider/block_cypher/core/params.dart';

class BlockCypherRequestSendRawTransaction
    extends BlockCypherRequest<String, Map<String, dynamic>> {
  final String digest;
  const BlockCypherRequestSendRawTransaction(this.digest);

  @override
  BlockCypherRequestMethods get method =>
      BlockCypherRequestMethods.sendTransact;

  @override
  RequestMethod get requestMethod => RequestMethod.post;

  @override
  List<int>? get body => StringUtils.encodeJson({"tx": digest});

  @override
  String onResonse(Map<String, dynamic> result) {
    if (result.hasValue("tx")) {
      return BlockCypherTransaction.fromJson(
        result.valueEnsureAsMap<String, dynamic>("tx"),
      ).hash;
    }
    return BlockCypherTransaction.fromJson(result).hash;
  }
}
