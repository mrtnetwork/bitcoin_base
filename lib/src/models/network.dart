import 'package:blockchain_utils/bip/coin_conf/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';

enum BitcoinNetwork {
  mainnet(CoinsConf.bitcoinMainNet),
  testnet(CoinsConf.bitcoinTestNet);

  final CoinConf _conf;
  const BitcoinNetwork(this._conf);

  List<int> get wifNetVer => _conf.params.wifNetVer!;
  List<int> get p2pkhNetVer => _conf.params.p2pkhNetVer!;
  List<int> get p2shNetVer => _conf.params.p2shNetVer!;
  String get p2wpkhHrp => _conf.params.p2wpkhHrp!;

  bool get isMainnet => this == BitcoinNetwork.mainnet;
}
