import 'package:bitcoin_base/src/provider/block_cypher/core/methods.dart';
import 'package:bitcoin_base/src/provider/block_cypher/core/params.dart';
import 'package:bitcoin_base/src/provider/models/models.dart';

class BlockCypherRequestGetNetworkFeeRate
    extends BlockCypherRequest<BitcoinFeeRate, Map<String, dynamic>> {
  const BlockCypherRequestGetNetworkFeeRate();

  @override
  List<String> get parameters => [];

  @override
  BlockCypherRequestMethods get method =>
      BlockCypherRequestMethods.feeRecommended;

  @override
  BitcoinFeeRate onResonse(Map<String, dynamic> result) {
    return BitcoinFeeRate.fromBlockCypher(result);
  }
}
