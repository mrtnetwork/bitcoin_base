import 'package:bitcoin_base/src/bitcoin/address/core.dart';
import 'package:bitcoin_base/src/bitcoin/address/validate.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/bip/ecc/keys/secp256k1_keys_ecdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

abstract class LegacyAddress implements BitcoinAddress {
  /// Represents a Bitcoin address
  ///
  /// [hash160] the hash160 string representation of the address; hash160 represents
  /// two consequtive hashes of the public key or the redeam script, first
  /// a SHA-256 and then an RIPEMD-160
  LegacyAddress(
      {String? address,
      String? hash160,
      Script? script,
      BitcoinNetwork? network}) {
    if (hash160 != null) {
      if (!isValidHash160(hash160)) {
        throw ArgumentError("Invalid value for parameter hash160.");
      }
      _h160 = hash160;
    } else if (address != null) {
      if (!isValidAddress(address, type, network: network)) {
        throw ArgumentError("Invalid addres");
      }
      _h160 = _addressToHash160(address);
    } else if (script != null) {
      _h160 = _scriptToHash160(script);
    } else {
      if (type == BitcoinAddressType.p2pk) return;
      throw ArgumentError("Invalid parameters");
    }
  }

  late final String _h160;

  /// returns the address's hash160 hex string representation
  String get getH160 {
    if (type == BitcoinAddressType.p2pk) throw UnimplementedError();
    return _h160;
  }

  static String _addressToHash160(String address) {
    final decode = Base58Decoder.checkDecode(address);
    return BytesUtils.toHexString(decode.sublist(1));
  }

  static String _scriptToHash160(Script s) {
    final b = s.toBytes();
    final h160 = QuickCrypto.hash160(b);
    return BytesUtils.toHexString(h160);
  }

  /// returns the address's string encoding
  @override
  String toAddress(BitcoinNetwork network, {List<int>? h160}) {
    List<int> tobytes = h160 ?? BytesUtils.fromHexString(_h160);
    switch (type) {
      case BitcoinAddressType.p2wpkhInP2sh:
      case BitcoinAddressType.p2wshInP2sh:
      case BitcoinAddressType.p2pkhInP2sh:
      case BitcoinAddressType.p2pkInP2sh:
        tobytes = [...network.p2shNetVer, ...tobytes];
        break;
      case const (BitcoinAddressType.p2pkh) || const (BitcoinAddressType.p2pk):
        tobytes = [...network.p2pkhNetVer, ...tobytes];
        break;
      default:
    }
    return Base58Encoder.checkEncode(tobytes);
  }
}

class P2shAddress extends LegacyAddress {
  /// Encapsulates a P2SH address.
  P2shAddress({super.address, super.hash160, super.script, super.network})
      : type = BitcoinAddressType.p2pkInP2sh;
  P2shAddress.fromScript(
      {super.script, this.type = BitcoinAddressType.p2pkInP2sh})
      : assert(type == BitcoinAddressType.p2pkInP2sh ||
            type == BitcoinAddressType.p2pkhInP2sh ||
            type == BitcoinAddressType.p2wpkhInP2sh ||
            type == BitcoinAddressType.p2wshInP2sh);

  @override
  final BitcoinAddressType type;

  /// Returns the scriptPubKey (P2SH) that corresponds to this address
  @override
  Script toScriptPubKey() {
    return Script(script: ['OP_HASH160', _h160, 'OP_EQUAL']);
  }
}

class P2pkhAddress extends LegacyAddress {
  P2pkhAddress({super.address, super.hash160, super.network});

  /// Returns the scriptPubKey (P2SH) that corresponds to this address
  @override
  Script toScriptPubKey() {
    return Script(script: [
      'OP_DUP',
      'OP_HASH160',
      _h160,
      'OP_EQUALVERIFY',
      'OP_CHECKSIG'
    ]);
  }

  @override
  BitcoinAddressType get type => BitcoinAddressType.p2pkh;
}

class P2pkAddress extends LegacyAddress {
  P2pkAddress({required String publicKey}) {
    final toBytes = BytesUtils.fromHexString(publicKey);
    if (!Secp256k1PublicKeyEcdsa.isValidBytes(toBytes)) {
      throw ArgumentError("The public key is wrong");
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
  String toAddress(BitcoinNetwork network, {List<int>? h160}) {
    final bytes = BytesUtils.fromHexString(publicHex);
    List<int> ripemd160Hash = QuickCrypto.hash160(bytes);
    return super.toAddress(network, h160: ripemd160Hash);
  }

  @override
  BitcoinAddressType get type => BitcoinAddressType.p2pk;
}
