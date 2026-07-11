import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/provider/mempool/core/methods.dart';
import 'package:bitcoin_base/src/provider/types/types.dart';
import 'package:bitcoin_base/src/provider/utils/utils.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class MempoolRequestDetails extends BitcoinRequestDetails {
  final String method;
  const MempoolRequestDetails({
    required super.requestID,
    required this.method,
    required super.requestMethod,
    super.path,
    required super.responseEncoding,
    super.headers = ServiceConst.defaultPostHeaders,
    super.bodyBytes,
    super.bodyString,
    super.errorStatusCodes = const [400],
  }) : super(api: BitcoinProviderApi.mempool);
  factory MempoolRequestDetails.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainNetwork.bitcoinAndRelated.identifier,
      cborBytes: bytes,
      cborObject: object,
    );
    return MempoolRequestDetails(
      headers: values
          .mapAt<CborStringValue, CborStringValue>(1)
          .map((k, v) => MapEntry(k.value, v.value)),
      path: values.rawValueAt(2),
      requestMethod: RequestMethod.fromValue(values.rawValueAt(3)),
      responseEncoding: ServiceReponseEncoding.fromValue(values.rawValueAt(4)),
      bodyBytes: values.rawValueAt(5),
      bodyString: values.rawValueAt(6),
      requestID: values.rawValueAt(7),
      method: values.rawValueAt(8),
      errorStatusCodes:
          values
              .listAt<CborIntValue>(9)
              .map((e) => e.value)
              .toList()
              .emptyAsNull,
    );
  }
  MempoolRequestDetails copyWith({
    int? requestID,
    Map<String, String>? headers,
    List<int>? bodyBytes,
    String? bodyString,
    ServiceReponseEncoding? responseEncoding,
    String? method,
    RequestMethod? requestMethod,
    String? path,
    List<int>? errorStatusCodes,
  }) {
    return MempoolRequestDetails(
      requestID: requestID ?? this.requestID,
      headers: headers ?? this.headers,
      responseEncoding: responseEncoding ?? this.responseEncoding,
      bodyString: bodyString ?? this.bodyString,
      bodyBytes: bodyBytes ?? this.bodyBytes,
      method: method ?? this.method,
      requestMethod: requestMethod ?? this.requestMethod,
      path: path ?? this.path,
      errorStatusCodes: errorStatusCodes ?? this.errorStatusCodes,
    );
  }

  @override
  Uri encodeUrl(String uri) {
    if (uri.endsWith('/')) {
      uri = uri.substring(0, uri.length - 1);
    }

    return Uri.parse('$uri${path ?? ''}');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "requestId": requestID,
      'body': bodyString ?? BytesUtils.tryToHexString(bodyBytes),
      "method": method,
      "path": path,
    };
  }

  @override
  List<int>? encodeBody({ServiceProtocol protocol = ServiceProtocol.http}) {
    assert(protocol.isHttp, "Unsupported protocol.");
    final toBytes = super.encodeBody();
    if (toBytes == null) return null;
    return toBytes;
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      BlockchainNetwork.bitcoinAndRelated.identifier;

  @override
  List<CborObject?> get serializationItems => [
    api.value.toCbor(),
    CborMapValue.definite(
      headers.map((k, v) => MapEntry(CborStringValue(k), CborStringValue(v))),
    ),
    path?.toCbor(),
    requestMethod.value.toCbor(),
    responseEncoding.value.toCbor(),
    bodyBytes?.toCborBytes(),
    bodyString?.toCbor(),
    requestID.toCbor(),
    method.toCbor(),
    CborTagSerializable.listFromDynamic(
      errorStatusCodes?.map((e) => CborIntValue(e)).toList() ?? [],
    ),
  ];
}

/// Abstract class representing an Electrum request with generic result and response types.
abstract class MempoolRequest<RESULT, RESPONSE>
    extends BaseServiceRequest<RESULT, RESPONSE, MempoolRequestDetails> {
  const MempoolRequest();
  abstract final MempoolRequestMethods method;
  List<String> get parameters => [];
  Map<String, String?> get queryParameters => {};
  List<int>? get body => null;

  @override
  MempoolRequestDetails buildRequest(int requestID) {
    final pathParams = BitcoinProviderUtils.extractParams(method.url);
    if (pathParams.length != parameters.length) {
      throw DartBitcoinPluginException(
        'Invalid Path Parameters.',
        details: {
          'pathParams': parameters.join(","),
          'expectedPathParametersLength': pathParams.length.toString(),
        },
      );
    }
    String params = method.url;
    for (int i = 0; i < pathParams.length; i++) {
      params = params.replaceFirst(pathParams[i], parameters[i]);
    }
    final queryParams = Map<String, String>.from(queryParameters.notNullValue);
    if (queryParams.isNotEmpty) {
      params =
          Uri.parse(
            params,
          ).replace(queryParameters: queryParams).normalizePath().toString();
    }
    return MempoolRequestDetails(
      requestID: requestID,
      method: method.url,
      bodyBytes: requestMethod.isPost ? body : null,
      path: params,
      responseEncoding: ServiceReponseEncoding.fromType<RESPONSE>(),
      headers: requestMethod.isPost ? ServiceConst.defaultPostHeaders : {},
      requestMethod: requestMethod,
    );
  }

  @override
  RequestMethod get requestMethod => RequestMethod.get;
}
