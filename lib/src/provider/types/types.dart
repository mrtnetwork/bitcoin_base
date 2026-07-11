import 'package:bitcoin_base/src/provider/block_cypher/block_cypher.dart';
import 'package:bitcoin_base/src/provider/electrum/electrum.dart';
import 'package:bitcoin_base/src/provider/mempool/mempool.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

enum BitcoinProviderApi {
  electrum(0),
  mempool(1),
  blockCypher(2);

  final int value;
  const BitcoinProviderApi(this.value);
  static BitcoinProviderApi fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ItemNotFoundException(),
    );
  }

  bool get isMempool => this == mempool;
  bool get isBlockCypher => this == blockCypher;
  bool get isJsonRpc => this == electrum;
}

abstract class BitcoinRequestDetails extends BaseServiceRequestParams {
  final BitcoinProviderApi api;
  const BitcoinRequestDetails({
    required super.headers,
    required super.requestMethod,
    required super.requestID,
    required super.responseEncoding,
    super.bodyBytes,
    super.bodyString,
    required this.api,
    super.errorStatusCodes,
    super.path,
    super.successStatusCodes,
  }) : super(network: BlockchainNetwork.bitcoinAndRelated);

  factory BitcoinRequestDetails.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final CborTagValue tag = CborTagSerializable.decode(
      cborBytes: bytes,
      cborObject: object,
    );
    final decode = CborTagSerializable.decodeTaggedValue(
      cborObject: tag,
      identifier: BlockchainNetwork.bitcoinAndRelated.identifier,
    );
    final api = BitcoinProviderApi.fromValue(decode.rawValueAt(0));
    return switch (api) {
      BitcoinProviderApi.electrum => ElectrumRequestDetails.deserialize(
        object: tag,
      ),
      BitcoinProviderApi.mempool => MempoolRequestDetails.deserialize(
        object: tag,
      ),
      BitcoinProviderApi.blockCypher => BlockCypherRequestDetails.deserialize(
        object: tag,
      ),
    };
  }
}
