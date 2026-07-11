import 'package:bitcoin_base/src/provider/types/types.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'dart:async';

class BitcoinProvider<SERVICE extends IServiceProvider>
    extends IProvider<SERVICE, BitcoinRequestDetails> {
  @override
  final SERVICE service;
  BitcoinProvider(this.service);

  /// The unique identifier for each JSON-RPC request.
  int _id = 0;

  /// Sends a request to the Electrum server using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  @override
  Future<RESULT> request<RESULT, SERVICERESPONSE>(
    IServiceRequest<RESULT, SERVICERESPONSE, BitcoinRequestDetails> request, {
    Duration? timeout,
  }) async {
    final r = await requestDynamic<RESULT, SERVICERESPONSE>(
      request,
      timeout: timeout,
    );
    return request.onResonse(r);
  }

  /// Sends a request to the Electrum server using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  @override
  Future<SERVICERESPONSE> requestDynamic<RESULT, SERVICERESPONSE>(
    IServiceRequest<RESULT, SERVICERESPONSE, BitcoinRequestDetails> request, {
    Duration? timeout,
  }) async {
    final params = request.buildRequest(_id++);
    final response = await service.doRequest(params, timeout: timeout);
    return parseResponse<SERVICERESPONSE>(params: params, response: response);
  }

  static SERVICERESPONSE _parseRpcError<SERVICERESPONSE>({
    required Map data,
    required BaseServiceResponse response,
    required BitcoinRequestDetails params,
  }) {
    final errorJson = StringUtils.tryToJson<Map<String, dynamic>>(
      data["error"],
    );
    final code = IntUtils.tryParse(errorJson?['code']);
    final message = errorJson?['message']?.toString();
    throw RPCError(
      errorCode: code,
      message: message ?? data["error"].toString(),
      request: params.toJson(),
      jsonRpcErrpr: Map<String, dynamic>.from(data),
      relatedNetwork: BlockchainNetwork.bitcoinAndRelated,
      statusCode: response.statusCode,
    );
  }

  static SERVICERESPONSE parseResponse<SERVICERESPONSE>({
    required BaseServiceResponse response,
    required BitcoinRequestDetails params,
  }) {
    if (response.type == ServiceResponseType.error) {
      final error = response.cast<BaseServiceErrorResponse>();
      if (!error.validate) throw error.defaultError();
      if (params.api == BitcoinProviderApi.electrum ||
          params.api == BitcoinProviderApi.blockCypher) {
        Map<String, dynamic>? errorJson = error.tryToJson();

        final code = IntUtils.tryParse(errorJson?['code']);
        final message = errorJson?['message'] ?? errorJson?['error'];
        throw RPCError(
          errorCode: code,
          message: (message is String ? message : ServiceConst.defaultError),
          request: params.toJson(),
          jsonRpcErrpr: errorJson,
          relatedNetwork: BlockchainNetwork.bitcoinAndRelated,
          statusCode: response.statusCode,
        );
      }
      throw RPCError(
        message: error.tryAsString() ?? ServiceConst.defaultError,
        request: params.toJson(),
        relatedNetwork: BlockchainNetwork.bitcoinAndRelated,
        statusCode: response.statusCode,
      );
    }
    final data = switch (params.api) {
      BitcoinProviderApi.blockCypher || BitcoinProviderApi.mempool => params
          .toEncodingResponse<SERVICERESPONSE>(response),
      BitcoinProviderApi.electrum => params
          .toEncodingResponse<Map<String, dynamic>>(response),
    };
    if (params.api.isJsonRpc && data is Map) {
      if (data.hasValue("error")) {
        return _parseRpcError(data: data, response: response, params: params);
      }
      return ServiceProviderUtils.toResponse<SERVICERESPONSE>(
        object: data['result'],
        params: params,
      );
    }
    return ServiceProviderUtils.toResponse<SERVICERESPONSE>(
      object: data,
      params: params,
    );
  }
}
