import 'package:bitcoin_base/src/provider/core/params.dart';
import 'package:blockchain_utils/service/models/params.dart';

/// A mixin defining the service provider contract for interacting with the bitcoin (elctrum) network.
mixin ElectrumServiceProvider
    implements BaseServiceProvider<ElectrumRequestDetails> {
  @override
  Future<BaseServiceResponse<T>> doRequest<T>(ElectrumRequestDetails params,
      {Duration? timeout});
}
