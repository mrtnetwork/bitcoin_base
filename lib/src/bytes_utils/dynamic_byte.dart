import 'package:blockchain_utils/binary/binary_operation.dart';

class DynamicByteTracker {
  final List<int> _buffer = List<int>.empty(growable: true);

  List<int> toBytes() {
    return List<int>.from(_buffer, growable: false);
  }

  void add(List<int> chunk) {
    for (int i in chunk) {
      _buffer.add(i & mask8);
    }
  }
}
