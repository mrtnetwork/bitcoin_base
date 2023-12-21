import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/utils/enumerate.dart';
import 'package:blockchain_utils/bip/coin_conf/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';

/// Abstract class representing a base for UTXO-based cryptocurrency networks.
abstract class BasedUtxoNetwork implements Enumerate {
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

  abstract final List<BitcoinAddressType> supportedAddress;

  @override
  operator ==(other) {
    if (identical(other, this)) return true;
    return other is BasedUtxoNetwork &&
        other.runtimeType == runtimeType &&
        value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// Class representing a Bitcoin network, implementing the `BasedUtxoNetwork` abstract class.
class BitcoinNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const BitcoinNetwork mainnet =
      BitcoinNetwork._("bitcoinMainnet", CoinsConf.bitcoinMainNet);

  /// Testnet configuration with associated `CoinConf`.
  static const BitcoinNetwork testnet =
      BitcoinNetwork._("bitcoinTestnet", CoinsConf.bitcoinTestNet);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  @override
  final String value;

  /// Constructor for creating a Bitcoin network with a specific configuration.
  const BitcoinNetwork._(this.value, this.conf);

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

  @override
  List<BitcoinAddressType> get supportedAddress => BitcoinAddressType.values;
}

/// Class representing a Litecoin network, implementing the `BasedUtxoNetwork` abstract class.
class LitecoinNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const LitecoinNetwork mainnet =
      LitecoinNetwork._("litecoinMainnet", CoinsConf.litecoinMainNet);

  /// Testnet configuration with associated `CoinConf`.
  static const LitecoinNetwork testnet =
      LitecoinNetwork._("litecoinTestnet", CoinsConf.litecoinTestNet);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;
  @override
  final String value;

  /// Constructor for creating a Litecoin network with a specific configuration.
  const LitecoinNetwork._(this.value, this.conf);

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

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    BitcoinAddressType.p2pkh,
    BitcoinAddressType.p2wpkh,
    BitcoinAddressType.p2pk,
    BitcoinAddressType.p2wsh,
    BitcoinAddressType.p2wshInP2sh,
    BitcoinAddressType.p2wpkhInP2sh,
    BitcoinAddressType.p2pkhInP2sh,
    BitcoinAddressType.p2pkInP2sh,
  ];
}

/// Class representing a Dash network, implementing the `BasedUtxoNetwork` abstract class.
class DashNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const DashNetwork mainnet =
      DashNetwork._("dashMainnet", CoinsConf.dashMainNet);

  /// Testnet configuration with associated `CoinConf`.
  static const DashNetwork testnet =
      DashNetwork._("dashTestnet", CoinsConf.dashTestNet);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Dash network with a specific configuration.
  const DashNetwork._(this.value, this.conf);

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
  String get p2wpkhHrp => throw UnimplementedError(
      "DashNetwork network does not support P2WPKH/P2WSH");

  /// Checks if the current network is the mainnet.
  bool get isMainnet => this == DashNetwork.mainnet;

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    BitcoinAddressType.p2pk,
    BitcoinAddressType.p2pkh,
    BitcoinAddressType.p2pkhInP2sh,
    BitcoinAddressType.p2pkInP2sh
  ];

  @override
  final String value;
}

/// Class representing a Dogecoin network, implementing the `BasedUtxoNetwork` abstract class.
class DogecoinNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const DogecoinNetwork mainnet =
      DogecoinNetwork._("dogeMainnet", CoinsConf.dogecoinMainNet);

  /// Testnet configuration with associated `CoinConf`.
  static const DogecoinNetwork testnet =
      DogecoinNetwork._("dogeTestnet", CoinsConf.dogecoinTestNet);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Dogecoin network with a specific configuration.
  const DogecoinNetwork._(this.value, this.conf);

  @override
  final String value;

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
  String get p2wpkhHrp => throw UnimplementedError(
      "DogecoinNetwork network does not support P2WPKH/P2WSH");

  /// Checks if the current network is the mainnet.
  bool get isMainnet => this == DogecoinNetwork.mainnet;

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    BitcoinAddressType.p2pk,
    BitcoinAddressType.p2pkh,
    BitcoinAddressType.p2pkhInP2sh,
    BitcoinAddressType.p2pkInP2sh
  ];
}

/// Class representing a Bitcoin Cash network, implementing the `BasedUtxoNetwork` abstract class.
class BitcoinCashNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const BitcoinCashNetwork mainnet =
      BitcoinCashNetwork._("bitcoinCashMainnet", CoinsConf.bitcoinCashMainNet);

  /// Testnet configuration with associated `CoinConf`.
  static const BitcoinCashNetwork testnet =
      BitcoinCashNetwork._("bitcoinCashTestnet", CoinsConf.bitcoinCashTestNet);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Bitcoin Cash network with a specific configuration.
  const BitcoinCashNetwork._(this.value, this.conf);
  @override
  final String value;

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

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    BitcoinAddressType.p2pk,
    BitcoinAddressType.p2pkh,
    BitcoinAddressType.p2pkhInP2sh,
    BitcoinAddressType.p2pkInP2sh
  ];
}
