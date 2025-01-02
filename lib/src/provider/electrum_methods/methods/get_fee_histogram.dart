import 'package:bitcoin_base/src/provider/core/methods.dart';
import 'package:bitcoin_base/src/provider/core/params.dart';

/// Return a histogram of the fee rates paid by transactions in the memory pool, weighted by transaction size.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestGetFeeHistogram
    extends ElectrumRequest<List<List<double>>, List<dynamic>> {
  /// mempool.get_fee_histogram
  @override
  String get method => ElectrumRequestMethods.getFeeHistogram.method;

  @override
  List toJson() {
    return [];
  }

  /// The histogram is an array of [fee, vsize] pairs, where vsizen is the cumulative virtual size of mempool transactions with a fee rate in the interval [feen-1, feen], and feen-1 > feen.
  /// Fee intervals may have variable size. The choice of appropriate intervals is currently not part of the protocol.
  /// fee uses sat/vbyte as unit, and must be a non-negative integer or float.
  /// vsize uses vbyte as unit, and must be a non-negative integer.
  @override
  List<List<double>> onResonse(result) {
    return result
        .map((e) => (e as List).map((e) => (e as num).toDouble()).toList())
        .toList();
  }
}
