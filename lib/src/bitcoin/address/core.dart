import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

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
}

abstract class BitcoinAddress {
  BitcoinAddressType get type;
  Script toScriptPubKey();
  String toAddress(BitcoinNetwork networkType);

  static BitcoinAddress fromAddress(String address, BitcoinNetwork network) {
    final length = address.length;
    try {
      switch (length) {
        case 34:
          try {
            return P2pkhAddress.fromAddress(address: address, network: network);
          } catch (e) {
            return P2shAddress.fromAddress(address: address, network: network);
          }
        case 35:
          return P2shAddress.fromAddress(address: address, network: network);
        case 42:
          P2WPKHAddrDecoder().decodeAddr(address, {"hrp": network.p2wpkhHrp});
          return P2wpkhAddress.fromAddress(address: address, network: network);
        case 64:
        case 62:
          try {
            return P2wshAddress.fromAddress(address: address, network: network);
          } catch (e) {
            return P2trAddress.fromAddress(address: address, network: network);
          }

        default:
          throw ArgumentError("invalid bitcoin address length");
      }
    } on ArgumentError {
      rethrow;
    } catch (e) {
      throw ArgumentError("invalid bitcoin address");
    }
  }
}
