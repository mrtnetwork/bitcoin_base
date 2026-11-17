import 'package:blockchain_utils/blockchain_utils.dart';

/// Bitcoin-specific error types. Phase 2: taxonomy only, no serialization.
enum BitcoinErrorType implements BuErrorType {
  plugin(10000);

  @override
  String get domain => 'bitcoin';

  @override
  String get errName => name;

  @override
  final int id;
  const BitcoinErrorType(this.id);

  @override
  bool isValid(int? tag) {
    return tag == id;
  }
}
