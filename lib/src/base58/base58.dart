// import 'package:bitcoin/src/crypto/crypto.dart';
import 'dart:typed_data';

import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';
// import 'package:flutter/foundation.dart';

const String _btc =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
final base58 = Base(_btc);

class Base {
  final String alphabet;
  // ignore: non_constant_identifier_names
  Map<String, int> ALPHABET_MAP = <String, int>{};
  late final int _base;

  late final String _leader;

  Base(this.alphabet) {
    _base = alphabet.length;
    _leader = (alphabet)[0];
    for (var i = 0; i < (alphabet).length; i++) {
      ALPHABET_MAP[(alphabet)[i]] = i;
    }
  }
  String encodeCheck(Uint8List bytes) {
    Uint8List hash = doubleHash(bytes);
    Uint8List combine = Uint8List.fromList(
        [bytes, hash.sublist(0, 4)].expand((i) => i).toList(growable: false));
    return encode(combine);
  }

  String encode(Uint8List source) {
    if (source.isEmpty) {
      return "";
    }
    List<int> digits = [0];

    for (var i = 0; i < source.length; ++i) {
      var carry = source[i];
      for (var j = 0; j < digits.length; ++j) {
        carry += digits[j] << 8;
        digits[j] = carry % _base;
        carry = carry ~/ _base;
      }
      while (carry > 0) {
        digits.add(carry % _base);
        carry = carry ~/ _base;
      }
    }
    var string = "";

    // deal with leading zeros
    for (var k = 0; source[k] == 0 && k < source.length - 1; ++k) {
      string += _leader;
    }
    // convert digits to a string
    for (var q = digits.length - 1; q >= 0; --q) {
      string += alphabet[digits[q]];
    }
    return string;
  }

  Uint8List decode(String string) {
    if (string.isEmpty) {
      throw ArgumentError('Non-base$_base character');
    }
    List<int> bytes = [0];
    for (var i = 0; i < string.length; i++) {
      var value = ALPHABET_MAP[string[i]];
      if (value == null) {
        throw ArgumentError('Non-base$_base character');
      }
      var carry = value;
      for (var j = 0; j < bytes.length; ++j) {
        carry += bytes[j] * _base;
        bytes[j] = carry & 0xff;
        carry >>= 8;
      }
      while (carry > 0) {
        bytes.add(carry & 0xff);
        carry >>= 8;
      }
    }
    // deal with leading zeros
    for (var k = 0; string[k] == _leader && k < string.length - 1; ++k) {
      bytes.add(0);
    }
    return Uint8List.fromList(bytes.reversed.toList());
  }

  Uint8List decodeCheck(String string) {
    final bytes = decode(string);
    if (bytes.length < 5) {
      throw const FormatException("invalid base58check");
    }
    Uint8List payload = bytes.sublist(0, bytes.length - 4);
    Uint8List checksum = bytes.sublist(bytes.length - 4);
    Uint8List newChecksum = doubleHash(payload).sublist(0, 4);
    if (!bytesListEqual(checksum, newChecksum)) {
      throw ArgumentError("Invalid checksum");
    }
    return payload;
  }
}
