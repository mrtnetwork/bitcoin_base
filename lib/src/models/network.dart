import 'package:blockchain_utils/bip/coin_conf/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';

/// Abstract class representing a base for UTXO-based cryptocurrency networks.
abstract class BasedUtxoNetwork {
  /// List of version bytes for Wallet Import Format (WIF).
  abstract final List<int> wifNetVer;

  /// List of version bytes for Pay-to-Public-Key-Hash (P2PKH).
  abstract final List<int> p2pkhNetVer;

  /// List of version bytes for Pay-to-Script-Hash (P2SH).
  abstract final List<int> p2shNetVer;

  /// Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses.
  abstract final String p2wpkhHrp;

  /// Configuration object specific to the coin.
  abstract final CoinConf conf;
}

/// Enum representing different Bitcoin networks, implementing the `BasedUtxoNetwork` abstract class.
enum BitcoinNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet(CoinsConf.bitcoinMainNet),

  /// Testnet configuration with associated `CoinConf`.
  testnet(CoinsConf.bitcoinTestNet);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Bitcoin network with a specific configuration.
  const BitcoinNetwork(this.conf);

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int> get wifNetVer => conf.params.wifNetVer!;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int> get p2pkhNetVer => conf.params.p2pkhNetVer!;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
  @override
  List<int> get p2shNetVer => conf.params.p2shNetVer!;

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
  /// from the associated `CoinConf`.
  @override
  String get p2wpkhHrp => conf.params.p2wpkhHrp!;

  /// Checks if the current network is the mainnet.
  bool get isMainnet => this == BitcoinNetwork.mainnet;
}

/// Enum representing different Litecoin networks, implementing the `BasedUtxoNetwork` abstract class.
enum LitecoinNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet(CoinsConf.litecoinMainNet),

  /// Testnet configuration with associated `CoinConf`.
  testnet(CoinsConf.litecoinTestNet);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Litecoin network with a specific configuration.
  const LitecoinNetwork(this.conf);

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int> get wifNetVer => conf.params.wifNetVer!;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int> get p2pkhNetVer => conf.params.p2pkhStdNetVer!;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
  @override
  List<int> get p2shNetVer => conf.params.p2shStdNetVer!;

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
  /// from the associated `CoinConf`.
  @override
  String get p2wpkhHrp => conf.params.p2wpkhHrp!;

  /// Checks if the current network is the mainnet.
  bool get isMainnet => this == LitecoinNetwork.mainnet;
}

/// Enum representing different Dash networks, implementing the `BasedUtxoNetwork` abstract class.
enum DashNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet(CoinsConf.dashMainNet),

  /// Testnet configuration with associated `CoinConf`.
  testnet(CoinsConf.dashTestNet);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Dash network with a specific configuration.
  const DashNetwork(this.conf);

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int> get wifNetVer => conf.params.wifNetVer!;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int> get p2pkhNetVer => conf.params.p2pkhNetVer!;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
  @override
  List<int> get p2shNetVer => conf.params.p2shNetVer!;

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses.
  @override
  String get p2wpkhHrp =>
      throw UnimplementedError("{$name} network does not support P2WPKH/P2WSH");

  /// Checks if the current network is the mainnet.
  bool get isMainnet => this == DashNetwork.mainnet;
}

/// Enum representing different Dogecoin networks, implementing the `BasedUtxoNetwork` abstract class.
enum DogecoinNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet(CoinsConf.dogecoinMainNet),

  /// Testnet configuration with associated `CoinConf`.
  testnet(CoinsConf.dogecoinTestNet);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Dogecoin network with a specific configuration.
  const DogecoinNetwork(this.conf);

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int> get wifNetVer => conf.params.wifNetVer!;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int> get p2pkhNetVer => conf.params.p2pkhNetVer!;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
  @override
  List<int> get p2shNetVer => conf.params.p2shNetVer!;

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses.
  @override
  String get p2wpkhHrp =>
      throw UnimplementedError("{$name} network does not support P2WPKH/P2WSH");

  /// Checks if the current network is the mainnet.
  bool get isMainnet => this == DogecoinNetwork.mainnet;
}

/// Enum representing different Bitcoin Cash networks, implementing the `BasedUtxoNetwork` abstract class.
enum BitcoinCashNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet(CoinsConf.bitcoinCashMainNet),

  /// Testnet configuration with associated `CoinConf`.
  testnet(CoinsConf.bitcoinCashTestNet);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Bitcoin Cash network with a specific configuration.
  const BitcoinCashNetwork(this.conf);

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int> get wifNetVer => conf.params.wifNetVer!;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int> get p2pkhNetVer => conf.params.p2pkhStdNetVer!;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
  @override
  List<int> get p2shNetVer => conf.params.p2shNetVer!;

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
  /// from the associated `CoinConf`.
  @override
  String get p2wpkhHrp => conf.params.p2wpkhHrp!;

  /// Checks if the current network is the mainnet.
  bool get isMainnet => this == BitcoinCashNetwork.mainnet;
}
