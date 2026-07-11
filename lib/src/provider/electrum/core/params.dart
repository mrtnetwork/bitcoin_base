import 'package:bitcoin_base/src/provider/types/types.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class ElectrumRequestDetails extends BitcoinRequestDetails {
  final String method;
  const ElectrumRequestDetails({
    required super.requestID,
    required this.method,
    super.responseEncoding = ServiceReponseEncoding.map,
    super.headers = ServiceConst.defaultPostHeaders,
    super.bodyBytes,
    super.bodyString,
  }) : super(
         requestMethod: RequestMethod.post,
         path: null,
         api: BitcoinProviderApi.electrum,
       );
  factory ElectrumRequestDetails.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainNetwork.bitcoinAndRelated.identifier,
      cborBytes: bytes,
      cborObject: object,
    );
    return ElectrumRequestDetails(
      headers: values
          .mapAt<CborStringValue, CborStringValue>(1)
          .map((k, v) => MapEntry(k.value, v.value)),
      responseEncoding: ServiceReponseEncoding.fromValue(values.rawValueAt(2)),
      bodyBytes: values.rawValueAt(3),
      bodyString: values.rawValueAt(4),
      requestID: values.rawValueAt(5),
      method: values.rawValueAt(6),
    );
  }
  ElectrumRequestDetails copyWith({
    int? requestID,
    Map<String, String>? headers,
    List<int>? bodyBytes,
    String? bodyString,
    ServiceReponseEncoding? responseEncoding,
    String? method,
  }) {
    return ElectrumRequestDetails(
      requestID: requestID ?? this.requestID,
      headers: headers ?? this.headers,
      responseEncoding: responseEncoding ?? this.responseEncoding,
      bodyString: bodyString ?? this.bodyString,
      bodyBytes: bodyBytes ?? this.bodyBytes,

      method: method ?? this.method,
    );
  }

  @override
  Uri encodeUrl(String uri) {
    return Uri.parse(uri);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'body': bodyString ?? BytesUtils.tryToHexString(bodyBytes),
      "method": method,
    };
  }

  @override
  List<int>? encodeBody({
    ServiceProtocol protocol = ServiceProtocol.http,
    List<int> rawSocketEof = const [10],
  }) {
    final toBytes = super.encodeBody();
    if (toBytes == null) return [];

    if (protocol == ServiceProtocol.ssl ||
        protocol == ServiceProtocol.tcp && rawSocketEof.isNotEmpty) {
      return toBytes + rawSocketEof;
    }
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
    responseEncoding.value.toCbor(),
    bodyBytes?.toCborBytes(),
    bodyString?.toCbor(),
    requestID.toCbor(),
    method.toCbor(),
  ];
}

/// Abstract class representing an Electrum request with generic result and response types.
abstract class ElectrumRequest<RESULT, RESPONSE>
    extends BaseServiceRequest<RESULT, RESPONSE, ElectrumRequestDetails> {
  abstract final String method;
  List<dynamic> toJson();

  @override
  ElectrumRequestDetails buildRequest(int requestID) {
    final inJson = toJson();
    inJson.removeWhere((v) => v == null);
    final params = ServiceProviderUtils.buildJsonRPCParams(
      requestId: requestID,
      method: method,
      params: inJson,
    );
    return ElectrumRequestDetails(
      requestID: requestID,
      bodyString: StringUtils.fromJson(params),
      method: method,
    );
  }

  @override
  RequestMethod get requestMethod => RequestMethod.post;
}
