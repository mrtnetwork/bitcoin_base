import 'package:bitcoin_base/bitcoin_base.dart';

enum APIType { mempool, blockCypher }

class BtcApiConst {
  static const String blockCypherBaseURL =
      'https://api.blockcypher.com/v1/btc/test3';
  static const String mempoolBaseURL = 'https://mempool.space/testnet/api';
  static const String mempoolTestnet4BaseURL =
      'https://mempool.space/testnet4/api';
  static const String mempoolSignetBaseURL = 'https://mempool.space/signet/api';
  static const String blockstreamBaseURL =
      'https://blockstream.info/testnet/api';
  static const String blockCypherMainBaseURL =
      'https://api.blockcypher.com/v1/btc/main';
  static const String mempoolMainBaseURL = 'https://mempool.space/api';
  static const String blockstreamMainBaseURL = 'https://blockstream.info/api';
  //
  static const String blockCypherDashBaseUri =
      'https://api.blockcypher.com/v1/dash/main';
  static const String blockCypherDogeBaseUri =
      'https://api.blockcypher.com/v1/doge/main';
  static const String blockCypherLitecoinBaseUri =
      'https://api.blockcypher.com/v1/ltc/main';

  static String getUrl(BasedUtxoNetwork network, APIType type) {
    String? baseUrl;
    if (type == APIType.mempool) {
      switch (network) {
        case BitcoinNetwork.mainnet:
          baseUrl ??= BtcApiConst.mempoolMainBaseURL;
          break;
        case BitcoinNetwork.testnet:
          baseUrl ??= BtcApiConst.mempoolBaseURL;
          break;
        case BitcoinNetwork.testnet4:
          baseUrl ??= BtcApiConst.mempoolTestnet4BaseURL;
          break;
        case BitcoinNetwork.signet:
          baseUrl ??= BtcApiConst.mempoolSignetBaseURL;
          break;
        default:
          break;
      }
    } else {
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
          break;
      }
    }
    if (baseUrl == null) {
      throw DartBitcoinPluginException('Unsupported network provider api.');
    }
    return baseUrl;
  }
}
