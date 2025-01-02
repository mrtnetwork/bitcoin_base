part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

abstract class LegacyAddress implements BitcoinBaseAddress {
  /// Represents a Bitcoin address
  ///
  /// [addressProgram] the addressProgram string representation of the address; hash160 represents
  /// two consequtive hashes of the public key or the redeam script or SHA256 for BCH(P2SH), first
  /// a SHA-256 and then an RIPEMD-160
  LegacyAddress.fromHash160(String addrHash, BitcoinAddressType addressType)
      : _addressProgram =
            _BitcoinAddressUtils.validateAddressProgram(addrHash, addressType);
  LegacyAddress.fromAddress(
      {required String address, required BasedUtxoNetwork network}) {
    final decode = _BitcoinAddressUtils.decodeLagacyAddressWithNetworkAndType(
        address: address, type: type, network: network);
    if (decode == null) {
      throw DartBitcoinPluginException(
          'Invalid ${network.conf.coinName} address');
    }
    _addressProgram = decode;
  }
  LegacyAddress.fromScript({required Script script})
      : _addressProgram = _BitcoinAddressUtils.scriptToHash160(script);
  LegacyAddress._();

  late final String _addressProgram;

  @override
  String get addressProgram {
    if (type == PubKeyAddressType.p2pk) throw UnimplementedError();
    return _addressProgram;
  }

  @override
  String toAddress(BasedUtxoNetwork network) {
    return _BitcoinAddressUtils.legacyToAddress(
        network: network, addressProgram: addressProgram, type: type);
  }

  @override
  String pubKeyHash() {
    return _BitcoinAddressUtils.pubKeyHash(toScriptPubKey());
  }
}

class P2shAddress extends LegacyAddress {
  P2shAddress.fromScript(
      {required super.script, this.type = P2shAddressType.p2pkInP2sh})
      : super.fromScript();

  P2shAddress.fromAddress(
      {required super.address,
      required super.network,
      this.type = P2shAddressType.p2pkInP2sh})
      : super.fromAddress();
  P2shAddress.fromHash160(
      {required String addrHash, this.type = P2shAddressType.p2pkInP2sh})
      : super.fromHash160(addrHash, type);

  @override
  final P2shAddressType type;

  @override
  String toAddress(BasedUtxoNetwork network) {
    if (!network.supportedAddress.contains(type)) {
      throw DartBitcoinPluginException(
          'network does not support ${type.value} address');
    }
    return super.toAddress(network);
  }

  /// Returns the scriptPubKey (P2SH) that corresponds to this address
  @override
  Script toScriptPubKey() {
    if (addressProgram.length == 64) {
      return Script(script: ['OP_HASH256', addressProgram, 'OP_EQUAL']);
    }
    return Script(script: ['OP_HASH160', addressProgram, 'OP_EQUAL']);
  }
}

class P2pkhAddress extends LegacyAddress {
  P2pkhAddress.fromScript(
      {required super.script, this.type = P2pkhAddressType.p2pkh})
      : super.fromScript();
  P2pkhAddress.fromAddress(
      {required super.address,
      required super.network,
      this.type = P2pkhAddressType.p2pkh})
      : super.fromAddress();
  P2pkhAddress.fromHash160(
      {required String addrHash, this.type = P2pkhAddressType.p2pkh})
      : super.fromHash160(addrHash, type);

  @override
  Script toScriptPubKey() {
    return Script(script: [
      'OP_DUP',
      'OP_HASH160',
      addressProgram,
      'OP_EQUALVERIFY',
      'OP_CHECKSIG'
    ]);
  }

  @override
  final P2pkhAddressType type;
}

class P2pkAddress extends LegacyAddress {
  P2pkAddress({required String publicKey}) : super._() {
    final toBytes = BytesUtils.fromHexString(publicKey);
    if (!Secp256k1PublicKeyEcdsa.isValidBytes(toBytes)) {
      throw const DartBitcoinPluginException('Invalid secp256k1 public key');
    }
    publicHex = publicKey;
  }
  late final String publicHex;

  /// Returns the scriptPubKey (P2SH) that corresponds to this address
  @override
  Script toScriptPubKey() {
    return Script(script: [publicHex, 'OP_CHECKSIG']);
  }

  @override
  String toAddress(BasedUtxoNetwork network) {
    return _BitcoinAddressUtils.legacyToAddress(
        network: network,
        addressProgram: _BitcoinAddressUtils.pubkeyToHash160(publicHex),
        type: type);
  }

  @override
  final PubKeyAddressType type = PubKeyAddressType.p2pk;
}
