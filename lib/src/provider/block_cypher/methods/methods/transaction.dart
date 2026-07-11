import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:bitcoin_base/src/provider/block_cypher/core/methods.dart';
import 'package:bitcoin_base/src/provider/block_cypher/core/params.dart';

class BlockCypherRequestGetTransaction
    extends BlockCypherRequest<BlockCypherTransaction, Map<String, dynamic>> {
  final String transactionId;
  const BlockCypherRequestGetTransaction(this.transactionId);

  @override
  List<String> get parameters => [transactionId];

  @override
  BlockCypherRequestMethods get method => BlockCypherRequestMethods.transaction;

  @override
  BlockCypherTransaction onResonse(Map<String, dynamic> result) {
    return BlockCypherTransaction.fromJson(result);
  }
}
