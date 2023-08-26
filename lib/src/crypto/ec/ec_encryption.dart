// ignore_for_file: non_constant_identifier_names
import 'dart:typed_data';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';
import 'package:bitcoin_base/src/formating/der.dart' show listBigIntToDER;
import "package:pointycastle/ecc/curves/secp256k1.dart" show ECCurve_secp256k1;
import "package:pointycastle/api.dart"
    show PrivateKeyParameter, PublicKeyParameter;
import 'package:pointycastle/ecc/api.dart'
    show ECPrivateKey, ECPublicKey, ECSignature, ECPoint;
import "package:pointycastle/signers/ecdsa_signer.dart" show ECDSASigner;
import 'package:pointycastle/macs/hmac.dart';
import "package:pointycastle/digests/sha256.dart";
import 'curve.dart' as ec;

final prime = BigInt.parse(
    "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F",
    radix: 16);

final ZERO32 = Uint8List.fromList(List.generate(32, (index) => 0));
final EC_GROUP_ORDER = hexToBytes(
    "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141");
final EC_P = hexToBytes(
    "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f");
final secp256k1 = ECCurve_secp256k1();
final n = secp256k1.n;
final G = secp256k1.G;
BigInt nDiv2 = n >> 1;

bool isPrivate(Uint8List x) {
  if (!isScalar(x)) return false;
  return _compare(x, ZERO32) > 0 && // > 0
      _compare(x, EC_GROUP_ORDER) < 0; // < G
}

Uint8List? generateTweek(Uint8List point, Uint8List tweak) {
  if (!isPrivate(point)) throw ArgumentError("Bad Private");
  if (!isOrderScalar(tweak)) throw ArgumentError("Bad Tweek");
  BigInt dd = decodeBigInt(point);
  BigInt tt = decodeBigInt(tweak);
  Uint8List dt = encodeBigInt((dd + tt) % n);

  if (dt.length < 32) {
    Uint8List padLeadingZero = Uint8List(32 - dt.length);
    dt = Uint8List.fromList(padLeadingZero + dt);
  }

  if (!isPrivate(dt)) return null;
  return dt;
}

bool isPoint(Uint8List p) {
  if (p.length < 33) {
    return false;
  }
  var t = p[0];
  var x = p.sublist(1, 33);

  if (_compare(x, ZERO32) == 0) {
    return false;
  }
  if (_compare(x, EC_P) == 1) {
    return false;
  }
  try {
    _decodeFrom(p);
  } catch (err) {
    return false;
  }
  if ((t == 0x02 || t == 0x03) && p.length == 33) {
    return true;
  }
  var y = p.sublist(33);
  if (_compare(y, ZERO32) == 0) {
    return false;
  }
  if (_compare(y, EC_P) == 1) {
    return false;
  }
  if (t == 0x04 && p.length == 65) {
    return true;
  }
  return false;
}

bool isScalar(Uint8List x) {
  return x.length == 32;
}

bool isOrderScalar(x) {
  if (!isScalar(x)) return false;
  return _compare(x, EC_GROUP_ORDER) < 0; // < G
}

bool isSignature(Uint8List value) {
  Uint8List r = value.sublist(0, 32);
  Uint8List s = value.sublist(32, 64);

  return value.length == 64 &&
      _compare(r, EC_GROUP_ORDER) < 0 &&
      _compare(s, EC_GROUP_ORDER) < 0;
}

bool _isPointCompressed(Uint8List p) {
  return p[0] != 0x04;
}

bool assumeCompression(bool? value, Uint8List? pubkey) {
  if (value == null && pubkey != null) return _isPointCompressed(pubkey);
  if (value == null) return true;
  return value;
}

Uint8List? pointFromScalar(Uint8List d, bool compress) {
  if (!isPrivate(d)) throw ArgumentError("Bad Private");
  BigInt dd = decodeBigInt(d);
  ECPoint pp = (G * dd) as ECPoint;
  if (pp.isInfinity) return null;
  return pp.getEncoded(compress);
}

Uint8List? pointAddScalar(Uint8List p, Uint8List tweak, bool compress) {
  if (!isPoint(p)) throw ArgumentError("Bad Point");
  if (!isOrderScalar(tweak)) throw ArgumentError("Bad Tweek");
  bool compressed = assumeCompression(compress, p);
  ECPoint? pp = _decodeFrom(p);
  if (_compare(tweak, ZERO32) == 0) return pp!.getEncoded(compressed);
  BigInt tt = decodeBigInt(tweak);
  ECPoint qq = (G * tt) as ECPoint;
  ECPoint uu = (pp! + qq) as ECPoint;
  if (uu.isInfinity) return null;
  return uu.getEncoded(compressed);
}

ECSignature deterministicGenerateK(Uint8List hash, Uint8List x) {
  final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
  var pkp = PrivateKeyParameter(ECPrivateKey(decodeBigInt(x), secp256k1));
  signer.init(true, pkp);
  return signer.generateSignature(hash) as ECSignature;
}

Uint8List sign(Uint8List hash, Uint8List x) {
  if (!isScalar(hash)) throw ArgumentError("Bad hash");
  if (!isPrivate(x)) throw ArgumentError("Bad Private");
  ECSignature sig = deterministicGenerateK(hash, x);
  Uint8List buffer = Uint8List(64);
  buffer.setRange(0, 32, encodeBigInt(sig.r));
  BigInt s;
  if (sig.s.compareTo(nDiv2) > 0) {
    s = n - sig.s;
  } else {
    s = sig.s;
  }

  buffer.setRange(32, 64, encodeBigInt(s));
  return buffer;
}

Uint8List signDer(Uint8List hash, Uint8List x, {Uint8List? entery}) {
  if (!isScalar(hash)) throw ArgumentError("Bad Hash");
  if (!isPrivate(x)) throw ArgumentError("Bad private");
  ECSignature sig = _deterministicGenerateK(hash, x, entry: entery);

  return listBigIntToDER([sig.r, sig.s]);
}

bool verify(Uint8List hash, Uint8List q, Uint8List signature) {
  if (!isScalar(hash)) throw ArgumentError("Bad hash");
  if (!isPoint(q)) throw ArgumentError("Bad Point");
  if (!isSignature(signature)) throw ArgumentError("Bad signatur");
  ECPoint? Q = _decodeFrom(q);
  BigInt r = decodeBigInt(signature.sublist(0, 32));
  BigInt s = decodeBigInt(signature.sublist(32, 64));
  final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
  signer.init(false, PublicKeyParameter(ECPublicKey(Q, secp256k1)));
  return signer.verifySignature(hash, ECSignature(r, s));
}

ECPoint? _decodeFrom(Uint8List P) {
  return secp256k1.curve.decodePoint(P);
}

Uint8List reEncodedFromForm(Uint8List p, bool compressed) {
  final decode = _decodeFrom(p);
  if (decode == null) {
    throw ArgumentError("Bad point");
  }
  final encode = decode.getEncoded(compressed);
  if (!_isPointCompressed(encode)) {
    return encode.sublist(1, encode.length);
  }

  return encode;
}

Uint8List tweakTaprootPoint(Uint8List pub, Uint8List tweak) {
  BigInt x = decodeBigInt(pub.sublist(0, 32));
  BigInt y = decodeBigInt(pub.sublist(32, pub.length));
  if (y.isOdd) {
    y = prime - y;
  }
  final tw = decodeBigInt(tweak);

  final c = secp256k1.curve.createPoint(x, y);
  ECPoint qq = (G * tw) as ECPoint;
  ECPoint Q = (c + qq) as ECPoint;

  if (Q.y!.toBigInteger()!.isOdd) {
    y = prime - Q.y!.toBigInteger()!;
    Q = secp256k1.curve.createPoint(Q.x!.toBigInteger()!, y);
  }
  x = Q.x!.toBigInteger()!;
  y = Q.y!.toBigInteger()!;
  final r = padUint8ListTo32(encodeBigInt(x));
  final s = padUint8ListTo32(encodeBigInt(y));
  return Uint8List.fromList([...r, ...s]);
}

ECSignature _deterministicGenerateK(Uint8List hash, Uint8List x,
    {Uint8List? entry}) {
  final signer = ec.CustomECDSASigner(null, HMac(SHA256Digest(), 64), entry);

  final ds = decodeBigInt(x);
  var pkp = PrivateKeyParameter(ECPrivateKey(ds, secp256k1));
  signer.init(true, pkp);
  final sig = signer.generateSignature(hash) as ECSignature;
  return sig;
}

int _compare(Uint8List a, Uint8List b) {
  BigInt aa = decodeBigInt(a);
  BigInt bb = decodeBigInt(b);
  if (aa == bb) return 0;
  if (aa > bb) return 1;
  return -1;
}

Uint8List pubKeyGeneration(Uint8List secret) {
  final d0 = decodeBigInt(secret);
  if (!(BigInt.one <= d0 && d0 <= n - BigInt.one)) {
    throw ArgumentError(
        "The secret key must be an integer in the range 1..n-1.");
  }
  ECPoint qq = (G * d0) as ECPoint;
  Uint8List toBytes = qq.getEncoded(false);
  if (toBytes[0] == 0x04) {
    toBytes = toBytes.sublist(1, toBytes.length);
  }
  return toBytes;
}

BigInt _negatePrivateKey(Uint8List secret) {
  final bytes = pubKeyGeneration(secret);
  final toBigInt = decodeBigInt(bytes.sublist(32));
  BigInt negatedKey = decodeBigInt(secret);
  if (toBigInt.isOdd) {
    final keyExpend = decodeBigInt(secret);
    negatedKey = n - keyExpend;
  }
  return negatedKey;
}

Uint8List tweekTapprotPrivate(Uint8List secret, BigInt tweek) {
  final bytes = pubKeyGeneration(secret);
  final toBigInt = decodeBigInt(bytes.sublist(32));
  BigInt negatedKey = decodeBigInt(secret);
  if (toBigInt.isOdd) {
    negatedKey = _negatePrivateKey(secret);
  }
  final tw = (negatedKey + tweek) % n;
  return encodeBigInt(tw);
}

Uint8List _xorBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    throw ArgumentError("Input lists must have the same length");
  }

  Uint8List result = Uint8List(a.length);

  for (int i = 0; i < a.length; i++) {
    result[i] = a[i] ^ b[i];
  }

  return result;
}

Uint8List schnorrSign(Uint8List msg, Uint8List secret, Uint8List aux) {
  if (msg.length != 32) {
    throw ArgumentError("The message must be a 32-byte array.");
  }
  final d0 = decodeBigInt(secret);
  if (!(BigInt.one <= d0 && d0 <= n - BigInt.one)) {
    throw ArgumentError(
        "The secret key must be an integer in the range 1..n-1.");
  }
  if (aux.length != 32) {
    throw ArgumentError("aux_rand must be 32 bytes instead of ${aux.length}");
  }
  ECPoint P = (G * d0) as ECPoint;
  BigInt d = d0;
  if (P.y!.toBigInteger()!.isOdd) {
    d = n - d;
  }
  final t = _xorBytes(encodeBigInt(d), taggedHash(aux, "BIP0340/aux"));
  final kHash = taggedHash(
      Uint8List.fromList([...t, ...encodeBigInt(P.x!.toBigInteger()!), ...msg]),
      "BIP0340/nonce");
  final k0 = decodeBigInt(kHash) % n;
  if (k0 == BigInt.zero) {
    throw const FormatException(
        'Failure. This happens only with negligible probability.');
  }
  final R = (G * k0) as ECPoint;
  BigInt k = k0;
  if (R.y!.toBigInteger()!.isOdd) {
    k = n - k;
  }
  final eHash = taggedHash(
      Uint8List.fromList([
        ...encodeBigInt(R.x!.toBigInteger()!),
        ...encodeBigInt(P.x!.toBigInteger()!),
        ...msg
      ]),
      "BIP0340/challenge");

  final e = decodeBigInt(eHash) % n;
  final eKey = (k + e * d) % n;
  final sig = Uint8List.fromList(
      [...encodeBigInt(R.x!.toBigInteger()!), ...encodeBigInt(eKey)]);
  final verify = verifySchnorr(msg, encodeBigInt(P.x!.toBigInteger()!), sig);
  if (!verify) {
    throw const FormatException(
        'The created signature does not pass verification.');
  }
  return sig;
}

bool verifySchnorr(Uint8List message, Uint8List publicKey, Uint8List signatur) {
  if (message.length != 32) {
    throw ArgumentError("The message must be a 32-byte array.");
  }
  if (publicKey.length != 32) {
    throw ArgumentError("The public key must be a 32-byte array.");
  }
  if (signatur.length != 64) {
    throw ArgumentError("The signature must be a 64-byte array.");
  }
  final P = _liftX(decodeBigInt(publicKey));
  final r = decodeBigInt(signatur.sublist(0, 32));
  final s = decodeBigInt(signatur.sublist(32, 64));
  if (P == null || r >= prime || s >= n) {
    return false;
  }
  final eHash = taggedHash(
      Uint8List.fromList(
          [...signatur.sublist(0, 32), ...publicKey, ...message]),
      "BIP0340/challenge");
  final e = decodeBigInt(eHash) % n;

  final sp = (G * s) as ECPoint;

  final eP = (P * (n - e)) as ECPoint;

  final R = (sp + eP) as ECPoint;
  if (R.y!.toBigInteger()!.isOdd || R.x!.toBigInteger()! != r) {
    return false;
  }
  return true;
}

ECPoint? _liftX(BigInt x) {
  if (x >= prime) {
    return null;
  }
  final ySq = (_modPow(x, BigInt.from(3), prime) + BigInt.from(7)) % prime;
  final y = _modPow(ySq, (prime + BigInt.one) ~/ BigInt.from(4), prime);
  if (_modPow(y, BigInt.two, prime) != ySq) return null;
  BigInt result = (y & BigInt.one) == BigInt.zero ? y : prime - y;
  return secp256k1.curve.createPoint(x, result);
}

BigInt _modPow(BigInt base, BigInt exponent, BigInt modulus) {
  if (exponent == BigInt.zero) {
    return BigInt.one;
  }

  BigInt result = BigInt.one;
  base %= modulus;

  while (exponent > BigInt.zero) {
    if ((exponent & BigInt.one) == BigInt.one) {
      result = (result * base) % modulus;
    }
    exponent = exponent ~/ BigInt.two;
    base = (base * base) % modulus;
  }

  return result;
}

ECPoint _decompressKey(BigInt xBN, bool yBit) {
  List<int> x9IntegerToBytes(BigInt s, int qLength) {
    //https://github.com/bcgit/bc-java/blob/master/core/src/main/java/org/bouncycastle/asn1/x9/X9IntegerConverter.java#L45
    final bytes = intToBytes(s);

    if (qLength < bytes.length) {
      return bytes.sublist(0, bytes.length - qLength);
    } else if (qLength > bytes.length) {
      final tmp = List<int>.filled(qLength, 0);

      final offset = qLength - bytes.length;
      for (var i = 0; i < bytes.length; i++) {
        tmp[i + offset] = bytes[i];
      }

      return tmp;
    }

    return bytes;
  }

  final compEnc =
      x9IntegerToBytes(xBN, 1 + ((secp256k1.curve.fieldSize + 7) ~/ 8));
  compEnc[0] = yBit ? 0x03 : 0x02;
  return secp256k1.curve.decodePoint(compEnc)!;
}

Uint8List? recoverPublicKeyFromSignature(
  int recId,
  Uint8List sig,
  Uint8List message,
) {
  final r = decodeBigInt(Uint8List.view(sig.buffer, 0, 32));
  final s = decodeBigInt(Uint8List.view(sig.buffer, 32, 32));
  final i = BigInt.from(recId ~/ 2);
  final x = r + (i * n);
  if (x.compareTo(prime) >= 0) return null;
  final R = _decompressKey(x, (recId & 1) == 1);
  final ECPoint? ecPoint = R * n;
  if (ecPoint == null || !ecPoint.isInfinity) return null;
  final e = decodeBigInt(message);
  final eInv = (BigInt.zero - e) % n;
  final rInv = r.modInverse(n);
  final srInv = (rInv * s) % n;
  final eInvrInv = (rInv * eInv) % n;

  final preQ = (G * eInvrInv);
  if (preQ == null) return null;
  final q = preQ + (R * srInv);
  final bytes = q?.getEncoded(false);
  return bytes;
}

// List<int> _convertHex(String input) {
//   const String alphabet = "0123456789abcdef";
//   String str = input.replaceAll(" ", "");
//   str = str.toLowerCase();
//   if (str.length % 2 != 0) {
//     str = "0$str";
//   }
//   Uint8List result = Uint8List(str.length ~/ 2);
//   for (int i = 0; i < result.length; i++) {
//     int firstDigit = alphabet.indexOf(str[i * 2]);
//     int secondDigit = alphabet.indexOf(str[i * 2 + 1]);
//     if (firstDigit == -1 || secondDigit == -1) {
//       throw FormatException("Non-hex character detected in $input");
//     }
//     result[i] = (firstDigit << 4) + secondDigit;
//   }
//   return result;
// }
