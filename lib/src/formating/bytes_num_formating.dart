import 'dart:core';
import 'dart:typed_data';
import 'package:convert/convert.dart';

/// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart' as p_utils;

String bytesToHex(
  List<int> bytes,
) =>
    hex.encode(bytes);

BigInt bytesToInt(List<int> bytes) => p_utils.decodeBigInt(bytes);

Uint8List intToBytes(BigInt number) => p_utils.encodeBigInt(number);

Uint8List padUint8ListTo32(Uint8List data) {
  assert(data.length <= 32);
  if (data.length == 32) return data;

  /// todo there must be a faster way to do this?
  return Uint8List(32)..setRange(32 - data.length, 32, data);
}

bool isLessThanBytes(List<int> thashedA, List<int> thashedB) {
  for (int i = 0; i < thashedA.length && i < thashedB.length; i++) {
    if (thashedA[i] < thashedB[i]) {
      return true;
    } else if (thashedA[i] > thashedB[i]) {
      return false;
    }
  }
  return thashedA.length < thashedB.length;
}

BigInt decodeBigInt(List<int> bytes) {
  BigInt result = BigInt.from(0);
  for (int i = 0; i < bytes.length; i++) {
    result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
  }
  return result;
}

/// Encode a BigInt into bytes using big-endian encoding.
Uint8List encodeBigInt(BigInt number) {
  int needsPaddingByte;
  int rawSize;

  if (number > BigInt.zero) {
    rawSize = (number.bitLength + 7) >> 3;
    needsPaddingByte =
        ((number >> (rawSize - 1) * 8) & BigInt.from(0x80)) == BigInt.from(0x80)
            ? 1
            : 0;

    if (rawSize < 32) {
      needsPaddingByte = 1;
    }
  } else {
    needsPaddingByte = 0;
    rawSize = (number.bitLength + 8) >> 3;
  }

  final size = rawSize < 32 ? rawSize + needsPaddingByte : rawSize;
  var result = Uint8List(size);
  for (int i = 0; i < size; i++) {
    result[size - i - 1] = (number & BigInt.from(0xff)).toInt();
    number = number >> 8;
  }
  return result;
}

List<int>? convertBits(List<int> data, int fromBits, int toBits,
    {bool pad = true}) {
  int acc = 0;
  int bits = 0;
  List<int> ret = [];
  int maxv = (1 << toBits) - 1;
  int maxAcc = (1 << (fromBits + toBits - 1)) - 1;

  for (int value in data) {
    if (value < 0 || (value >> fromBits) > 0) {
      return null;
    }
    acc = ((acc << fromBits) | value) & maxAcc;
    bits += fromBits;
    while (bits >= toBits) {
      bits -= toBits;
      ret.add((acc >> bits) & maxv);
    }
  }

  if (pad) {
    if (bits > 0) {
      ret.add((acc << (toBits - bits)) & maxv);
    }
  } else if (bits >= fromBits || ((acc << (toBits - bits)) & maxv) > 0) {
    return null;
  }

  return ret;
}

Uint8List encodeVarint(int i) {
  if (i < 253) {
    return Uint8List.fromList([i]);
  } else if (i < 0x10000) {
    final bytes = Uint8List(3);
    bytes[0] = 0xfd;
    ByteData.view(bytes.buffer).setUint16(1, i, Endian.little);
    return bytes;
  } else if (i < 0x100000000) {
    final bytes = Uint8List(5);
    bytes[0] = 0xfe;
    ByteData.view(bytes.buffer).setUint32(1, i, Endian.little);
    return bytes;
  } else if (BigInt.from(i) < BigInt.parse("0x10000000000000000", radix: 16)) {
    final bytes = Uint8List(9);
    bytes[0] = 0xff;
    ByteData.view(bytes.buffer).setUint64(1, i, Endian.little);
    return bytes;
  } else {
    throw ArgumentError("Integer is too large: $i");
  }
}

Uint8List prependVarint(Uint8List data) {
  final varintBytes = encodeVarint(data.length);
  return Uint8List.fromList([...varintBytes, ...data]);
}

(int, int) viToInt(Uint8List byteint) {
  int ni = byteint[0];
  int size = 0;

  if (ni < 253) {
    return (ni, 1);
  }

  if (ni == 253) {
    size = 2;
  } else if (ni == 254) {
    size = 4;
  } else {
    size = 8;
  }

  int value =
      ByteData.sublistView(byteint, 1, 1 + size).getInt64(0, Endian.little);
  return (value, size + 1);
}

Uint8List packUint32LE(int value) {
  final byteData = ByteData(4);
  byteData.setUint32(0, value, Endian.little);
  return byteData.buffer.asUint8List();
}

Uint8List packBigIntToLittleEndian(BigInt value) {
  final buffer = Uint8List(8);

  for (var i = 0; i < 8; i++) {
    buffer[i] = (value & BigInt.from(0xff)).toInt();
    value >>= 8;
  }

  return buffer;
}

Uint8List packInt32LE(int value) {
  final byteData = ByteData(4);
  byteData.setInt32(0, value, Endian.little);
  return byteData.buffer.asUint8List();
}

String strip0x(String hex) {
  if (hex.startsWith('0x')) return hex.substring(2);
  return hex;
}

Uint8List hexToBytes(String hexStr) {
  final bytes = hex.decode(strip0x(hexStr));
  if (bytes is Uint8List) return bytes;

  return Uint8List.fromList(bytes);
}

int intFromBytes(List<int> bytes, Endian endian) {
  if (bytes.isEmpty) {
    throw ArgumentError("Input bytes should not be empty");
  }

  final buffer = Uint8List.fromList(bytes);
  final byteData = ByteData.sublistView(buffer);

  switch (bytes.length) {
    case 1:
      return byteData.getInt8(0);
    case 2:
      return byteData.getInt16(0, endian);
    case 4:
      return byteData.getInt32(0, endian);
    default:
      throw ArgumentError("Unsupported byte length: ${bytes.length}");
  }
}

bool bytesListEqual(List<int>? a, List<int>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  if (identical(a, b)) {
    return true;
  }
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

Uint8List packUint32BE(int value) {
  var bytes = Uint8List(4);
  bytes[0] = (value >> 24) & 0xFF;
  bytes[1] = (value >> 16) & 0xFF;
  bytes[2] = (value >> 8) & 0xFF;
  bytes[3] = value & 0xFF;
  return bytes;
}

int binaryToByte(String binary) {
  return int.parse(binary, radix: 2);
}

String bytesToBinary(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(2).padLeft(8, '0')).join('');
}
