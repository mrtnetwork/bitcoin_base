import 'dart:convert';
import 'package:bitcoin_base/src/base58/base58.dart' as bs58;
import 'package:bitcoin_base/src/bitcoin/tools/tools.dart';
import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';
import 'package:bitcoin_base/src/formating/magic_prefix.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/bitcoin/constant/constant.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'ec_encryption.dart' as ec;

/// Represents an ECDSA private key.
class ECPrivate {
  ECPrivate._({
    required String priveHex,
    required String publicHex,
  })  : _publicHex = publicHex,
        _priveHex = priveHex;

  /// creates an object from raw 32 bytes
  factory ECPrivate.fromBytes(Uint8List prive) {
    if (!ec.isPrivate(prive)) {
      throw Exception("wrong ec private");
    }
    final priveHex = bytesToHex(prive);
    final public = ec.pointFromScalar(prive, false);
    final publicHex = bytesToHex(public!);
    return ECPrivate._(
      priveHex: priveHex,
      publicHex: publicHex,
    );
  }

  /// returns the corresponding ECPublic object
  ECPublic getPublic() => ECPublic.fromHex(_publicHex);

  /// creates an object from a WIF of WIFC format (string)
  factory ECPrivate.fromWif(String wif) {
    final b64 = Uint8List.fromList(bs58.base58.decode(wif));
    Uint8List keyBytes = b64.sublist(0, b64.length - 4);
    final checksum = b64.sublist(b64.length - 4);
    final h = doubleHash(keyBytes);
    final isValid = listEquals(h.sublist(0, 4), checksum);
    if (!isValid) {
      throw Exception('Checksum is wrong. Possible mistype?'); // listtEqual
    }
    keyBytes = keyBytes.sublist(1);
    if (keyBytes.length > 32) {
      keyBytes = keyBytes.sublist(0, keyBytes.length - 1);
    }
    return ECPrivate.fromBytes(keyBytes);
  }
  final String _priveHex;
  final String _publicHex;

  /// returns as WIFC (compressed) or WIF format (string)
  String toWif({bool compressed = true, NetworkInfo? networkType}) {
    final network = networkType ?? NetworkInfo.BITCOIN;
    Uint8List bytes = Uint8List.fromList([network.wif, ...toBytes()]);
    if (compressed) {
      bytes = Uint8List.fromList([...bytes, 0x01]);
    }
    Uint8List hash = doubleHash(bytes);
    hash = Uint8List.fromList(
        [bytes, hash.sublist(0, 4)].expand((i) => i).toList(growable: false));
    return bs58.base58.encode(hash);
  }

  /// returns the key's raw bytes
  Uint8List toBytes() {
    return hexToBytes(_priveHex);
  }

  String toHex() {
    return _priveHex;
  }

  /// Returns a Bitcoin compact signature in hex
  String signMessage(String message, {bool compressed = true}) {
    final m = singleHash(magicMessage(message));
    final sign = ec.sign(m, toBytes());
    int prefix = 27;
    if (compressed) {
      prefix += 4;
    }
    final address = getPublic().toAddress(copressed: compressed);
    for (int i = prefix; i < prefix + 4; i++) {
      try {
        final sig = Uint8List.fromList(
            [...utf8.encode(String.fromCharCode(i)), ...sign]);
        final pub = ECPublic.getSignaturPublic(message, sig);
        if (pub?.toAddress(copressed: compressed).getH160 == address.getH160) {
          return bytesToHex(sig);
        }
      } catch (e) {
        continue;
      }
    }
    throw Exception("cannot validate message");
  }

  /// sign transaction digest  and returns the signature.
  String signInput(Uint8List txDigest, {int sigHash = SIGHASH_ALL}) {
    final priveBytes = toBytes();
    Uint8List signature = ec.signDer(txDigest, priveBytes);

    int attempt = 1;
    int lengthR = signature[3];

    while (lengthR == 33) {
      final attemptBytes = bytes32FromInt(attempt);
      signature = ec.signDer(txDigest, priveBytes, entery: attemptBytes);
      attempt += 1;
      lengthR = signature[3];

      if (attempt > 20) {
        throw Exception("wrong !!!!! sign must implanet");
      }
    }
    int derPrefix = signature[0];
    int lengthTotal = signature[1];
    int derTypeInt = signature[2];
    lengthR = signature[3];
    Uint8List R = Uint8List.sublistView(signature, 4, 4 + lengthR);
    int lengthS = signature[5 + lengthR];
    Uint8List S = Uint8List.sublistView(signature, 5 + lengthR + 1);
    BigInt sAsBigint = bytesToInt(S);
    Uint8List newS;
    if (lengthS == 33) {
      final BigInt prime = BigInt.parse(
          'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
          radix: 16);
      final newSAsBigint = prime - sAsBigint;
      newS = hexToBytes(newSAsBigint.toRadixString(16).padLeft(64, '0'));
      lengthS -= 1;
      lengthTotal -= 1;
    } else {
      newS = S;
    }

    signature = Uint8List.fromList([
      derPrefix,
      lengthTotal,
      derTypeInt,
      lengthR,
      ...R,
      derTypeInt,
      lengthS,
      ...newS,
    ]);
    signature = Uint8List.fromList([...signature, sigHash]);
    return bytesToHex(signature);
  }

  /// sign taproot transaction digest and returns the signature.
  String signTapRoot(Uint8List txDigest,
      {sighash = TAPROOT_SIGHASH_ALL,
      List<dynamic> scripts = const [],
      bool tweak = true}) {
    Uint8List byteKey = Uint8List(0);
    if (tweak) {
      final ECPublic publicKey = ECPublic.fromHex(_publicHex);
      final t = publicKey.calculateTweek(script: scripts);
      byteKey = ec.tweekTapprotPrivate(hexToBytes(_priveHex), t);
    } else {
      byteKey = hexToBytes(_priveHex);
    }
    final randAux = singleHash(Uint8List.fromList([...txDigest, ...byteKey]));
    Uint8List signatur = ec.schnorrSign(txDigest, byteKey, randAux);
    if (sighash != TAPROOT_SIGHASH_ALL) {
      signatur = Uint8List.fromList([...signatur, sighash]);
    }
    return bytesToHex(signatur);
  }

  static ECPrivate random() {
    final secret = generateRandom();
    return ECPrivate.fromBytes(secret);
  }
}
