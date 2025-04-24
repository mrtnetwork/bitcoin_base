import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/utils/enumerate.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class MessagePrefixes {
  static const String bitcoinMainnet = "\x18Bitcoin Signed Message:\n";
  static const String litecoinMainnet = "\x19Litecoin Signed Message:\n";
  static const String dashMainnet = "\x19DarkCoin Signed Message:\n";
  static const String dogecoinMainnet = "\x19Dogecoin Signed Message:\n";
  static const String bitcoinCashMainnet = "\x1cBitcoin Cash Signed Message:\n";
  static const String bitcoinSVMainnet = "\x18Bitcoin Signed Message:\n";
  static const String pepeMainnet = "\x15Pepe Signed Message:\n";
  static const String electraProtocolMainnet =
      "\x20Electra Protocol Signed Message:\n";
}

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
  String get identifier;
  @override
  bool operator ==(other) {
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
    BitcoinNetwork.testnet4,
    LitecoinNetwork.mainnet,
    LitecoinNetwork.testnet,
    DashNetwork.mainnet,
    DashNetwork.testnet,
    DogecoinNetwork.mainnet,
    DogecoinNetwork.testnet,
    BitcoinCashNetwork.mainnet,
    BitcoinCashNetwork.testnet,
    BitcoinSVNetwork.mainnet,
    BitcoinSVNetwork.testnet,
    PepeNetwork.mainnet,
    ElectraProtocolNetwork.mainnet,
    ElectraProtocolNetwork.testnet
  ];

  static BasedUtxoNetwork fromName(String name) {
    return values.firstWhere((element) => element.value == name,
        orElse: () => throw DartBitcoinPluginException(
            "No matching network found for the given name."));
  }

  List<BipCoins> get coins;

  /// Checks if the current network is the mainnet.
  bool get isMainnet => this == BitcoinNetwork.mainnet;
}

/// Class representing a Bitcoin network, implementing the `BasedUtxoNetwork` abstract class.
class BitcoinSVNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const BitcoinSVNetwork mainnet = BitcoinSVNetwork._(
      'BitcoinSVMainnet', CoinsConf.bitcoinSvMainNet, 'bitcoinsv:mainnet');

  /// Testnet configuration with associated `CoinConf`.
  static const BitcoinSVNetwork testnet = BitcoinSVNetwork._(
      'BitcoinSVTestnet', CoinsConf.bitcoinSvTestNet, 'bitcoinsv:testnet');

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  @override
  final String value;

  /// Constructor for creating a Bitcoin network with a specific configuration.
  const BitcoinSVNetwork._(this.value, this.conf, this.identifier);

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
  List<BipCoins> get coins {
    if (isMainnet) return [Bip44Coins.bitcoinSv];
    return [Bip44Coins.bitcoinSvTestnet];
  }

  @override
  final String identifier;
}

/// Class representing a Bitcoin network, implementing the `BasedUtxoNetwork` abstract class.
class BitcoinNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const BitcoinNetwork mainnet = BitcoinNetwork._(
      'bitcoinMainnet', CoinsConf.bitcoinMainNet, 'bitcoin:mainnet');

  /// Testnet configuration with associated `CoinConf`.
  static const BitcoinNetwork testnet = BitcoinNetwork._(
      'bitcoinTestnet', CoinsConf.bitcoinTestNet, 'bitcoin:testnet');

  /// Testnet4 configuration with associated `CoinConf`.
  static const BitcoinNetwork testnet4 = BitcoinNetwork._(
      'bitcoinTestnet4', CoinsConf.bitcoinTestNet, 'bitcoin:testnet4');

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  @override
  final String value;

  /// Constructor for creating a Bitcoin network with a specific configuration.
  const BitcoinNetwork._(this.value, this.conf, this.identifier);

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
        SegwitAddressType.p2wpkh,
        PubKeyAddressType.p2pk,
        SegwitAddressType.p2tr,
        SegwitAddressType.p2wsh,
        P2shAddressType.p2wshInP2sh,
        P2shAddressType.p2wpkhInP2sh,
        P2shAddressType.p2pkhInP2sh,
        P2shAddressType.p2pkInP2sh,
      ];

  @override
  List<BipCoins> get coins {
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

  @override
  final String identifier;
}

/// Class representing a Litecoin network, implementing the `BasedUtxoNetwork` abstract class.
class LitecoinNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const LitecoinNetwork mainnet = LitecoinNetwork._(
      'litecoinMainnet', CoinsConf.litecoinMainNet, 'litecoin:mainnet');

  /// Testnet configuration with associated `CoinConf`.
  static const LitecoinNetwork testnet = LitecoinNetwork._(
      'litecoinTestnet', CoinsConf.litecoinTestNet, 'litecoin:testnet');

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;
  @override
  final String value;

  /// Constructor for creating a Litecoin network with a specific configuration.
  const LitecoinNetwork._(this.value, this.conf, this.identifier);

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
    SegwitAddressType.p2wpkh,
    PubKeyAddressType.p2pk,
    SegwitAddressType.p2wsh,
    P2shAddressType.p2wshInP2sh,
    P2shAddressType.p2wpkhInP2sh,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh,
  ];

  @override
  List<BipCoins> get coins {
    if (isMainnet) {
      return [Bip44Coins.litecoin, Bip49Coins.litecoin, Bip84Coins.litecoin];
    }
    return [
      Bip44Coins.litecoinTestnet,
      Bip49Coins.litecoinTestnet,
      Bip84Coins.litecoinTestnet
    ];
  }

  @override
  final String identifier;
}

/// Class representing a Dash network, implementing the `BasedUtxoNetwork` abstract class.
class DashNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const DashNetwork mainnet =
      DashNetwork._('dashMainnet', CoinsConf.dashMainNet, 'dash:mainnet');

  /// Testnet configuration with associated `CoinConf`.
  static const DashNetwork testnet =
      DashNetwork._('dashTestnet', CoinsConf.dashTestNet, 'dash:testnet');

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Dash network with a specific configuration.
  const DashNetwork._(this.value, this.conf, this.identifier);

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
  String get p2wpkhHrp => throw const DartBitcoinPluginException(
      'DashNetwork network does not support P2WPKH/P2WSH');

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
  List<BipCoins> get coins {
    if (isMainnet) return [Bip44Coins.dash, Bip49Coins.dash];
    return [Bip44Coins.dashTestnet, Bip49Coins.dashTestnet];
  }

  @override
  final String identifier;
}

/// Class representing a Dogecoin network, implementing the `BasedUtxoNetwork` abstract class.
class DogecoinNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const DogecoinNetwork mainnet = DogecoinNetwork._(
      'dogeMainnet', CoinsConf.dogecoinMainNet, 'dogecoin:mainnet');

  /// Testnet configuration with associated `CoinConf`.
  static const DogecoinNetwork testnet = DogecoinNetwork._(
      'dogeTestnet', CoinsConf.dogecoinTestNet, 'dogecoin:testnet');

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Dogecoin network with a specific configuration.
  const DogecoinNetwork._(this.value, this.conf, this.identifier);

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
  String get p2wpkhHrp => throw const DartBitcoinPluginException(
      'DogecoinNetwork network does not support P2WPKH/P2WSH');

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
  List<BipCoins> get coins {
    if (isMainnet) return [Bip44Coins.dogecoin, Bip49Coins.dogecoin];
    return [Bip44Coins.dogecoinTestnet, Bip49Coins.dogecoinTestnet];
  }

  @override
  final String identifier;
}

/// Class representing a Bitcoin Cash network, implementing the `BasedUtxoNetwork` abstract class.
class BitcoinCashNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const BitcoinCashNetwork mainnet = BitcoinCashNetwork._(
      'bitcoinCashMainnet',
      CoinsConf.bitcoinCashMainNet,
      'bitcoincash:mainnet');

  /// Testnet configuration with associated `CoinConf`.
  static const BitcoinCashNetwork testnet = BitcoinCashNetwork._(
      'bitcoinCashTestnet',
      CoinsConf.bitcoinCashTestNet,
      'bitcoincash:testnet');

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Bitcoin Cash network with a specific configuration.
  const BitcoinCashNetwork._(this.value, this.conf, this.identifier);
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
  String get p2wpkhHrp => throw const DartBitcoinPluginException(
      'network does not support p2wpkh HRP');

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
  List<BipCoins> get coins {
    if (isMainnet) return [Bip44Coins.bitcoinCash, Bip49Coins.bitcoinCash];
    return [Bip44Coins.bitcoinCashTestnet, Bip49Coins.bitcoinCashTestnet];
  }

  @override
  final String identifier;
}

/// Class representing a Dogecoin network, implementing the `BasedUtxoNetwork` abstract class.
class PepeNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const PepeNetwork mainnet = PepeNetwork._(
      'pepecoinMainnet', CoinsConf.pepeMainnet, 'pepecoin:mainnet');

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Dogecoin network with a specific configuration.
  const PepeNetwork._(this.value, this.conf, this.identifier);

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
  String get p2wpkhHrp => throw const DartBitcoinPluginException(
      'DogecoinNetwork network does not support P2WPKH/P2WSH');

  /// Checks if the current network is the mainnet.
  @override
  bool get isMainnet => true;

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    PubKeyAddressType.p2pk,
    P2pkhAddressType.p2pkh,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh
  ];

  @override
  List<BipCoins> get coins {
    if (isMainnet) {
      return [Bip44Coins.pepecoin, Bip49Coins.pepecoin];
    }
    return [Bip44Coins.pepecoinTestnet, Bip49Coins.pepecoinTestnet];
  }

  @override
  final String identifier;
}

/// Class representing a Electra Protocol network, implementing the `BasedUtxoNetwork` abstract class.
class ElectraProtocolNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  static const ElectraProtocolNetwork mainnet = ElectraProtocolNetwork._(
      'electraProtocolMainnet',
      CoinsConf.electraProtocolMainNet,
      'electra:mainnet');

  /// Testnet configuration with associated `CoinConf`.
  static const ElectraProtocolNetwork testnet = ElectraProtocolNetwork._(
      'electraProtocolTestnet',
      CoinsConf.electraProtocolTestNet,
      'electra:testnet');

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;
  @override
  final String value;

  /// Constructor for creating a Electra Protocol network with a specific configuration.
  const ElectraProtocolNetwork._(this.value, this.conf, this.identifier);

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
  bool get isMainnet => this == ElectraProtocolNetwork.mainnet;

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    P2pkhAddressType.p2pkh,
    SegwitAddressType.p2wpkh,
    PubKeyAddressType.p2pk,
    SegwitAddressType.p2wsh,
    P2shAddressType.p2wshInP2sh,
    P2shAddressType.p2wpkhInP2sh,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh,
  ];

  @override
  List<BipCoins> get coins {
    if (isMainnet) {
      return [
        Bip44Coins.electraProtocol,
        Bip49Coins.electraProtocol,
        Bip84Coins.electraProtocol
      ];
    }
    return [
      Bip44Coins.electraProtocolTestnet,
      Bip49Coins.electraProtocolTestnet,
      Bip84Coins.electraProtocolTestnet
    ];
  }

  @override
  final String identifier;
}

// class BonkcoinNetwork implements BasedUtxoNetwork {
//   /// Mainnet configuration with associated `CoinConf`.
//   static const ElectraProtocolNetwork mainnet = ElectraProtocolNetwork._(
//       'BonkcoinMainnet', CoinsConf.electraProtocolMainNet, 'electra:mainnet');

//   /// Testnet configuration with associated `CoinConf`.
//   static const ElectraProtocolNetwork testnet = ElectraProtocolNetwork._(
//       'electraProtocolTestnet',
//       CoinsConf.electraProtocolTestNet,
//       'electra:testnet');

//   /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
//   @override
//   final CoinConf conf;
//   @override
//   final String value;

//   /// Constructor for creating a Electra Protocol network with a specific configuration.
//   const BonkcoinNetwork._(this.value, this.conf, this.identifier);

//   /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
//   @override
//   List<int> get wifNetVer => conf.params.wifNetVer!;

//   /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
//   @override
//   List<int> get p2pkhNetVer => conf.params.p2pkhNetVer!;

//   /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
//   @override
//   List<int> get p2shNetVer => conf.params.p2shNetVer!;

//   /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
//   /// from the associated `CoinConf`.
//   @override
//   String get p2wpkhHrp => conf.params.p2wpkhHrp!;

//   /// Checks if the current network is the mainnet.
//   @override
//   bool get isMainnet => this == ElectraProtocolNetwork.mainnet;

//   @override
//   final List<BitcoinAddressType> supportedAddress = const [
//     P2pkhAddressType.p2pkh,
//     SegwitAddressType.p2wpkh,
//     PubKeyAddressType.p2pk,
//     SegwitAddressType.p2wsh,
//     P2shAddressType.p2wshInP2sh,
//     P2shAddressType.p2wpkhInP2sh,
//     P2shAddressType.p2pkhInP2sh,
//     P2shAddressType.p2pkInP2sh,
//   ];

//   @override
//   List<BipCoins> get coins {
//     if (isMainnet) {
//       return [
//         Bip44Coins.electraProtocol,
//         Bip49Coins.electraProtocol,
//         Bip84Coins.electraProtocol
//       ];
//     }
//     return [
//       Bip44Coins.electraProtocolTestnet,
//       Bip49Coins.electraProtocolTestnet,
//       Bip84Coins.electraProtocolTestnet
//     ];
//   }

//   @override
//   final String identifier;
// }
