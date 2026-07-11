part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

abstract class LegacyAddress
    with CborTagSerializable, Equality
    implements BitcoinBaseAddress {
  /// Represents a Bitcoin address
  ///
  /// [addressProgram] the addressProgram string representation of the address; hash160 represents
  /// two consequtive hashes of the public key or the redeam script or SHA256 for BCH(P2SH), first
  /// a SHA-256 and then an RIPEMD-160
  LegacyAddress.fromHash160(String addrHash, BitcoinAddressType addressType)
    : _addressProgram = BitcoinAddressUtils.validateAddressProgram(
        addrHash,
        addressType,
      );
  LegacyAddress.fromAddress({
    required String address,
    required BasedUtxoNetwork network,
  }) {
    final decode = BitcoinAddressUtils.decodeLagacyAddressWithNetworkAndType(
      address: address,
      type: type,
      network: network,
    );
    if (decode == null) {
      throw DartBitcoinPluginException(
        'Invalid ${network.conf.coinName} address',
      );
    }
    _addressProgram = decode;
  }
  LegacyAddress.fromScript({required Script script})
    : _addressProgram = BitcoinAddressUtils.scriptToHash160(script);
  LegacyAddress();

  late final String _addressProgram;

  @override
  String get addressProgram {
    if (type == PubKeyAddressType.p2pk) {
      throw DartBitcoinPluginException(
        "addressProgram not supported by p2pk address.",
      );
    }
    return _addressProgram;
  }

  @override
  String toAddress(BasedUtxoNetwork network) {
    return BitcoinAddressUtils.legacyToAddress(
      network: network,
      addressProgram: addressProgram,
      type: type,
    );
  }

  @override
  String pubKeyHash() {
    return BitcoinAddressUtils.pubKeyHash(toScriptPubKey());
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      BlockchainNetwork.bitcoinAndRelated.identifier;

  @override
  List<CborObject?> get serializationItems => [
    type.id.toCbor(),
    CborBytesValue(BytesUtils.fromHexString(addressProgram)),
  ];
}

class P2shAddress extends LegacyAddress {
  factory P2shAddress.fromScript32({
    required Script script,
    P2shAddressType addressType = P2shAddressType.p2pkInP2sh32,
  }) {
    if (addressType.hashLength != 32) {
      throw DartBitcoinPluginException("Invalid P2sh 32 address type.");
    }
    return P2shAddress.fromHash160(
      addrHash: BytesUtils.toHexString(
        QuickCrypto.sha256DoubleHash(script.toBytes()),
      ),
      type: addressType,
    );
  }
  P2shAddress.fromScript({
    required super.script,
    this.type = P2shAddressType.p2pkInP2sh,
  }) : super.fromScript();

  P2shAddress.fromAddress({
    required super.address,
    required super.network,
    this.type = P2shAddressType.p2pkInP2sh,
  }) : super.fromAddress();
  P2shAddress.fromHash160({
    required String addrHash,
    this.type = P2shAddressType.p2pkInP2sh,
  }) : super.fromHash160(addrHash, type);

  @override
  final P2shAddressType type;

  @override
  String toAddress(BasedUtxoNetwork network) {
    if (!network.supportedAddress.contains(type)) {
      throw DartBitcoinPluginException(
        'network does not support ${type.name} address.',
      );
    }
    return super.toAddress(network);
  }

  /// Returns the scriptPubKey (P2SH) that corresponds to this address
  @override
  Script toScriptPubKey() {
    if (addressProgram.length == QuickCrypto.sha256DigestSize * 2) {
      return Script(
        script: [
          BitcoinOpcode.opHash256,
          addressProgram,
          BitcoinOpcode.opEqual,
        ],
      );
    }
    return Script(
      script: [BitcoinOpcode.opHash160, addressProgram, BitcoinOpcode.opEqual],
    );
  }

  @override
  List<dynamic> get variables => [_addressProgram];
}

class P2pkhAddress extends LegacyAddress {
  P2pkhAddress.fromScript({
    required super.script,
    this.type = P2pkhAddressType.p2pkh,
  }) : super.fromScript();
  P2pkhAddress.fromAddress({
    required super.address,
    required super.network,
    this.type = P2pkhAddressType.p2pkh,
  }) : super.fromAddress();
  P2pkhAddress.fromHash160({
    required String addrHash,
    this.type = P2pkhAddressType.p2pkh,
  }) : super.fromHash160(addrHash, type);

  @override
  Script toScriptPubKey() {
    return Script(
      script: [
        BitcoinOpcode.opDup,
        BitcoinOpcode.opHash160,
        addressProgram,
        BitcoinOpcode.opEqualVerify,
        BitcoinOpcode.opCheckSig,
      ],
    );
  }

  @override
  final P2pkhAddressType type;

  @override
  List<dynamic> get variables => [addressProgram];
}

class P2pkAddress extends LegacyAddress {
  P2pkAddress._(this.publicKey) : super();
  factory P2pkAddress({required String publicKey}) {
    final toBytes = BytesUtils.fromHexString(publicKey);
    if (!Secp256k1PublicKey.isValidBytes(toBytes)) {
      throw const DartBitcoinPluginException('Invalid Public key.');
    }
    return P2pkAddress._(StringUtils.strip0x(publicKey.toLowerCase()));
  }
  final String publicKey;

  @override
  Script toScriptPubKey() {
    return Script(script: [publicKey, BitcoinOpcode.opCheckSig]);
  }

  @override
  String toAddress(BasedUtxoNetwork network) {
    return BitcoinAddressUtils.legacyToAddress(
      network: network,
      addressProgram: BitcoinAddressUtils.pubkeyToHash160(publicKey),
      type: type,
    );
  }

  @override
  final PubKeyAddressType type = PubKeyAddressType.p2pk;
  @override
  List<dynamic> get variables => [publicKey];

  @override
  List<CborObject?> get serializationItems => [
    type.id.toCbor(),
    CborBytesValue(BytesUtils.fromHexString(publicKey)),
  ];
}
