import 'package:bitcoin_base/src/provider/types/types.dart';
import 'package:blockchain_utils/service/models/params.dart';

typedef BitcoinServiceResponse = BaseServiceResponse;

/// A mixin defining the service provider contract for interacting with the bitcoin (elctrum) network.
mixin BitcoinServiceProvider
    implements
        IServiceProvider<BitcoinRequestDetails, BaseGRPCServiceRequestParams> {
  @override
  Future<BitcoinServiceResponse> doRequest(
    BitcoinRequestDetails params, {
    Duration? timeout,
  });

  @override
  Future<BaseServiceSubscribtionResponse> doSubscribtionRequest({
    required BitcoinRequestDetails params,
    required BaseServiceSubscribtionRequest<
      dynamic,
      dynamic,
      BaseSubscribtionEvent<dynamic>,
      BitcoinRequestDetails
    >
    request,
    Duration? timeout,
  }) {
    throw UnsupportedError(
      "Subscribtion requests are not supported by this service.",
    );
  }

  @override
  Future<List<int>> doGrpcRequest(
    BaseGRPCServiceRequestParams params, {
    Duration? timeout,
  }) {
    throw UnsupportedError("gRPC requests are not supported by this service.");
  }

  @override
  Stream<List<int>> doGrpcRequestStream(
    BaseGRPCServiceRequestParams params, {
    Duration? timeout,
  }) {
    throw UnsupportedError("gRPC requests are not supported by this service.");
  }

  @override
  Future<Stream<List<int>>> doGrpcRequestStreamAsync(
    BaseGRPCServiceRequestParams params, {
    Duration? timeout,
  }) {
    throw UnsupportedError("gRPC requests are not supported by this service.");
  }
}
