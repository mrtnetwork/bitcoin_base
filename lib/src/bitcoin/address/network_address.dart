part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

/// An abstract class representing a forked address for a specific network.
abstract class BitcoinNetworkAddress<T extends BasedUtxoNetwork> {
  const BitcoinNetworkAddress();

  /// The underlying Bitcoin base address.
  abstract final BitcoinBaseAddress baseAddress;

  /// Converts the address to a string representation for the specified network [T].
  String toAddress([T? network]) {
    return network == null ? address : baseAddress.toAddress(network);
  }

  /// The type of the Bitcoin address.
  BitcoinAddressType get type => baseAddress.type;

  /// The string representation of the address.
  abstract final String address;
}

/// A concrete implementation of [BitcoinNetworkAddress] for Bitcoin network.
class BitcoinAddress extends BitcoinNetworkAddress<BitcoinNetwork> {
  const BitcoinAddress._(this.baseAddress, this.address);
  factory BitcoinAddress(String address,
      {BitcoinNetwork network = BitcoinNetwork.mainnet}) {
    return BitcoinAddress._(
        _BitcoinAddressUtils.decodeAddress(address, network), address);
  }
  factory BitcoinAddress.fromBaseAddress(BitcoinBaseAddress address,
      {DashNetwork network = DashNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return BitcoinAddress._(baseAddress, baseAddress.toAddress(network));
  }
  @override
  final BitcoinBaseAddress baseAddress;
  @override
  final String address;
}

/// A concrete implementation of [BitcoinNetworkAddress] for Doge network.
class DogeAddress extends BitcoinNetworkAddress<DogecoinNetwork> {
  const DogeAddress._(this.baseAddress, this.address);
  factory DogeAddress(String address,
      {DogecoinNetwork network = DogecoinNetwork.mainnet}) {
    return DogeAddress._(
        _BitcoinAddressUtils.decodeAddress(address, network), address);
  }
  factory DogeAddress.fromBaseAddress(BitcoinBaseAddress address,
      {DogecoinNetwork network = DogecoinNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return DogeAddress._(baseAddress, baseAddress.toAddress(network));
  }
  @override
  final BitcoinBaseAddress baseAddress;

  @override
  final String address;
}

/// A concrete implementation of [BitcoinNetworkAddress] for Pepecoin network.
class PepeAddress extends BitcoinNetworkAddress<PepeNetwork> {
  const PepeAddress._(this.baseAddress, this.address);
  factory PepeAddress(String address,
      {PepeNetwork network = PepeNetwork.mainnet}) {
    return PepeAddress._(
        _BitcoinAddressUtils.decodeAddress(address, network), address);
  }
  factory PepeAddress.fromBaseAddress(BitcoinBaseAddress address,
      {PepeNetwork network = PepeNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return PepeAddress._(baseAddress, baseAddress.toAddress(network));
  }
  @override
  final BitcoinBaseAddress baseAddress;

  @override
  final String address;
}

/// A concrete implementation of [BitcoinNetworkAddress] for Litecoin network.
class LitecoinAddress extends BitcoinNetworkAddress<LitecoinNetwork> {
  LitecoinAddress._(this.baseAddress, this.address);
  factory LitecoinAddress(String address,
      {LitecoinNetwork network = LitecoinNetwork.mainnet}) {
    return LitecoinAddress._(
        _BitcoinAddressUtils.decodeAddress(address, network), address);
  }
  factory LitecoinAddress.fromBaseAddress(BitcoinBaseAddress address,
      {LitecoinNetwork network = LitecoinNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return LitecoinAddress._(baseAddress, baseAddress.toAddress(network));
  }
  @override
  final BitcoinBaseAddress baseAddress;
  @override
  final String address;
}

/// A concrete implementation of [BitcoinNetworkAddress] for Bitcoin cash network.
class BitcoinCashAddress extends BitcoinNetworkAddress<BitcoinCashNetwork> {
  const BitcoinCashAddress._(this.baseAddress, this.address);
  factory BitcoinCashAddress(String address,
      {BitcoinCashNetwork network = BitcoinCashNetwork.mainnet,
      bool validateNetworkPrefix = false}) {
    final decodeAddress = _BitcoinAddressUtils.decodeBchAddress(
        address, network,
        validateNetworkHRP: validateNetworkPrefix);
    if (decodeAddress == null) {
      throw BitcoinBasePluginException("Invalid ${network.value} address.");
    }
    return BitcoinCashAddress._(decodeAddress, address);
  }
  factory BitcoinCashAddress.fromBaseAddress(BitcoinBaseAddress address,
      {BitcoinCashNetwork network = BitcoinCashNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return BitcoinCashAddress._(baseAddress, baseAddress.toAddress(network));
  }
  @override
  final BitcoinBaseAddress baseAddress;
  @override
  final String address;

  @override
  String toAddress([BitcoinCashNetwork? network, String? prefix]) {
    if (prefix != null) {
      return BchAddrConverter.convert(address, prefix, null);
    }
    return super.toAddress(network);
  }
}

/// A concrete implementation of [BitcoinNetworkAddress] for Dash network.
class DashAddress extends BitcoinNetworkAddress<DashNetwork> {
  const DashAddress._(this.baseAddress, this.address);
  factory DashAddress(String address,
      {DashNetwork network = DashNetwork.mainnet}) {
    return DashAddress._(
        _BitcoinAddressUtils.decodeAddress(address, network), address);
  }
  factory DashAddress.fromBaseAddress(BitcoinBaseAddress address,
      {DashNetwork network = DashNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return DashAddress._(baseAddress, baseAddress.toAddress(network));
  }
  @override
  final BitcoinBaseAddress baseAddress;
  @override
  final String address;
}

/// A concrete implementation of [BitcoinNetworkAddress] for bitcoinSV network.
class BitcoinSVAddress extends BitcoinNetworkAddress<DashNetwork> {
  const BitcoinSVAddress._(this.baseAddress, this.address);
  factory BitcoinSVAddress(String address,
      {BitcoinSVNetwork network = BitcoinSVNetwork.mainnet}) {
    return BitcoinSVAddress._(
        _BitcoinAddressUtils.decodeAddress(address, network), address);
  }
  factory BitcoinSVAddress.fromBaseAddress(BitcoinBaseAddress address,
      {BitcoinSVNetwork network = BitcoinSVNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return BitcoinSVAddress._(baseAddress, baseAddress.toAddress(network));
  }
  @override
  final BitcoinBaseAddress baseAddress;
  @override
  final String address;
}
