import 'package:bitcoin_base/src/provider/block_cypher/core/methods.dart';
import 'package:bitcoin_base/src/provider/block_cypher/core/params.dart';
import 'package:bitcoin_base/src/provider/models/models.dart';

class BlockCypherRequestGetAccountUtxos
    extends BlockCypherRequest<List<UtxoWithAddress>, Map<String, dynamic>> {
  final UtxoAddressDetails owner;
  final String address;
  final int? limit;
  const BlockCypherRequestGetAccountUtxos({
    required this.owner,
    required this.address,
    this.limit = 2000,
  });

  @override
  List<String> get parameters => [address];

  @override
  Map<String, String?> get queryParameters => {
    "unspentOnly": "true",
    "includeScript": "true",
    "limit": limit?.toString(),
  };

  @override
  BlockCypherRequestMethods get method =>
      BlockCypherRequestMethods.addressUtxos;

  @override
  List<UtxoWithAddress> onResonse(Map<String, dynamic> result) {
    final utxos = BlockCypherUtxo.fromJson(result);
    return utxos.toUtxoWithOwner(owner);
  }
}
