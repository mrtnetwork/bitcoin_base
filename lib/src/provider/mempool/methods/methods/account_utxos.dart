import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:bitcoin_base/src/provider/mempool/core/methods.dart';
import 'package:bitcoin_base/src/provider/mempool/core/params.dart';

class MempoolRequestGetAccountUtxos
    extends MempoolRequest<List<UtxoWithAddress>, List<Map<String, dynamic>>> {
  final UtxoAddressDetails owner;
  final String address;
  const MempoolRequestGetAccountUtxos({
    required this.owner,
    required this.address,
  });

  @override
  List<String> get parameters => [address];

  @override
  MempoolRequestMethods get method => MempoolRequestMethods.addressUtxos;

  @override
  List<UtxoWithAddress> onResonse(List<Map<String, dynamic>> result) {
    final utxos = result.map((e) => MempolUtxo.fromJson(e)).toList();
    return utxos.toUtxoWithOwnerList(owner);
  }
}
