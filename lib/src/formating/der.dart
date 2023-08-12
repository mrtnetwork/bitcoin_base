import 'dart:typed_data';

import 'bytes_num_formating.dart' show hexToBytes;

Uint8List listBigIntToDER(List<BigInt> bigIntList) {
  List<Uint8List> encodedIntegers = bigIntList.map((bi) {
    var bytes = _encodeInteger(bi);
    return Uint8List.fromList(bytes);
  }).toList();

  var lengthBytes =
      _encodeLength(encodedIntegers.fold<int>(0, (sum, e) => sum + e.length));
  var contentBytes = encodedIntegers.fold<Uint8List>(
      Uint8List(0), (prev, e) => Uint8List.fromList([...prev, ...e]));

  var derBytes = Uint8List.fromList([
    0x30, ...lengthBytes, // DER SEQUENCE tag and length
    ...contentBytes,
  ]);

  return derBytes;
}

Uint8List _encodeLength(int length) {
  if (length < 128) {
    return Uint8List.fromList([length]);
  } else {
    var lengthBytes =
        length.toRadixString(16).padLeft((length.bitLength + 7) ~/ 8, '0');
    if (lengthBytes.length % 2 != 0) {
      lengthBytes = '0$lengthBytes';
    }
    return Uint8List.fromList(
        [0x80 | (lengthBytes.length ~/ 2), ...hexToBytes(lengthBytes)]);
  }
}

Uint8List _encodeInteger(BigInt r) {
  assert(r >= BigInt.zero); // can't support negative numbers yet

  String h = r.toRadixString(16);
  if (h.length % 2 != 0) {
    h = '0$h';
  }
  Uint8List s = hexToBytes(h);

  int num = s[0];
  if (num <= 0x7F) {
    return Uint8List.fromList([0x02, ..._length(s.length), ...s]);
  } else {
    // DER integers are two's complement, so if the first byte is
    // 0x80-0xff then we need an extra 0x00 byte to prevent it from
    // looking negative.
    return Uint8List.fromList([0x02, ..._length(s.length + 1), 0x00, ...s]);
  }
}

Uint8List _length(int length) {
  if (length < 128) {
    return Uint8List.fromList([length]);
  } else {
    var lengthBytes = hexToBytes(
        length.toRadixString(16).padLeft((length.bitLength + 7) ~/ 8, '0'));
    return Uint8List.fromList([0x80 | (lengthBytes.length), ...lengthBytes]);
  }
}
