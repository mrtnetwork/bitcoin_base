import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart' show test, expect, isA, equals;

import 'utils.dart';

void exceptionTest() {
  test('Bitcoin error CBOR round-trip', () {
    BuErrorCodec.registerTypes(BitcoinErrorType.values);
    const error = BuError(
      BitcoinErrorType.plugin,
      "error",
      details: {"length": "32"},
    );
    final bytes = error.toCborBytes();
    final decode = BuErrorCodec.decode(bytes: bytes);
    expect(decode.type, BitcoinErrorType.plugin);
    expect(decode.message, "error");
    expect(decode.details, {"length": "32"});
  });

  test('unknown identifier decodes to invalidArgument BuError', () {
    // Unknown tags must surface as errors, never throw or mis-decode.
    final decoded = BuErrorCodec.decode(
      bytes: const BuError(_Unknown(999999), 'x').toCborBytes(),
    );
    expect(decoded, isA<BuError>());
    expect(decoded.type, DefaultErrorType.invalidArgument);
  });

  test('bitcoin identifiers are unique and above 258', () {
    final ids = BitcoinErrorType.values.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(id > 258, equals(true));
    }
  });
}

class _Unknown implements BuErrorType {
  const _Unknown(this.id);
  @override
  String get domain => 'test';
  @override
  String get errName => 'unknown';
  @override
  final int id;

  @override
  bool isValid(int? tag) => tag == id;
}

void exceptionTest2() {
  BitcoinBaseTestApi.runTest(exceptionTest, "Exception");
}

void main() {
  BitcoinBaseTestApi.runTest(exceptionTest2, "Exception");
}
