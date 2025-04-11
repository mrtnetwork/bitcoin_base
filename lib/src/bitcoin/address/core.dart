part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

abstract class BitcoinAddressType implements Enumerate {
  @override
  final String value;

  const BitcoinAddressType._(this.value);

  /// Factory method to create a BitcoinAddressType enum value from a name or value.
  static BitcoinAddressType fromValue(String? value) {
    return values.firstWhere((element) => element.value == value,
        orElse: () =>
            throw DartBitcoinPluginException('Unknown address type. $value'));
  }

  /// Check if the address type is Pay-to-Script-Hash (P2SH).
  bool get isP2sh;
  bool get isSegwit;
  bool get isP2tr => false;
  int get hashLength;
  bool get isP2sh32 => isP2sh && hashLength == 32;

  bool get supportBip137 => switch (this) {
        P2pkhAddressType.p2pkh || P2pkhAddressType.p2pkhwt => true,
        P2shAddressType.p2wpkhInP2sh => true,
        SegwitAddressType.p2wpkh => true,
        _ => false
      };

  // Enum values as a list for iteration
  static const List<BitcoinAddressType> values = [
    P2pkhAddressType.p2pkh,
    SegwitAddressType.p2wpkh,
    SegwitAddressType.p2tr,
    SegwitAddressType.p2wsh,
    P2shAddressType.p2wshInP2sh,
    P2shAddressType.p2wpkhInP2sh,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh,
    P2shAddressType.p2pkhInP2sh32,
    P2shAddressType.p2pkInP2sh32,
    P2shAddressType.p2pkhInP2sh32wt,
    P2shAddressType.p2pkInP2sh32wt,
    P2shAddressType.p2pkhInP2shwt,
    P2shAddressType.p2pkInP2shwt,
    P2pkhAddressType.p2pkhwt
  ];
  T cast<T extends BitcoinAddressType>() {
    if (this is! T) {
      throw DartBitcoinPluginException(
          "Invalid cast: expected ${T.runtimeType}, but found $runtimeType.",
          details: {'expected': '$T', 'type': value});
    }
    return this as T;
  }

  @override
  String toString() {
    return 'BitcoinAddressType.$value';
  }
}

abstract class BitcoinBaseAddress {
  const BitcoinBaseAddress();
  factory BitcoinBaseAddress.fromProgram(
      {required String addressProgram, required BitcoinAddressType type}) {
    if (type.isP2sh) {
      return P2shAddress.fromHash160(
          addrHash: addressProgram, type: type.cast());
    }
    return switch (type) {
      PubKeyAddressType.p2pk => P2pkAddress(publicKey: addressProgram),
      P2pkhAddressType.p2pkh ||
      P2pkhAddressType.p2pkhwt =>
        P2pkhAddress.fromHash160(addrHash: addressProgram, type: type.cast()),
      SegwitAddressType.p2wpkh =>
        P2wpkhAddress.fromProgram(program: addressProgram),
      SegwitAddressType.p2wsh =>
        P2wshAddress.fromProgram(program: addressProgram),
      SegwitAddressType.p2tr =>
        P2trAddress.fromProgram(program: addressProgram),
      _ => throw DartBitcoinPluginException("Unsuported bitcoin address type."),
    };
  }
  BitcoinAddressType get type;
  String toAddress(BasedUtxoNetwork network);
  Script toScriptPubKey();
  String pubKeyHash();
  String get addressProgram;
}

class PubKeyAddressType extends BitcoinAddressType {
  const PubKeyAddressType._(super.value) : super._();
  static const PubKeyAddressType p2pk = PubKeyAddressType._('P2PK');
  @override
  bool get isP2sh => false;
  @override
  bool get isSegwit => false;

  @override
  int get hashLength => 20;
  @override
  String toString() {
    return 'PubKeyAddressType.$value';
  }
}

class P2pkhAddressType extends BitcoinAddressType {
  const P2pkhAddressType._(super.value) : super._();
  static const P2pkhAddressType p2pkh = P2pkhAddressType._('P2PKH');
  static const P2pkhAddressType p2pkhwt = P2pkhAddressType._('P2PKHWT');

  @override
  bool get isP2sh => false;
  @override
  bool get isSegwit => false;

  @override
  int get hashLength => 20;
  @override
  String toString() {
    return 'P2pkhAddressType.$value';
  }
}

class P2shAddressType extends BitcoinAddressType {
  const P2shAddressType._(super.value, this.hashLength, this.withToken)
      : super._();
  static const P2shAddressType p2wshInP2sh = P2shAddressType._(
      'P2SH/P2WSH', _BitcoinAddressUtils.hash160DigestLength, false);
  static const P2shAddressType p2wpkhInP2sh = P2shAddressType._(
      'P2SH/P2WPKH', _BitcoinAddressUtils.hash160DigestLength, false);
  static const P2shAddressType p2pkhInP2sh = P2shAddressType._(
      'P2SH/P2PKH', _BitcoinAddressUtils.hash160DigestLength, false);
  static const P2shAddressType p2pkInP2sh = P2shAddressType._(
      'P2SH/P2PK', _BitcoinAddressUtils.hash160DigestLength, false);
  @override
  bool get isP2sh => true;
  @override
  bool get isSegwit => false;

  @override
  final int hashLength;
  final bool withToken;

  /// specify BCH NETWORK for now!
  /// Pay-to-Script-Hash-32
  static const P2shAddressType p2pkhInP2sh32 = P2shAddressType._(
      'P2SH32/P2PKH', _BitcoinAddressUtils.scriptHashLenght, false);
  //// Pay-to-Script-Hash-32
  static const P2shAddressType p2pkInP2sh32 = P2shAddressType._(
      'P2SH32/P2PK', _BitcoinAddressUtils.scriptHashLenght, false);

  /// Pay-to-Script-Hash-32-with-token
  static const P2shAddressType p2pkhInP2sh32wt = P2shAddressType._(
      'P2SH32WT/P2PKH', _BitcoinAddressUtils.scriptHashLenght, true);

  /// Pay-to-Script-Hash-32-with-token
  static const P2shAddressType p2pkInP2sh32wt = P2shAddressType._(
      'P2SH32WT/P2PK', _BitcoinAddressUtils.scriptHashLenght, true);

  /// Pay-to-Script-Hash-with-token
  static const P2shAddressType p2pkhInP2shwt = P2shAddressType._(
      'P2SHWT/P2PKH', _BitcoinAddressUtils.hash160DigestLength, true);

  /// Pay-to-Script-Hash-with-token
  static const P2shAddressType p2pkInP2shwt = P2shAddressType._(
      'P2SHWT/P2PK', _BitcoinAddressUtils.hash160DigestLength, true);

  @override
  String toString() {
    return 'P2shAddressType.$value';
  }
}

class SegwitAddressType extends BitcoinAddressType {
  const SegwitAddressType._(super.value) : super._();
  static const SegwitAddressType p2wpkh = SegwitAddressType._('P2WPKH');
  static const SegwitAddressType p2tr = SegwitAddressType._('P2TR');
  static const SegwitAddressType p2wsh = SegwitAddressType._('P2WSH');
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
        return 20;
      default:
        return 32;
    }
  }

  @override
  String toString() {
    return 'SegwitAddressType.$value';
  }
}
