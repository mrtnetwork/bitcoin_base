part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

/// An abstract class representing a forked address for a specific network.
abstract class BitcoinNetworkAddress<T extends BasedUtxoNetwork> {
  const BitcoinNetworkAddress._(
      {required this.address,
      required this.network,
      required this.baseAddress});

  /// The underlying Bitcoin base address.
  final BitcoinBaseAddress baseAddress;

  /// Converts the address to a string representation for the specified network [T].
  String toAddress([T? updateNetwork]) {
    return updateNetwork == null
        ? address
        : baseAddress.toAddress(updateNetwork);
  }

  /// The type of the Bitcoin address.
  BitcoinAddressType get type => baseAddress.type;

  /// The string representation of the address.
  final String address;

  final T network;
}

/// A concrete implementation of [BitcoinNetworkAddress] for Bitcoin network.
class BitcoinAddress extends BitcoinNetworkAddress<BitcoinNetwork> {
  const BitcoinAddress._(
      BitcoinBaseAddress baseAddress, String address, BitcoinNetwork network)
      : super._(address: address, baseAddress: baseAddress, network: network);
  factory BitcoinAddress(String address,
      {BitcoinNetwork network = BitcoinNetwork.mainnet}) {
    return BitcoinAddress._(
        _BitcoinAddressUtils.decodeAddress(address, network), address, network);
  }
  factory BitcoinAddress.fromBaseAddress(BitcoinBaseAddress address,
      {BitcoinNetwork network = BitcoinNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return BitcoinAddress._(
        baseAddress, baseAddress.toAddress(network), network);
  }
}

/// A concrete implementation of [BitcoinNetworkAddress] for Doge network.
class DogeAddress extends BitcoinNetworkAddress<DogecoinNetwork> {
  const DogeAddress._(
      BitcoinBaseAddress baseAddress, String address, DogecoinNetwork network)
      : super._(address: address, baseAddress: baseAddress, network: network);
  factory DogeAddress(String address,
      {DogecoinNetwork network = DogecoinNetwork.mainnet}) {
    return DogeAddress._(
        _BitcoinAddressUtils.decodeAddress(address, network), address, network);
  }
  factory DogeAddress.fromBaseAddress(BitcoinBaseAddress address,
      {DogecoinNetwork network = DogecoinNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return DogeAddress._(baseAddress, baseAddress.toAddress(network), network);
  }
}

/// A concrete implementation of [BitcoinNetworkAddress] for Pepecoin network.
class PepeAddress extends BitcoinNetworkAddress<PepeNetwork> {
  const PepeAddress._(
      BitcoinBaseAddress baseAddress, String address, PepeNetwork network)
      : super._(address: address, network: network, baseAddress: baseAddress);
  factory PepeAddress(String address,
      {PepeNetwork network = PepeNetwork.mainnet}) {
    return PepeAddress._(
        _BitcoinAddressUtils.decodeAddress(address, network), address, network);
  }
  factory PepeAddress.fromBaseAddress(BitcoinBaseAddress address,
      {PepeNetwork network = PepeNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return PepeAddress._(baseAddress, baseAddress.toAddress(network), network);
  }
}

/// A concrete implementation of [BitcoinNetworkAddress] for Litecoin network.
class LitecoinAddress extends BitcoinNetworkAddress<LitecoinNetwork> {
  const LitecoinAddress._(
      BitcoinBaseAddress baseAddress, String address, LitecoinNetwork network)
      : super._(address: address, baseAddress: baseAddress, network: network);
  factory LitecoinAddress(String address,
      {LitecoinNetwork network = LitecoinNetwork.mainnet}) {
    return LitecoinAddress._(
        _BitcoinAddressUtils.decodeAddress(address, network), address, network);
  }
  factory LitecoinAddress.fromBaseAddress(BitcoinBaseAddress address,
      {LitecoinNetwork network = LitecoinNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return LitecoinAddress._(
        baseAddress, baseAddress.toAddress(network), network);
  }
}

/// A concrete implementation of [BitcoinNetworkAddress] for Bitcoin cash network.
class BitcoinCashAddress extends BitcoinNetworkAddress<BitcoinCashNetwork> {
  const BitcoinCashAddress._(BitcoinBaseAddress baseAddress, String address,
      BitcoinCashNetwork network)
      : super._(address: address, baseAddress: baseAddress, network: network);
  factory BitcoinCashAddress(String address,
      {BitcoinCashNetwork network = BitcoinCashNetwork.mainnet,
      bool validateNetworkPrefix = false}) {
    final decodeAddress = _BitcoinAddressUtils.decodeBchAddress(
        address, network,
        validateNetworkHRP: validateNetworkPrefix);
    if (decodeAddress == null) {
      throw DartBitcoinPluginException("Invalid ${network.value} address.");
    }
    return BitcoinCashAddress._(decodeAddress, address, network);
  }
  factory BitcoinCashAddress.fromBaseAddress(BitcoinBaseAddress address,
      {BitcoinCashNetwork network = BitcoinCashNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return BitcoinCashAddress._(
        baseAddress, baseAddress.toAddress(network), network);
  }

  @override
  String toAddress([BitcoinCashNetwork? updateNetwork, String? prefix]) {
    if (prefix != null) {
      return BchAddrConverter.convert(address, prefix, null);
    }
    return super.toAddress(updateNetwork);
  }
}

/// A concrete implementation of [BitcoinNetworkAddress] for Dash network.
class DashAddress extends BitcoinNetworkAddress<DashNetwork> {
  const DashAddress._(
      BitcoinBaseAddress baseAddress, String address, DashNetwork network)
      : super._(address: address, baseAddress: baseAddress, network: network);
  factory DashAddress(String address,
      {DashNetwork network = DashNetwork.mainnet}) {
    return DashAddress._(
        _BitcoinAddressUtils.decodeAddress(address, network), address, network);
  }
  factory DashAddress.fromBaseAddress(BitcoinBaseAddress address,
      {DashNetwork network = DashNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return DashAddress._(baseAddress, baseAddress.toAddress(network), network);
  }
}

/// A concrete implementation of [BitcoinNetworkAddress] for bitcoinSV network.
class BitcoinSVAddress extends BitcoinNetworkAddress<BitcoinSVNetwork> {
  const BitcoinSVAddress._(
      BitcoinBaseAddress baseAddress, String address, BitcoinSVNetwork network)
      : super._(address: address, baseAddress: baseAddress, network: network);
  factory BitcoinSVAddress(String address,
      {BitcoinSVNetwork network = BitcoinSVNetwork.mainnet}) {
    return BitcoinSVAddress._(
        _BitcoinAddressUtils.decodeAddress(address, network), address, network);
  }
  factory BitcoinSVAddress.fromBaseAddress(BitcoinBaseAddress address,
      {BitcoinSVNetwork network = BitcoinSVNetwork.mainnet}) {
    final baseAddress = _BitcoinAddressUtils.validateAddress(address, network);
    return BitcoinSVAddress._(
        baseAddress, baseAddress.toAddress(network), network);
  }
}

// 
