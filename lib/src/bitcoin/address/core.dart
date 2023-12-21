import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/utils/enumerate.dart';

class BitcoinAddressType implements Enumerate {
  static const BitcoinAddressType p2pkh = BitcoinAddressType._("P2PKH");
  static const BitcoinAddressType p2wpkh = BitcoinAddressType._("P2WPKH");
  static const BitcoinAddressType p2pk = BitcoinAddressType._("P2PK");
  static const BitcoinAddressType p2tr = BitcoinAddressType._("P2TR");
  static const BitcoinAddressType p2wsh = BitcoinAddressType._("P2WSH");
  static const BitcoinAddressType p2wshInP2sh =
      BitcoinAddressType._("P2SH/P2WSH");
  static const BitcoinAddressType p2wpkhInP2sh =
      BitcoinAddressType._("P2SH/P2WPKH");
  static const BitcoinAddressType p2pkhInP2sh =
      BitcoinAddressType._("P2SH/P2PKH");
  static const BitcoinAddressType p2pkInP2sh =
      BitcoinAddressType._("P2SH/P2PK");

  @override
  final String value;

  const BitcoinAddressType._(this.value);

  /// Factory method to create a BitcoinAddressType enum value from a name or value.
  static BitcoinAddressType fromValue(String value) {
    return values.firstWhere((element) => element.value == value,
        orElse: () =>
            throw ArgumentError('Invalid BitcoinAddressType: $value'));
  }

  /// Check if the address type is Pay-to-Script-Hash (P2SH).
  bool get isP2sh {
    if (value.startsWith("P2SH")) return true;
    return false;
  }

  // Enum values as a list for iteration
  static const List<BitcoinAddressType> values = [
    p2pkh,
    p2wpkh,
    p2pk,
    p2tr,
    p2wsh,
    p2wshInP2sh,
    p2wpkhInP2sh,
    p2pkhInP2sh,
    p2pkInP2sh,
  ];
}

abstract class BitcoinAddress {
  BitcoinAddressType get type;
  Script toScriptPubKey();
  String toAddress(BasedUtxoNetwork network);
}
