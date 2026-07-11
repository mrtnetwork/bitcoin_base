import 'package:bitcoin_base/src/bitcoin/script/transaction.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:bitcoin_base/src/provider/block_cypher/core/methods.dart';
import 'package:bitcoin_base/src/provider/block_cypher/core/params.dart';

class BlockCypherRequestGetRawTransaction
    extends BlockCypherRequest<BtcTransaction, Map<String, dynamic>> {
  final String transactionId;
  const BlockCypherRequestGetRawTransaction(this.transactionId);

  @override
  List<String> get parameters => [transactionId];
  @override
  Map<String, String?> get queryParameters => {"includeHex": 'true'};
  @override
  BlockCypherRequestMethods get method =>
      BlockCypherRequestMethods.rawTransaction;

  @override
  BtcTransaction onResonse(Map<String, dynamic> result) {
    return BtcTransaction.deserialize(
      BytesUtils.fromHexString(result.valueAs("hex")),
    );
  }
}
