import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:test/test.dart' show test, expect;

void main() {
  test('Exception serialization', () {
    {
      final error = DartBitcoinPluginException(
        "error",
        details: {"length": "32"},
      );
      final decode = DartBitcoinPluginException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
  });
}
