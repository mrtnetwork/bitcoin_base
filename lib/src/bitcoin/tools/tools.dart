import 'dart:typed_data';

import 'package:bitcoin_base/src/base58/base58.dart' as bs58;
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';
import 'package:convert/convert.dart';

bool isValidAddress(String address) {
  if (address.length < 26 || address.length > 35) {
    return false;
  }
  final decode = bs58.base58.decode(address);
  Uint8List data = decode.sublist(0, decode.length - 4);
  Uint8List checksum = decode.sublist(decode.length - 4);
  Uint8List hash = doubleHash(data).sublist(0, 4);
  if (!isValidCheckSum(checksum, hash)) {
    return false;
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

List<int> opPushData(String hexData) {
  final Uint8List dataBytes = hexToBytes(hexData);
  if (dataBytes.length < 0x4c) {
    return Uint8List.fromList([dataBytes.length]) + dataBytes;
  } else if (dataBytes.length < 0xff) {
    return Uint8List.fromList([0x4c]) +
        Uint8List.fromList([dataBytes.length]) +
        dataBytes;
  } else if (dataBytes.length < 0xffff) {
    var lengthBytes = ByteData(2);
    lengthBytes.setUint16(0, dataBytes.length, Endian.little);
    return Uint8List.fromList([0x4d]) +
        Uint8List.view(lengthBytes.buffer) +
        dataBytes;
  } else if (dataBytes.length < 0xffffffff) {
    var lengthBytes = ByteData(4);
    lengthBytes.setUint32(0, dataBytes.length, Endian.little);
    return Uint8List.fromList([0x4e]) +
        Uint8List.view(lengthBytes.buffer) +
        dataBytes;
  } else {
    throw ArgumentError("Data too large. Cannot push into script");
  }
}

Uint8List pushInteger(int integer) {
  if (integer < 0) {
    throw ArgumentError('Integer is currently required to be positive.');
  }

  // Calculate the number of bytes required to represent the integer
  int numberOfBytes = (integer.bitLength + 7) ~/ 8;

  // Convert to little-endian bytes
  Uint8List integerBytes = Uint8List(numberOfBytes);
  for (int i = 0; i < numberOfBytes; i++) {
    integerBytes[i] = (integer >> (i * 8)) & 0xFF;
  }

  // If the last bit is set, add a sign byte to signify a positive integer
  if ((integer & (1 << (numberOfBytes * 8 - 1))) != 0) {
    integerBytes = Uint8List.fromList([...integerBytes, 0x00]);
  }

  return Uint8List.fromList(opPushData(hex.encode(integerBytes)));
}

Uint8List bytes32FromInt(int x) {
  var result = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    result[32 - i - 1] = (x >> (8 * i)) & 0xFF;
  }
  return result;
}

bool isValidCheckSum(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
