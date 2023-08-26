enum AddressType {
  p2pkh,
  p2sh,
  p2wpkh,
  p2pk,
  p2tr,
  p2wsh,
  p2wshInP2sh,
  p2wpkhInP2sh
}

abstract class BitcoinAddress {
  AddressType get type;

  List<String> toScriptPubKey();
}
