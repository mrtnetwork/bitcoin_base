import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';

List<int> opPushData(String hexData) {
  final List<int> dataBytes = BytesUtils.fromHexString(hexData);
  if (dataBytes.length < 0x4c) {
    return List<int>.from([dataBytes.length]) + dataBytes;
  } else if (dataBytes.length < mask8) {
    return List<int>.from([0x4c]) +
        List<int>.from([dataBytes.length]) +
        dataBytes;
  } else if (dataBytes.length < mask16) {
    var lengthBytes = List<int>.filled(2, 0);

    writeUint16LE(dataBytes.length, lengthBytes);
    return List<int>.from([0x4d, ...lengthBytes, ...dataBytes]);
  } else if (dataBytes.length < mask32) {
    var lengthBytes = List<int>.filled(4, 0);
    writeUint32LE(lengthBytes.length, lengthBytes);
    return List<int>.from([0x4e, ...lengthBytes, ...dataBytes]);
  } else {
    throw const BitcoinBasePluginException(
        "Data too large. Cannot push into script");
  }
}

List<int> pushInteger(int integer) {
  if (integer < 0) {
    throw const BitcoinBasePluginException(
        'Integer is currently required to be positive.');
  }

  /// Calculate the number of bytes required to represent the integer
  int numberOfBytes = (integer.bitLength + 7) ~/ 8;

  /// Convert to little-endian bytes
  List<int> integerBytes = List<int>.filled(numberOfBytes, 0);
  for (int i = 0; i < numberOfBytes; i++) {
    integerBytes[i] = (integer >> (i * 8)) & mask8;
  }

  /// If the last bit is set, add a sign byte to signify a positive integer
  if ((integer & (1 << (numberOfBytes * 8 - 1))) != 0) {
    integerBytes = List<int>.from([...integerBytes, 0x00]);
  }

  return List<int>.from(opPushData(BytesUtils.toHexString(integerBytes)));
}
