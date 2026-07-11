import 'package:bitcoin_base/src/provider/block_cypher/core/methods.dart';
import 'package:bitcoin_base/src/provider/block_cypher/core/params.dart';
import 'package:bitcoin_base/src/provider/models/block_cypher/block_cypher_models.dart';

class BlockCypherRequestLatestBlockHeight
    extends BlockCypherRequest<int, Map<String, dynamic>> {
  const BlockCypherRequestLatestBlockHeight();

  @override
  List<String> get parameters => [];

  @override
  BlockCypherRequestMethods get method =>
      BlockCypherRequestMethods.latestBlockHeight;

  @override
  int onResonse(Map<String, dynamic> result) {
    final chainInfo = BlockCypherChainInfo.fromJson(result);
    return chainInfo.height;
  }
}
