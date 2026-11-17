import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'utils.dart';

void encodingRequestParamsTest() {
  test('encoding provider params', () {
    final param = MempoolRequestGetBlockHashByHeight(1);
    final request = param.buildRequest(0);
    final deserialize = BitcoinRequestDetails.deserialize(
      bytes: request.toCbor().encode(),
    );
    expect(deserialize.path, request.path);
    expect(deserialize.encodeBody(), request.encodeBody());
    expect(deserialize.successStatusCodes, request.successStatusCodes);
    expect(deserialize.errorStatusCodes, request.errorStatusCodes);
    expect(deserialize.network, BlockchainNetwork.bitcoinAndRelated);
    expect(deserialize.responseEncoding, request.responseEncoding);
    expect(deserialize.requestMethod, request.requestMethod);
    expect(deserialize.api, BitcoinProviderApi.mempool);
  });
  test('encoding provider params', () {
    final param = BlockCypherRequestGetBlockHashByHeight(1);
    final request = param.buildRequest(0);
    final deserialize = BitcoinRequestDetails.deserialize(
      bytes: request.toCbor().encode(),
    );
    expect(deserialize.path, request.path);
    expect(deserialize.encodeBody(), request.encodeBody());
    expect(deserialize.successStatusCodes, request.successStatusCodes);
    expect(deserialize.errorStatusCodes, request.errorStatusCodes);
    expect(deserialize.network, BlockchainNetwork.bitcoinAndRelated);
    expect(deserialize.responseEncoding, request.responseEncoding);
    expect(deserialize.requestMethod, request.requestMethod);
    expect(deserialize.api, BitcoinProviderApi.blockCypher);
  });
  test('encoding provider params', () {
    final param = ElectrumRequestGetMerkle(transactionHash: "", height: 1);
    final request = param.buildRequest(0);
    final deserialize = BitcoinRequestDetails.deserialize(
      bytes: request.toCbor().encode(),
    );
    expect(deserialize.path, request.path);
    expect(deserialize.encodeBody(), request.encodeBody());
    expect(deserialize.successStatusCodes, request.successStatusCodes);
    expect(deserialize.errorStatusCodes, request.errorStatusCodes);
    expect(deserialize.network, BlockchainNetwork.bitcoinAndRelated);
    expect(deserialize.responseEncoding, request.responseEncoding);
    expect(deserialize.requestMethod, request.requestMethod);
    expect(deserialize.api, BitcoinProviderApi.electrum);
  });
}

void encodingRequestParamsTest2() {
  BitcoinBaseTestApi.runTest(
    encodingRequestParamsTest,
    "Encoding Request Params",
  );
}

void main() {
  BitcoinBaseTestApi.runTest(
    encodingRequestParamsTest2,
    "Encoding Request Params",
  );
}
