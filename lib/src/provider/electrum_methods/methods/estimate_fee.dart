import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';
import 'package:bitcoin_base/src/utils/btc_utils.dart';

/// Return the estimated transaction fee per kilobyte for a transaction to be confirmed within a certain number of blocks.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumEstimateFee extends ElectrumRequest<BigInt, dynamic> {
  ElectrumEstimateFee({this.numberOfBlock = 2});

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
  BigInt onResonse(result) {
    return BtcUtils.toSatoshi(result.toString()).abs();
  }
}
