import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';
import 'package:bitcoin_base/src/utils/btc_utils.dart';

/// Return the estimated transaction fee per kilobyte for a transaction to be confirmed within a certain number of blocks.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestEstimateFee extends ElectrumRequest<BigInt?, dynamic> {
  ElectrumRequestEstimateFee({this.numberOfBlock = 2});

  /// The number of blocks to target for confirmation.
  final int numberOfBlock;

  /// blockchain.estimatefee
  @override
  String get method => ElectrumRequestMethods.estimateFee.method;

  @override
  List toJson() {
    return [numberOfBlock];
  }

  /// The estimated transaction fee in Bigint(satoshi)
  @override
  BigInt? onResonse(result) {
    final fee = BtcUtils.toSatoshi(result.toString());
    if (fee.isNegative) return null;
    return fee;
  }
}
