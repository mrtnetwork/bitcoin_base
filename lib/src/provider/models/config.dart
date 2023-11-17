import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/provider/constant/constant.dart';

enum APIType {
  mempool,
  blockCypher,
}

class APIConfig {
  final String url;
  final String feeRate;
  final String transaction;
  final String transactions;
  final String sendTransaction;
  final APIType apiType;
  final BitcoinNetwork network;

  factory APIConfig.selectApi(APIType apiType, BitcoinNetwork network) {
    switch (apiType) {
      case APIType.mempool:
        return APIConfig.mempool(network);
      default:
        return APIConfig.mempool(network);
    }
  }

  String getUtxoUrl(String address) {
    String baseUrl = url;
    return baseUrl.replaceAll("###", address);
  }

  String getFeeApiUrl() {
    return feeRate;
  }

  String getTransactionUrl(String transactionId) {
    String baseUrl = transaction;
    return baseUrl.replaceAll("###", transactionId);
  }

  String getTransactionsUrl(String address) {
    String baseUrl = transactions;
    return baseUrl.replaceAll("###", address);
  }

  factory APIConfig.fromBlockCypher(BitcoinNetwork network) {
    String baseUrl = network.isMainnet
        ? BtcApiConst.blockCypherMainBaseURL
        : BtcApiConst.blockCypherBaseURL;

    return APIConfig(
      url: "$baseUrl/addrs/###/?unspentOnly=true&includeScript=true&limit=2000",
      feeRate: baseUrl,
      transaction: "$baseUrl/txs/###",
      sendTransaction: "$baseUrl/txs/push",
      apiType: APIType.blockCypher,
      transactions: "$baseUrl/addrs/###/full?limit=200",
      network: network,
    );
  }

  factory APIConfig.mempool(BitcoinNetwork network) {
    String baseUrl = network.isMainnet
        ? BtcApiConst.mempoolMainBaseURL
        : BtcApiConst.mempoolBaseURL;

    return APIConfig(
      url: "$baseUrl/address/###/utxo",
      feeRate: "$baseUrl/v1/fees/recommended",
      transaction: "$baseUrl/tx/###",
      sendTransaction: "$baseUrl/tx",
      apiType: APIType.mempool,
      transactions: "$baseUrl/address/###/txs",
      network: network,
    );
  }

  APIConfig({
    required this.url,
    required this.feeRate,
    required this.transaction,
    required this.transactions,
    required this.sendTransaction,
    required this.apiType,
    required this.network,
  });
}
