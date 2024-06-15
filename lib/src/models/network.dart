import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/utils/enumerate.dart';
import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip49/bip49_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip84/bip84_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip86/bip86_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip_coins.dart';
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

  static List<BasedUtxoNetwork> values = const [
    BitcoinNetwork.mainnet,
    BitcoinNetwork.testnet,
    LitecoinNetwork.mainnet,
    LitecoinNetwork.testnet,
    DashNetwork.mainnet,
    DashNetwork.testnet,
    DogecoinNetwork.mainnet,
    DogecoinNetwork.testnet,
    BitcoinCashNetwork.mainnet,
    BitcoinCashNetwork.testnet,
    BitcoinSVNetwork.mainnet,
    BitcoinSVNetwork.testnet
  ];

  static BasedUtxoNetwork fromName(String name) {
    return values.firstWhere((element) => element.value == name);
  }

  List<CryptoCoins> get coins;

  /// Checks if the current network is the mainnet.
  bool get isMainnet => this == BitcoinNetwork.mainnet;
}

/// Class representing a Bitcoin network, implementing the `BasedUtxoNetwork` abstract class.
class BitcoinSVNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const BitcoinSVNetwork mainnet =
      BitcoinSVNetwork._("BitcoinSVMainnet", CoinsConf.bitcoinSvMainNet);

  /// Testnet configuration with associated `CoinConf`.
  static const BitcoinSVNetwork testnet =
      BitcoinSVNetwork._("BitcoinSVTestnet", CoinsConf.bitcoinSvTestNet);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  @override
  final String value;

  /// Constructor for creating a Bitcoin network with a specific configuration.
  const BitcoinSVNetwork._(this.value, this.conf);

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
  @override
  bool get isMainnet => this == BitcoinSVNetwork.mainnet;

  @override
  List<BitcoinAddressType> get supportedAddress =>
      [P2pkhAddressType.p2pkh, PubKeyAddressType.p2pk];

  @override
  List<CryptoCoins> get coins {
    if (isMainnet) return [Bip44Coins.bitcoinSv];
    return [Bip44Coins.bitcoinSvTestnet];
  }
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
  @override
  bool get isMainnet => this == BitcoinNetwork.mainnet;

  @override
  List<BitcoinAddressType> get supportedAddress => [
        P2pkhAddressType.p2pkh,
        SegwitAddresType.p2wpkh,
        PubKeyAddressType.p2pk,
        SegwitAddresType.p2tr,
        SegwitAddresType.p2wsh,
        P2shAddressType.p2wshInP2sh,
        P2shAddressType.p2wpkhInP2sh,
        P2shAddressType.p2pkhInP2sh,
        P2shAddressType.p2pkInP2sh,
      ];

  @override
  List<CryptoCoins> get coins {
    if (isMainnet) {
      return [
        Bip44Coins.bitcoin,
        Bip49Coins.bitcoin,
        Bip84Coins.bitcoin,
        Bip86Coins.bitcoin,
      ];
    }
    return [
      Bip44Coins.bitcoinTestnet,
      Bip49Coins.bitcoinTestnet,
      Bip84Coins.bitcoinTestnet,
      Bip86Coins.bitcoinTestnet,
    ];
  }
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
  @override
  bool get isMainnet => this == LitecoinNetwork.mainnet;

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    P2pkhAddressType.p2pkh,
    SegwitAddresType.p2wpkh,
    PubKeyAddressType.p2pk,
    SegwitAddresType.p2wsh,
    P2shAddressType.p2wshInP2sh,
    P2shAddressType.p2wpkhInP2sh,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh,
  ];

  @override
  List<CryptoCoins> get coins {
    if (isMainnet) {
      return [Bip44Coins.litecoin, Bip49Coins.litecoin, Bip84Coins.litecoin];
    }
    return [
      Bip44Coins.litecoinTestnet,
      Bip49Coins.litecoinTestnet,
      Bip84Coins.litecoinTestnet
    ];
  }
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
  @override
  bool get isMainnet => this == DashNetwork.mainnet;

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    PubKeyAddressType.p2pk,
    P2pkhAddressType.p2pkh,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh
  ];

  @override
  final String value;

  @override
  List<CryptoCoins> get coins {
    if (isMainnet) return [Bip44Coins.dash, Bip49Coins.dash];
    return [Bip44Coins.dashTestnet, Bip49Coins.dashTestnet];
  }
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
  @override
  bool get isMainnet => this == DogecoinNetwork.mainnet;

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    PubKeyAddressType.p2pk,
    P2pkhAddressType.p2pkh,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh
  ];

  @override
  List<CryptoCoins> get coins {
    if (isMainnet) return [Bip44Coins.dogecoin, Bip49Coins.dogecoin];
    return [Bip44Coins.dogecoinTestnet, Bip49Coins.dogecoinTestnet];
  }
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

  /// Retrieves the Pay-to-Public-Key-Hash-With-Token (P2PKHWT) version byte
  final List<int> p2pkhWtNetVer = const [0x10];

  /// Retrieves the Pay-to-Script-Hash (P2SH20) version bytes from the associated `CoinConf`.
  @override
  List<int> get p2shNetVer => conf.params.p2shStdNetVer!;

  /// Retrieves the Pay-to-Script-Hash (P2SH32) version bytes from the associated `CoinConf`.
  final List<int> p2sh32NetVer = const [0x0b];

  /// Retrieves the Pay-to-Script-Hash (P2SH20) version bytes from the associated `CoinConf`.
  final List<int> p2shwt20NetVer = const [0x18];

  /// Retrieves the Pay-to-Script-Hash (P2SH32) version bytes from the associated `CoinConf`.
  final List<int> p2shwt32NetVer = const [0x1b];

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
  /// from the associated `CoinConf`.
  @override
  String get p2wpkhHrp =>
      throw UnimplementedError("network does not support p2wpkh HRP");

  String get networkHRP => conf.params.p2pkhStdHrp!;

  /// Checks if the current network is the mainnet.
  @override
  bool get isMainnet => this == BitcoinCashNetwork.mainnet;

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    PubKeyAddressType.p2pk,
    P2pkhAddressType.p2pkh,
    P2pkhAddressType.p2pkhwt,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh,
    P2shAddressType.p2pkhInP2sh32,
    P2shAddressType.p2pkInP2sh32,
    P2shAddressType.p2pkhInP2sh32wt,
    P2shAddressType.p2pkInP2sh32wt,
    P2shAddressType.p2pkhInP2shwt,
    P2shAddressType.p2pkInP2shwt,
  ];

  @override
  List<CryptoCoins> get coins {
    if (isMainnet) return [Bip44Coins.bitcoinCash, Bip49Coins.bitcoinCash];
    return [Bip44Coins.bitcoinCashTestnet, Bip49Coins.bitcoinCashTestnet];
  }
}
