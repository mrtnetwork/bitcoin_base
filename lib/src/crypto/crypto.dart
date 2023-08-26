library bitcoin_crypto;

import 'dart:convert';
import 'package:pointycastle/export.dart';
import "dart:typed_data";
export 'ec/ec_private.dart';
export 'ec/ec_public.dart';
// ignore: implementation_imports
import 'package:pointycastle/src/platform_check/platform_check.dart'
    as platform;

Uint8List doubleSh256(Uint8List value) {
  Digest digest = SHA256Digest();
  return digest.process(digest.process(value));
}

Uint8List hash160(Uint8List buffer) {
  Uint8List tmp = SHA256Digest().process(buffer);
  return RIPEMD160Digest().process(tmp);
}

Uint8List hmacSHA512(Uint8List key, Uint8List data) {
  final tmp = HMac(SHA512Digest(), 128)..init(KeyParameter(key));
  return tmp.process(data);
}

Uint8List doubleHash(Uint8List buffer) {
  Uint8List tmp = SHA256Digest().process(buffer);
  return SHA256Digest().process(tmp);
}

Uint8List singleHash(Uint8List buffer) {
  Uint8List tmp = SHA256Digest().process(buffer);
  return tmp;
}

Uint8List taggedHash(Uint8List data, String tag) {
  final tagDIgits = singleHash(Uint8List.fromList(tag.codeUnits));
  final concat = Uint8List.fromList([...tagDIgits, ...tagDIgits, ...data]);
  return singleHash(concat);
}

FortunaRandom? _randomGenerator;
Uint8List generateRandom({int size = 32}) {
  if (_randomGenerator == null) {
    _randomGenerator = FortunaRandom();
    _randomGenerator!.seed(KeyParameter(
        platform.Platform.instance.platformEntropySource().getBytes(32)));
  }

  final r = _randomGenerator!.nextBytes(size);

  return r;
}

Uint8List pbkdfDeriveDigest(String mnemonic, String salt) {
  final toBytesSalt = Uint8List.fromList(utf8.encode(salt));
  final derive = PBKDF2KeyDerivator(HMac(SHA512Digest(), 128));
  derive.reset();
  derive.init(Pbkdf2Parameters(toBytesSalt, 2048, 64));
  return derive.process(Uint8List.fromList(mnemonic.codeUnits));
}
