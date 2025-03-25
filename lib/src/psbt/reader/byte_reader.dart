import 'package:blockchain_utils/blockchain_utils.dart';

class PsbtByteReader {
  final List<int> bytes;
  PsbtByteReader(List<int> bytes) : bytes = bytes.immutable;
  int _offset = 0;
  int get offset => _offset;
  int get length => bytes.length;
  List<int> read(int length) {
    final bytes = this.bytes.sublist(_offset, _offset + length);
    _offset += length;
    return bytes;
  }

  void skip(int length) {
    assert(_offset + 1 <= bytes.length);
    _offset += length;
  }

  int at() {
    return bytes[_offset];
  }

  int readLength() {
    final length = IntUtils.decodeVarint(bytes.sublist(_offset));
    _offset += length.item2;
    return length.item1;
  }
}
