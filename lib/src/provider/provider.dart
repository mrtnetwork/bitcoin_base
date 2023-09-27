// ignore_for_file: constant_identifier_names

import 'package:bitcoin_base/src/models/network.dart';

enum APIType {
  MempoolApi,
  BlockCypherApi,
}

class APIConfig {
  final String url;
  final String feeRate;
  final String transaction;
  final String transactions;
  final String sendTransaction;
  final APIType apiType;
  final NetworkInfo network;

  factory APIConfig.selectApi(APIType apiType, NetworkInfo network) {
    switch (apiType) {
      case APIType.MempoolApi:
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

  factory APIConfig.fromBlockCypher(NetworkInfo network) {
    String baseUrl =
        network.isMainnet ? blockCypherMainBaseURL : blockCypherBaseURL;

    return APIConfig(
      url: "$baseUrl/addrs/###/?unspentOnly=true&includeScript=true&limit=2000",
      feeRate: baseUrl,
      transaction: "$baseUrl/txs/###",
      sendTransaction: "$baseUrl/txs/push",
      apiType: APIType.BlockCypherApi,
      transactions: "$baseUrl/addrs/###/full?limit=200",
      network: network,
    );
  }

  factory APIConfig.mempool(NetworkInfo network) {
    String baseUrl = network.isMainnet ? mempoolMainBaseURL : mempoolBaseURL;

    return APIConfig(
      url: "$baseUrl/address/###/utxo",
      feeRate: "$baseUrl/v1/fees/recommended",
      transaction: "$baseUrl/tx/###",
      sendTransaction: "$baseUrl/tx",
      apiType: APIType.MempoolApi,
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

const String blockCypherBaseURL = "https://api.blockcypher.com/v1/btc/test3";
const String mempoolBaseURL = "https://mempool.space/testnet/api";
const String blockstreamBaseURL = "https://blockstream.info/testnet/api";

const String blockCypherMainBaseURL = "https://api.blockcypher.com/v1/btc/main";
const String mempoolMainBaseURL = "https://mempool.space/api";
const String blockstreamMainBaseURL = "https://blockstream.info/api";
