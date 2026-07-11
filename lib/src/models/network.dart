import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
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
abstract class BasedUtxoNetwork {
  /// List of version bytes for Wallet Import Format (WIF).
  abstract final List<int>? wifNetVer;

  /// List of version bytes for Pay-to-Public-Key-Hash (P2PKH).
  abstract final List<int>? p2pkhNetVer;

  /// List of version bytes for Pay-to-Script-Hash (P2SH).
  abstract final List<int>? p2shNetVer;

  /// Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses.
  abstract final String? p2wpkhHrp;

  /// Configuration object specific to the coin.
  abstract final CoinConf conf;

  abstract final List<BitcoinAddressType> supportedAddress;
  String get identifier;
  abstract final String name;
  abstract final int tag;

  static const List<BasedUtxoNetwork> values = [
    ...BitcoinNetwork.values,
    ...LitecoinNetwork.values,
    ...DashNetwork.values,
    ...DogecoinNetwork.values,
    ...BitcoinCashNetwork.values,
    ...BitcoinSVNetwork.values,
    ...PepeNetwork.values,
    ...ElectraProtocolNetwork.values,
    ...ZcashNetworkTransparent.values,
  ];

  static BasedUtxoNetwork fromName(String name) {
    return values.firstWhere(
      (element) => element.name == name,
      orElse:
          () =>
              throw DartBitcoinPluginException(
                "No matching network found for the given name.",
              ),
    );
  }

  static BasedUtxoNetwork fromTag(int tag) {
    return values.firstWhere(
      (element) => element.tag == tag,
      orElse:
          () =>
              throw DartBitcoinPluginException(
                "No matching network found for the given tag.",
              ),
    );
  }

  List<BipCoins> get coins;

  /// Checks if the current network is the mainnet.
  bool get isMainnet => this == BitcoinNetwork.mainnet;
}

/// Class representing a Bitcoin network, implementing the `BasedUtxoNetwork` abstract class.
enum BitcoinSVNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet(
    'BitcoinSVMainnet',
    CoinsConf.bitcoinSvMainNet,
    'bitcoinsv:mainnet',
    0,
  ),

  /// Testnet configuration with associated `CoinConf`.
  testnet(
    'BitcoinSVTestnet',
    CoinsConf.bitcoinSvTestNet,
    'bitcoinsv:testnet',
    1,
  );

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  @override
  final String name;

  @override
  final int tag;

  /// Constructor for creating a Bitcoin network with a specific configuration.
  const BitcoinSVNetwork(this.name, this.conf, this.identifier, this.tag);

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int>? get wifNetVer => conf.params.wifNetVer;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2pkhNetVer => conf.params.p2pkhNetVer;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2shNetVer => conf.params.p2shNetVer;

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
  /// from the associated `CoinConf`.
  @override
  String? get p2wpkhHrp => conf.params.p2wpkhHrp;

  /// Checks if the current network is the mainnet.
  @override
  bool get isMainnet => this == BitcoinSVNetwork.mainnet;

  @override
  List<BitcoinAddressType> get supportedAddress => [
    P2pkhAddressType.p2pkh,
    PubKeyAddressType.p2pk,
  ];

  @override
  List<BipCoins> get coins {
    if (isMainnet) return [Bip44Coins.bitcoinSv];
    return [Bip44Coins.bitcoinSvTestnet];
  }

  @override
  final String identifier;
}

/// Class representing a Bitcoin network, implementing the `BasedUtxoNetwork` abstract class.
enum BitcoinNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet('bitcoinMainnet', CoinsConf.bitcoinMainNet, 'bitcoin:mainnet', 2),

  /// Testnet configuration with associated `CoinConf`.
  testnet('bitcoinTestnet', CoinsConf.bitcoinTestNet, 'bitcoin:testnet', 3),

  /// Testnet4 configuration with associated `CoinConf`.
  testnet4('bitcoinTestnet4', CoinsConf.bitcoinTestNet, 'bitcoin:testnet4', 4),

  /// Signet configuration with associated `CoinConf`.
  signet('bitcoinSignet', CoinsConf.bitcoinTestNet, 'bitcoin:signet', 5);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  @override
  final String name;
  @override
  final int tag;

  /// Constructor for creating a Bitcoin network with a specific configuration.
  const BitcoinNetwork(this.name, this.conf, this.identifier, this.tag);

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int>? get wifNetVer => conf.params.wifNetVer;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2pkhNetVer => conf.params.p2pkhNetVer;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2shNetVer => conf.params.p2shNetVer;

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
  /// from the associated `CoinConf`.
  @override
  String? get p2wpkhHrp => conf.params.p2wpkhHrp;

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
enum LitecoinNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet('litecoinMainnet', CoinsConf.litecoinMainNet, 'litecoin:mainnet', 6),

  /// Testnet configuration with associated `CoinConf`.
  testnet('litecoinTestnet', CoinsConf.litecoinTestNet, 'litecoin:testnet', 7);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;
  @override
  final String name;
  @override
  final int tag;

  /// Constructor for creating a Litecoin network with a specific configuration.
  const LitecoinNetwork(this.name, this.conf, this.identifier, this.tag);

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int>? get wifNetVer => conf.params.wifNetVer;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2pkhNetVer => conf.params.p2pkhStdNetVer;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2shNetVer => conf.params.p2shStdNetVer;

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
  /// from the associated `CoinConf`.
  @override
  String? get p2wpkhHrp => conf.params.p2wpkhHrp;

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
      Bip84Coins.litecoinTestnet,
    ];
  }

  @override
  final String identifier;
}

/// Class representing a Dash network, implementing the `BasedUtxoNetwork` abstract class.
enum DashNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet('dashMainnet', CoinsConf.dashMainNet, 'dash:mainnet', 8),

  /// Testnet configuration with associated `CoinConf`.
  testnet('dashTestnet', CoinsConf.dashTestNet, 'dash:testnet', 9);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;
  @override
  final int tag;

  /// Constructor for creating a Dash network with a specific configuration.
  const DashNetwork(this.name, this.conf, this.identifier, this.tag);

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int>? get wifNetVer => conf.params.wifNetVer;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2pkhNetVer => conf.params.p2pkhNetVer;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2shNetVer => conf.params.p2shNetVer;

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses.
  @override
  String? get p2wpkhHrp => null;

  /// Checks if the current network is the mainnet.
  @override
  bool get isMainnet => this == DashNetwork.mainnet;

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    PubKeyAddressType.p2pk,
    P2pkhAddressType.p2pkh,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh,
  ];

  @override
  final String name;

  @override
  List<BipCoins> get coins {
    if (isMainnet) return [Bip44Coins.dash, Bip49Coins.dash];
    return [Bip44Coins.dashTestnet, Bip49Coins.dashTestnet];
  }

  @override
  final String identifier;
}

/// Class representing a Dogecoin network, implementing the `BasedUtxoNetwork` abstract class.
enum DogecoinNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet('dogeMainnet', CoinsConf.dogecoinMainNet, 'dogecoin:mainnet', 10),

  /// Testnet configuration with associated `CoinConf`.
  testnet('dogeTestnet', CoinsConf.dogecoinTestNet, 'dogecoin:testnet', 11);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;
  @override
  final int tag;

  /// Constructor for creating a Dogecoin network with a specific configuration.
  const DogecoinNetwork(this.name, this.conf, this.identifier, this.tag);

  @override
  final String name;

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int>? get wifNetVer => conf.params.wifNetVer;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2pkhNetVer => conf.params.p2pkhNetVer;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2shNetVer => conf.params.p2shNetVer;

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses.
  @override
  String? get p2wpkhHrp => null;

  /// Checks if the current network is the mainnet.
  @override
  bool get isMainnet => this == DogecoinNetwork.mainnet;

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    PubKeyAddressType.p2pk,
    P2pkhAddressType.p2pkh,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh,
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
enum BitcoinCashNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet(
    'bitcoinCashMainnet',
    CoinsConf.bitcoinCashMainNet,
    'bitcoincash:mainnet',
    12,
  ),

  /// Testnet configuration with associated `CoinConf`.
  testnet(
    'bitcoinCashTestnet',
    CoinsConf.bitcoinCashTestNet,
    'bitcoincash:testnet',
    13,
  );

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Bitcoin Cash network with a specific configuration.
  const BitcoinCashNetwork(this.name, this.conf, this.identifier, this.tag);
  @override
  final String name;
  @override
  final int tag;

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int>? get wifNetVer => conf.params.wifNetVer;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2pkhNetVer => conf.params.p2pkhStdNetVer;

  /// Retrieves the Pay-to-Public-Key-Hash-With-Token (P2PKHWT) version byte
  final List<int> p2pkhWtNetVer = const [0x10];

  /// Retrieves the Pay-to-Script-Hash (P2SH20) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2shNetVer => conf.params.p2shStdNetVer;

  /// Retrieves the Pay-to-Script-Hash (P2SH32) version bytes from the associated `CoinConf`.
  final List<int> p2sh32NetVer = const [0x0b];

  /// Retrieves the Pay-to-Script-Hash (P2SH20) version bytes from the associated `CoinConf`.
  final List<int> p2shwt20NetVer = const [0x18];

  /// Retrieves the Pay-to-Script-Hash (P2SH32) version bytes from the associated `CoinConf`.
  final List<int> p2shwt32NetVer = const [0x1b];

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
  /// from the associated `CoinConf`.
  @override
  String? get p2wpkhHrp => null;

  String? get networkHRP => conf.params.p2pkhStdHrp;

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
enum PepeNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet('pepecoinMainnet', CoinsConf.pepeMainnet, 'pepecoin:mainnet', 14);

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;

  /// Constructor for creating a Dogecoin network with a specific configuration.
  const PepeNetwork(this.name, this.conf, this.identifier, this.tag);

  @override
  final String name;
  @override
  final int tag;

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int>? get wifNetVer => conf.params.wifNetVer;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2pkhNetVer => conf.params.p2pkhNetVer;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2shNetVer => conf.params.p2shNetVer;

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses.
  @override
  String? get p2wpkhHrp => null;

  /// Checks if the current network is the mainnet.
  @override
  bool get isMainnet => true;

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    PubKeyAddressType.p2pk,
    P2pkhAddressType.p2pkh,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh,
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
enum ElectraProtocolNetwork implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet(
    'electraProtocolMainnet',
    CoinsConf.electraProtocolMainNet,
    'electra:mainnet',
    15,
  ),

  /// Testnet configuration with associated `CoinConf`.
  testnet(
    'electraProtocolTestnet',
    CoinsConf.electraProtocolTestNet,
    'electra:testnet',
    16,
  );

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;
  @override
  final String name;
  @override
  final int tag;

  /// Constructor for creating a Electra Protocol network with a specific configuration.
  const ElectraProtocolNetwork(this.name, this.conf, this.identifier, this.tag);

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int>? get wifNetVer => conf.params.wifNetVer;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2pkhNetVer => conf.params.p2pkhNetVer;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2shNetVer => conf.params.p2shNetVer;

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
  /// from the associated `CoinConf`.
  @override
  String? get p2wpkhHrp => conf.params.p2wpkhHrp;

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
        Bip84Coins.electraProtocol,
      ];
    }
    return [
      Bip44Coins.electraProtocolTestnet,
      Bip49Coins.electraProtocolTestnet,
      Bip84Coins.electraProtocolTestnet,
    ];
  }

  @override
  final String identifier;
}

/// Class representing a Zcash network, implementing the `BasedUtxoNetwork` abstract class.
enum ZcashNetworkTransparent implements BasedUtxoNetwork {
  /// Mainnet configuration with associated `CoinConf`.
  mainnet(
    'zcashMainnet',
    CoinsConf.zcashTransparentMainNet,
    'zcash:mainnet',
    17,
  ),

  /// Testnet configuration with associated `CoinConf`.
  testnet(
    'zcashTestnet',
    CoinsConf.zcashTransparentTestNet,
    'zcash:testnet',
    18,
  ),

  /// Testnet configuration with associated `CoinConf`.
  regtest(
    'zcashRegtest',
    CoinsConf.zcashTransparentRegtest,
    'zcash:regtest',
    19,
  );

  /// Overrides the `conf` property from `BasedUtxoNetwork` with the associated `CoinConf`.
  @override
  final CoinConf conf;
  @override
  final String name;

  @override
  final String identifier;
  @override
  final int tag;

  /// Constructor for creating a Zcash network with a specific configuration.
  const ZcashNetworkTransparent(
    this.name,
    this.conf,
    this.identifier,
    this.tag,
  );

  /// Retrieves the Wallet Import Format (WIF) version bytes from the associated `CoinConf`.
  @override
  List<int>? get wifNetVer => conf.params.wifNetVer;

  /// Retrieves the Pay-to-Public-Key-Hash (P2PKH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2pkhNetVer => conf.params.p2pkhNetVer;

  /// Retrieves the Pay-to-Script-Hash (P2SH) version bytes from the associated `CoinConf`.
  @override
  List<int>? get p2shNetVer => conf.params.p2shNetVer;

  /// Retrieves the Human-Readable Part (HRP) for Pay-to-Witness-Public-Key-Hash (P2WPKH) addresses
  /// from the associated `CoinConf`.
  @override
  String? get p2wpkhHrp => conf.params.p2wpkhHrp;

  /// Checks if the current network is the mainnet.
  @override
  bool get isMainnet => this == ZcashNetworkTransparent.mainnet;

  @override
  final List<BitcoinAddressType> supportedAddress = const [
    P2pkhAddressType.p2pkh,
    PubKeyAddressType.p2pk,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh,
  ];

  @override
  List<BipCoins> get coins {
    switch (this) {
      case ZcashNetworkTransparent.mainnet:
        return [Bip44Coins.zcash, Bip49Coins.zcash];
      case ZcashNetworkTransparent.testnet:
        return [Bip44Coins.zcashTestnet, Bip49Coins.zcashTestnet];
      case ZcashNetworkTransparent.regtest:
        return [Bip44Coins.zcashRegtest, Bip49Coins.zcashRegtest];
    }
  }
}
