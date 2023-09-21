import 'dart:typed_data';

import 'package:bitcoin_base/src/base58/base58.dart' as bs58;
import 'package:bitcoin_base/src/bitcoin/address/core.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/bitcoin/tools/tools.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/crypto/ec/ec_encryption.dart' as ecc;

abstract class BipAddress implements BitcoinAddress {
  /// Represents a Bitcoin address
  ///
  /// [hash160] the hash160 string representation of the address; hash160 represents
  /// two consequtive hashes of the public key or the redeam script, first
  /// a SHA-256 and then an RIPEMD-160
  BipAddress({String? address, String? hash160, Script? script}) {
    if (hash160 != null) {
      if (!isValidHash160(hash160)) {
        throw Exception("Invalid value for parameter hash160.");
      }
      _h160 = hash160;
    } else if (address != null) {
      if (!isValidAddress(address)) {
        throw ArgumentError("Invalid addres");
      }
      _h160 = _addressToHash160(address);
    } else if (script != null) {
      _h160 = _scriptToHash160(script);
    } else {
      if (type == AddressType.p2pk) return;
      throw ArgumentError("Invalid parameters");
    }
  }

  late final String _h160;

  /// returns the address's hash160 hex string representation
  String get getH160 {
    if (type == AddressType.p2pk) throw UnimplementedError();
    return _h160;
  }

  static String _addressToHash160(String address) {
    final dec = bs58.base58.decode(address);
    return bytesToHex(dec.sublist(1, dec.length - 4));
  }

  static String _scriptToHash160(Script s) {
    final b = s.toBytes();
    final h160 = hash160(b);
    return bytesToHex(h160);
  }

  /// returns the address's string encoding
  String toAddress(NetworkInfo networkType, {Uint8List? h160}) {
    Uint8List tobytes = h160 ?? hexToBytes(_h160);
    switch (type) {
      case AddressType.p2wpkhInP2sh:
      case AddressType.p2wshInP2sh:
      case AddressType.p2sh:
        tobytes = Uint8List.fromList([networkType.p2shPrefix, ...tobytes]);
        break;
      case const (AddressType.p2pkh) || const (AddressType.p2pk):
        tobytes = Uint8List.fromList([networkType.p2pkhPrefix, ...tobytes]);
        break;
      default:
    }
    Uint8List hash = doubleHash(tobytes);
    hash = Uint8List.fromList(
        [tobytes, hash.sublist(0, 4)].expand((i) => i).toList(growable: false));
    return bs58.base58.encode(hash);
  }
}

class P2shAddress extends BipAddress {
  /// Encapsulates a P2SH address.
  P2shAddress({super.address, super.hash160, super.script})
      : type = AddressType.p2sh;
  P2shAddress.fromSegwitScript({super.script, this.type = AddressType.p2sh})
      : assert(type == AddressType.p2sh ||
            type == AddressType.p2wpkhInP2sh ||
            type == AddressType.p2wshInP2sh);

  @override
  final AddressType type;

  /// Returns the scriptPubKey (P2SH) that corresponds to this address
  @override
  List<String> toScriptPubKey() {
    return ['OP_HASH160', _h160, 'OP_EQUAL'];
  }
}

class P2pkhAddress extends BipAddress {
  P2pkhAddress({super.address, super.hash160});

  /// Returns the scriptPubKey (P2SH) that corresponds to this address
  @override
  List<String> toScriptPubKey() {
    return ['OP_DUP', 'OP_HASH160', _h160, 'OP_EQUALVERIFY', 'OP_CHECKSIG'];
  }

  @override
  AddressType get type => AddressType.p2pkh;
}

class P2pkAddress extends BipAddress {
  P2pkAddress({required String publicKey}) {
    final toBytes = hexToBytes(publicKey);
    if (!ecc.isPoint(toBytes)) {
      throw ArgumentError("The public key is wrong");
    }
    publicHex = publicKey;
  }
  late final String publicHex;

  /// Returns the scriptPubKey (P2SH) that corresponds to this address
  @override
  List<String> toScriptPubKey() {
    return [publicHex, 'OP_CHECKSIG'];
  }

  @override
  String toAddress(NetworkInfo networkType, {Uint8List? h160}) {
    final bytes = hexToBytes(publicHex);
    Uint8List ripemd160Hash = hash160(bytes);
    return super.toAddress(networkType, h160: ripemd160Hash);
  }

  @override
  AddressType get type => AddressType.p2pk;
}
