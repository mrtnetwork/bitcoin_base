import 'dart:typed_data';

import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';

List<int> opPushData(String hexData) {
  final dataBytes = BytesUtils.fromHexString(hexData);
  if (dataBytes.length < BitcoinOpCodeConst.opPushData1) {
    return [dataBytes.length, ...dataBytes];
  } else if (dataBytes.length < mask8) {
    return [BitcoinOpCodeConst.opPushData1, dataBytes.length, ...dataBytes];
  } else if (dataBytes.length < mask16) {
    final lengthBytes =
        IntUtils.toBytes(dataBytes.length, length: 2, byteOrder: Endian.little);
    return [BitcoinOpCodeConst.opPushData2, ...lengthBytes, ...dataBytes];
  } else if (dataBytes.length < mask32) {
    final lengthBytes =
        IntUtils.toBytes(dataBytes.length, length: 4, byteOrder: Endian.little);
    return [BitcoinOpCodeConst.opPushData4, ...lengthBytes, ...dataBytes];
  } else {
    throw const DartBitcoinPluginException(
        'Data too large. Cannot push into script');
  }
}

List<int> pushInteger(int integer) {
  if (integer < 0) {
    throw const DartBitcoinPluginException(
        'Integer is currently required to be positive.');
  }

  /// Calculate the number of bytes required to represent the integer
  final numberOfBytes = (integer.bitLength + 7) ~/ 8;

  /// Convert to little-endian bytes
  var integerBytes = List<int>.filled(numberOfBytes, 0);
  for (var i = 0; i < numberOfBytes; i++) {
    integerBytes[i] = (integer >> (i * 8)) & mask8;
  }

  /// If the last bit is set, add a sign byte to signify a positive integer
  if ((integer & (1 << (numberOfBytes * 8 - 1))) != 0) {
    integerBytes = List<int>.from([...integerBytes, 0x00]);
  }

  return List<int>.from(opPushData(BytesUtils.toHexString(integerBytes)));
}
