import 'dart:typed_data';

import 'package:bitcoin/src/formating/bytes_num_formating.dart';

enum Bech32Type {
  bech32(1),
  bech32M(0x2bc830a3);

  final int value;
  const Bech32Type(this.value);
}

int _bech32Polymod(List<int> values) {
  List<int> generator = [
    0x3b6a57b2,
    0x26508e6d,
    0x1ea119fa,
    0x3d4233dd,
    0x2a1462b3
  ];
  int chk = 1;
  for (int value in values) {
    int top = chk >> 25;
    chk = (chk & 0x1ffffff) << 5 ^ value;
    for (int i = 0; i < 5; i++) {
      chk ^= ((top >> i) & 1) != 0 ? generator[i] : 0;
    }
  }
  return chk;
}

List<int> _bech32HrpExpand(String hrp) {
  List<int> values = [];
  for (int i = 0; i < hrp.length; i++) {
    values.add(hrp.codeUnitAt(i) >> 5);
  }
  values.add(0);
  for (int i = 0; i < hrp.length; i++) {
    values.add(hrp.codeUnitAt(i) & 31);
  }
  return values;
}

Bech32Type? _bech32VerifyChecksum(String hrp, List<int> data) {
  List<int> combined = _bech32HrpExpand(hrp) + data;
  int c = _bech32Polymod(combined);

  if (c == Bech32Type.bech32.value) {
    return Bech32Type.bech32;
  }
  if (c == Bech32Type.bech32M.value) {
    return Bech32Type.bech32M;
  }
  return null;
}

List<int> _bech32CreateChecksum(String hrp, List<int> data, Bech32Type spec) {
  List<int> values = _bech32HrpExpand(hrp) + data;

  int polymod = _bech32Polymod(values + [0, 0, 0, 0, 0, 0]) ^ spec.value;
  List<int> checksum = [];
  for (int i = 0; i < 6; i++) {
    checksum.add((polymod >> 5 * (5 - i)) & 31);
  }
  return checksum;
}

const _charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";
String _bech32Encode(String hrp, List<int> data, Bech32Type spec) {
  List<int> combined = data + _bech32CreateChecksum(hrp, data, spec);
  String encoded = '${hrp}1${combined.map((d) => _charset[d]).join('')}';
  return encoded;
}

(String, List<int>, Bech32Type)? _bech32Decode(String bech) {
  if (bech.runes.any((x) => x < 33 || x > 126) ||
      (bech.toLowerCase() != bech && bech.toUpperCase() != bech)) {
    return null;
  }
  bech = bech.toLowerCase();
  int pos = bech.lastIndexOf('1');
  if (pos < 1 || pos + 7 > bech.length || bech.length > 90) {
    return null;
  }
  if (!bech.substring(pos + 1).split('').every((x) => _charset.contains(x))) {
    return null;
  }
  String hrp = bech.substring(0, pos);
  List<int> data = bech
      .substring(pos + 1)
      .split('')
      .map((x) => _charset.indexOf(x))
      .toList();
  Bech32Type? spec = _bech32VerifyChecksum(hrp, data);
  if (spec == null) {
    return null;
  }
  return (hrp, data.sublist(0, data.length - 6), spec);
}

(int, List<int>)? decodeBech32(String address) {
  final decodeBech = _bech32Decode(address);
  if (decodeBech == null) return null;
  final data = decodeBech.$2;
  final bits = convertBits(data.sublist(1), 5, 8, pad: false);
  if (bits == null || bits.length < 2 || bits.length > 40) {
    return null;
  }
  if (data[0] > 16) {
    return null;
  }
  if (data[0] == 0 && bits.length != 20 && bits.length != 32) {
    return null;
  }
  final spec = decodeBech.$3;
  if (data[0] == 0 && spec != Bech32Type.bech32 ||
      data[0] != 0 && spec != Bech32Type.bech32M) {
    return null;
  }
  return (data[0], bits);
}

String? encodeBech32(String hrp, int version, Uint8List data) {
  final type = version == 0 ? Bech32Type.bech32 : Bech32Type.bech32M;
  final bits = convertBits(data, 8, 5);
  if (bits == null) {
    return null;
  }
  final en = _bech32Encode(hrp, Uint16List.fromList([version, ...bits]), type);
  if (decodeBech32(en) == null) {
    return null;
  }
  return en;
}
