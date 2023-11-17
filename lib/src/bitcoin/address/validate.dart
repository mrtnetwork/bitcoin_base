import 'package:bitcoin_base/src/models/network.dart';
import 'package:blockchain_utils/base58/base58_base.dart';
import 'package:blockchain_utils/compare/compare.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

import 'core.dart';

bool isValidAddress(String address, BitcoinAddressType type,
    {BitcoinNetwork? network}) {
  if (address.length < 26 || address.length > 35) {
    return false;
  }
  final decode = List<int>.from(Base58Decoder.decode(address));
  final List<int> networkPrefix = [decode[0]];
  List<int> data = decode.sublist(0, decode.length - 4);
  List<int> checksum = decode.sublist(decode.length - 4);
  List<int> hash = QuickCrypto.sha256DoubleHash(data).sublist(0, 4);
  if (!bytesEqual(checksum, hash)) {
    return false;
  }
  switch (type) {
    case BitcoinAddressType.p2pkh:
      if (network != null) {
        return bytesEqual(networkPrefix, network.p2pkhNetVer);
      }
      return bytesEqual(networkPrefix, BitcoinNetwork.mainnet.p2pkhNetVer) ||
          bytesEqual(networkPrefix, BitcoinNetwork.testnet.p2pkhNetVer);
    case BitcoinAddressType.p2pkhInP2sh:
    case BitcoinAddressType.p2pkInP2sh:
    case BitcoinAddressType.p2wshInP2sh:
    case BitcoinAddressType.p2wpkhInP2sh:
      if (network != null) {
        return bytesEqual(networkPrefix, network.p2shNetVer);
      }
      return bytesEqual(networkPrefix, BitcoinNetwork.mainnet.p2shNetVer) ||
          bytesEqual(networkPrefix, BitcoinNetwork.testnet.p2shNetVer);
    default:
  }
  return true;
}

bool isValidHash160(String hash160) {
  if (hash160.length != 40) {
    return false;
  }
  try {
    BigInt.parse(hash160, radix: 16);
  } catch (e) {
    return false;
  }
  return true;
}
