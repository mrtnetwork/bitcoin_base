import 'package:bitcoin_base/bitcoin_base.dart';

enum BitcoinAddressType {
  p2pkh("P2PKH"),
  p2wpkh("P2WPKH"),
  p2pk("P2PK"),
  p2tr("P2TR"),
  p2wsh("P2WSH"),
  p2wshInP2sh("P2SH/P2WSH"),
  p2wpkhInP2sh("P2SH/P2WPKh"),
  p2pkhInP2sh("P2SH/P2PKH"),
  p2pkInP2sh("P2SH/P2PK");

  static BitcoinAddressType fromNameOrValue(String value) {
    return values.firstWhere(
        (element) => element.name == value || element.value == value);
  }

  final String value;
  const BitcoinAddressType(this.value);

  bool get isP2sh {
    switch (this) {
      case p2wshInP2sh:
      case p2wpkhInP2sh:
      case p2pkhInP2sh:
      case p2pkInP2sh:
        return true;
      default:
        return false;
    }
  }
}

abstract class BitcoinAddress {
  BitcoinAddressType get type;
  Script toScriptPubKey();
  String toAddress(BasedUtxoNetwork network);
}
