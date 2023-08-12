import 'dart:typed_data';

import 'package:bitcoin/src/base58/base58.dart' as bs58;
import 'package:bitcoin/src/bitcoin/address/core.dart';
import 'package:bitcoin/src/bitcoin/script/script.dart';
import 'package:bitcoin/src/bitcoin/tools/tools.dart';
import 'package:bitcoin/src/crypto/crypto.dart';
import 'package:bitcoin/src/formating/bytes_num_formating.dart';
import 'package:bitcoin/src/models/network.dart';
import 'package:bitcoin/src/crypto/ec/ec_encryption.dart' as ecc;

abstract class BipAddress implements BitcoinAddress {
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
      _h160 = addressToHash160(address);
    } else if (script != null) {
      _h160 = scriptToHash160(script);
    } else {
      if (type == AddressType.p2pk) return;
      throw ArgumentError("Invalid parameters");
    }
  }

  // late final String? address;
  late final String _h160;
  String get getH160 {
    if (type == AddressType.p2pk) throw UnimplementedError();
    return _h160;
  }

  // BTCAddressTypes get type;
  static String addressToHash160(String address) {
    final dec = bs58.base58.decode(address);
    return bytesToHex(dec.sublist(1, dec.length - 4));
  }

  static String scriptToHash160(Script s) {
    final b = s.toBytes();
    final h160 = hash160(b);
    return bytesToHex(h160);
  }

  String toAddress(NetworkInfo networkType, {Uint8List? h160}) {
    Uint8List tobytes = h160 ?? hexToBytes(_h160);
    switch (type) {
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
  P2shAddress({super.address, super.hash160, super.script});

  @override
  AddressType get type => AddressType.p2sh;

  @override
  List<String> toScriptPubKey() {
    return ['OP_HASH160', _h160, 'OP_EQUAL'];
  }
}

class P2pkhAddress extends BipAddress {
  P2pkhAddress({super.address, super.hash160});
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
  @override
  List<String> toScriptPubKey() {
    return [publicHex, 'OP_CHECKSIG'];
  }

  /// return p2pkh address of public key.
  @override
  String toAddress(NetworkInfo networkType, {Uint8List? h160}) {
    final bytes = hexToBytes(publicHex);
    Uint8List ripemd160Hash = hash160(bytes);
    return super.toAddress(networkType, h160: ripemd160Hash);
  }

  @override
  AddressType get type => AddressType.p2pk;
}
