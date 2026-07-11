part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

sealed class BitcoinAddressType {
  /// Factory method to create a BitcoinAddressType enum value from a name or value.
  static BitcoinAddressType fromName(String? name) {
    return values.firstWhere(
      (element) => element.name == name,
      orElse:
          () => throw DartBitcoinPluginException('Unknown address type. $name'),
    );
  }

  static BitcoinAddressType fromTag(int? tag) {
    return values.firstWhere(
      (element) => element.id == tag,
      orElse:
          () => throw DartBitcoinPluginException('Unknown address type. $tag'),
    );
  }

  // Enum values as a list for iteration
  static const List<BitcoinAddressType> values = [
    ...P2pkhAddressType.values,
    ...SegwitAddressType.values,
    ...P2shAddressType.values,
    ...PubKeyAddressType.values,
  ];

  /// Check if the address type is Pay-to-Script-Hash (P2SH).
  bool get isP2sh;
  bool get isSegwit;
  bool get isP2tr;
  int get hashLength;
  bool get isP2sh32;
  bool get supportBip137;
  bool get withToken;
  int get id;
  abstract final String name;
}

abstract class BitcoinBaseAddress with Equality, CborTagSerializable {
  const BitcoinBaseAddress();
  factory BitcoinBaseAddress.fromProgram({
    required String addressProgram,
    required BitcoinAddressType type,
  }) {
    if (type.isP2sh) {
      return P2shAddress.fromHash160(
        addrHash: addressProgram,
        type: type.cast(),
      );
    }
    return switch (type) {
      PubKeyAddressType.p2pk => P2pkAddress(publicKey: addressProgram),
      P2pkhAddressType.p2pkh || P2pkhAddressType.p2pkhwt =>
        P2pkhAddress.fromHash160(addrHash: addressProgram, type: type.cast()),
      SegwitAddressType.p2wpkh => P2wpkhAddress.fromProgram(
        program: addressProgram,
      ),
      SegwitAddressType.p2wsh => P2wshAddress.fromProgram(
        program: addressProgram,
      ),
      SegwitAddressType.p2tr => P2trAddress.fromProgram(
        program: addressProgram,
      ),
      _ => throw DartBitcoinPluginException("Unsuported bitcoin address type."),
    };
  }
  factory BitcoinBaseAddress.deserializeIAddress({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainNetwork.bitcoinAndRelated.identifier,
      cborBytes: bytes,
      cborObject: object,
    );
    return BitcoinBaseAddress.fromProgram(
      type: BitcoinAddressType.fromTag(values.rawValueAt(0)),
      addressProgram: BytesUtils.toHexString(values.rawValueAt(1)),
    );
  }

  /// deserializeIAddress

  BitcoinAddressType get type;
  String toAddress(BasedUtxoNetwork network);
  Script toScriptPubKey();
  String pubKeyHash();
  String get addressProgram;

  @override
  SerializationIdentifier get serializationIdentifier =>
      BlockchainNetwork.bitcoinAndRelated.identifier;

  @override
  List<CborObject?> get serializationItems => [
    type.id.toCbor(),
    CborBytesValue(BytesUtils.fromHexString(addressProgram)),
  ];
}

enum PubKeyAddressType implements BitcoinAddressType {
  p2pk('P2PK', 1);

  @override
  final int id;
  const PubKeyAddressType(this.name, this.id);

  @override
  bool get isP2sh => false;
  @override
  bool get isSegwit => false;

  @override
  int get hashLength => QuickCrypto.hash160DigestSize;

  @override
  final String name;

  @override
  bool get isP2sh32 => false;

  @override
  bool get isP2tr => false;

  @override
  bool get supportBip137 => false;

  @override
  bool get withToken => false;
}

enum P2pkhAddressType implements BitcoinAddressType {
  p2pkh('P2PKH', 2),
  p2pkhwt('P2PKHWT', 3);

  @override
  final int id;
  @override
  final String name;
  const P2pkhAddressType(this.name, this.id);

  @override
  bool get isP2sh => false;
  @override
  bool get isSegwit => false;

  @override
  int get hashLength => QuickCrypto.hash160DigestSize;

  @override
  bool get isP2sh32 => false;

  @override
  bool get isP2tr => false;

  @override
  bool get supportBip137 => true;

  @override
  bool get withToken => this == p2pkhwt;
}

enum P2shAddressType implements BitcoinAddressType {
  p2wshInP2sh('P2SH/P2WSH', BitcoinAddressUtils.hash160DigestLength, false, 4),
  p2wpkhInP2sh(
    'P2SH/P2WPKH',
    BitcoinAddressUtils.hash160DigestLength,
    false,
    5,
  ),
  p2pkhInP2sh('P2SH/P2PKH', BitcoinAddressUtils.hash160DigestLength, false, 6),

  p2pkInP2sh('P2SH/P2PK', BitcoinAddressUtils.hash160DigestLength, false, 7),

  /// specify BCH NETWORK for now!
  /// Pay-to-Script-Hash-32
  p2pkhInP2sh32('P2SH32/P2PKH', BitcoinAddressUtils.scriptHashLenght, false, 8),
  //// Pay-to-Script-Hash-32
  p2pkInP2sh32('P2SH32/P2PK', BitcoinAddressUtils.scriptHashLenght, false, 9),

  /// Pay-to-Script-Hash-32-with-token
  p2pkhInP2sh32wt(
    'P2SH32WT/P2PKH',
    BitcoinAddressUtils.scriptHashLenght,
    true,
    10,
  ),

  /// Pay-to-Script-Hash-32-with-token
  p2pkInP2sh32wt(
    'P2SH32WT/P2PK',
    BitcoinAddressUtils.scriptHashLenght,
    true,
    11,
  ),

  /// Pay-to-Script-Hash-with-token
  p2pkhInP2shwt(
    'P2SHWT/P2PKH',
    BitcoinAddressUtils.hash160DigestLength,
    true,
    12,
  ),

  /// Pay-to-Script-Hash-with-token
  p2pkInP2shwt(
    'P2SHWT/P2PK',
    BitcoinAddressUtils.hash160DigestLength,
    true,
    13,
  );

  @override
  final int hashLength;
  @override
  final bool withToken;
  @override
  final String name;
  @override
  final int id;
  const P2shAddressType(this.name, this.hashLength, this.withToken, this.id);

  @override
  bool get isP2sh => true;
  @override
  bool get isSegwit => false;

  @override
  bool get isP2sh32 => hashLength == QuickCrypto.sha256DigestSize;

  @override
  bool get isP2tr => false;

  @override
  bool get supportBip137 => this == p2wpkhInP2sh;
}

enum SegwitAddressType implements BitcoinAddressType {
  p2wpkh('P2WPKH', 14),
  p2tr('P2TR', 15),
  p2wsh('P2WSH', 16);

  @override
  final int id;
  @override
  final String name;
  const SegwitAddressType(this.name, this.id);

  @override
  bool get isP2sh => false;
  @override
  bool get isSegwit => true;

  @override
  bool get isP2tr => this == p2tr;

  @override
  int get hashLength {
    switch (this) {
      case SegwitAddressType.p2wpkh:
        return QuickCrypto.hash160DigestSize;
      default:
        return QuickCrypto.sha256DigestSize;
    }
  }

  @override
  bool get isP2sh32 => false;

  @override
  bool get supportBip137 => this == p2wpkh;

  @override
  bool get withToken => false;
}

extension ExtBitcoinAddressTypeCasting on BitcoinAddressType {
  T cast<T extends BitcoinAddressType>() {
    if (this is! T) {
      throw CastFailedException<T>(value: this);
    }
    return this as T;
  }
}
