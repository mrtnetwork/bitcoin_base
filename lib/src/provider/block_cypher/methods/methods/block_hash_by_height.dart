import 'package:bitcoin_base/src/provider/block_cypher/core/methods.dart';
import 'package:bitcoin_base/src/provider/block_cypher/core/params.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';

class BlockCypherRequestGetBlockHashByHeight
    extends BlockCypherRequest<String, Map<String, dynamic>> {
  final int height;
  const BlockCypherRequestGetBlockHashByHeight(this.height);

  @override
  List<String> get parameters => [height.toString()];

  @override
  BlockCypherRequestMethods get method => BlockCypherRequestMethods.blockHeight;

  @override
  String onResonse(Map<String, dynamic> result) {
    return result.valueAs("hash");
  }
}
