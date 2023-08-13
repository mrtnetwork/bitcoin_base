import 'dart:convert';
import 'dart:typed_data';
import 'package:typed_data/typed_buffers.dart';

class DynamicByteTracker extends ByteConversionSinkBase {
  final Uint8Buffer _buffer = Uint8Buffer();
  int _length = 0;

  int get length => _length;

  Uint8List toBytes() {
    return _buffer.buffer.asUint8List(0, _length);
  }

  @override
  void add(List<int> chunk) {
    _buffer.addAll(chunk);
    _length += chunk.length;
  }

  @override
  void close() {
    // dont need
  }
}
