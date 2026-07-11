import 'package:bitcoin_base/src/provider/block_cypher/core/methods.dart';
import 'package:bitcoin_base/src/provider/block_cypher/core/params.dart';
import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class BlockCypherRequestGetAccountTransactions
    extends BlockCypherRequest<List<BlockCypherTransaction>, dynamic> {
  final int? limit;
  final String address;
  const BlockCypherRequestGetAccountTransactions(
    this.address, {
    this.limit = 200,
  });

  @override
  Map<String, String?> get queryParameters => {"limit": limit?.toString()};

  @override
  List<String> get parameters => [address];

  @override
  BlockCypherRequestMethods get method =>
      BlockCypherRequestMethods.transactions;

  @override
  List<BlockCypherTransaction> onResonse(dynamic result) {
    assert(result is List || result is Map, "unexpected blockcypher response");
    if (result is List) {
      return result.map((e) => BlockCypherTransaction.fromJson(e)).toList();
    } else if (result is Map && result.containsKey("txs")) {
      return result
          .valueEnsureAsList("txs")
          .map((e) => BlockCypherTransaction.fromJson(e))
          .toList();
    }
    return [];
  }
}
