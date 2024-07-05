import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/provider/constant/constant.dart';

enum APIType { mempool, blockCypher }

class APIConfig {
  final String url;
  final String feeRate;
  final String transaction;
  final String transactions;
  final String sendTransaction;
  final APIType apiType;
  final BasedUtxoNetwork network;

  factory APIConfig.selectApi(APIType apiType, BasedUtxoNetwork network) {
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

  factory APIConfig.fromBlockCypher(BasedUtxoNetwork network) {
    String baseUrl;
    switch (network) {
      case BitcoinNetwork.mainnet:
        baseUrl = BtcApiConst.blockCypherMainBaseURL;
        break;
      case BitcoinNetwork.testnet:
        baseUrl = BtcApiConst.blockCypherBaseURL;
        break;
      case DashNetwork.mainnet:
        baseUrl = BtcApiConst.blockCypherDashBaseUri;
        break;
      case DogecoinNetwork.mainnet:
        baseUrl = BtcApiConst.blockCypherDogeBaseUri;
        break;
      case LitecoinNetwork.mainnet:
        baseUrl = BtcApiConst.blockCypherLitecoinBaseUri;
        break;
      default:
        throw BitcoinBasePluginException(
            "blockcypher does not support ${network.conf.coinName.name}, u must use your own provider");
    }

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

  factory APIConfig.mempool(BasedUtxoNetwork network) {
    String baseUrl;
    switch (network) {
      case BitcoinNetwork.mainnet:
        baseUrl = BtcApiConst.mempoolMainBaseURL;
        break;
      case BitcoinNetwork.testnet:
        baseUrl = BtcApiConst.mempoolBaseURL;
        break;
      default:
        throw BitcoinBasePluginException(
            "mempool does not support ${network.conf.coinName.name}");
    }

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
