enum AddressType { p2pkh, p2sh, p2wpkh, p2pk, p2tr, p2wsh }

abstract class BitcoinAddress {
  AddressType get type;

  List<String> toScriptPubKey();
}
