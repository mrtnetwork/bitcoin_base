import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:bitcoin_base/src/provider/types/types.dart';

typedef BitcoinServiceResponse = BaseServiceResponse;

/// A mixin defining the service provider contract for interacting with the bitcoin (electrum) network.
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
    throw BuError(
      DefaultErrorType.unsupported,
      "Subscription requests are not supported by this service.",
    );
  }

  @override
  Future<List<int>> doGrpcRequest(
    BaseGRPCServiceRequestParams params, {
    Duration? timeout,
  }) {
    throw BuError(
      DefaultErrorType.unsupported,
      "gRPC requests are not supported by this service.",
    );
  }

  @override
  Stream<List<int>> doGrpcRequestStream(
    BaseGRPCServiceRequestParams params, {
    Duration? timeout,
  }) {
    throw BuError(
      DefaultErrorType.unsupported,
      "gRPC requests are not supported by this service.",
    );
  }

  @override
  Future<Stream<List<int>>> doGrpcRequestStreamAsync(
    BaseGRPCServiceRequestParams params, {
    Duration? timeout,
  }) {
    throw BuError(
      DefaultErrorType.unsupported,
      "gRPC requests are not supported by this service.",
    );
  }
}
