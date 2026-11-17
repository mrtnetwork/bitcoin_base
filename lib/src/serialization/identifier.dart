import 'package:blockchain_utils/blockchain_utils.dart';

enum BitcoinSerializationIdentifiers implements SerializationIdentifier {
  bitcoinPluginError(20001),
  bitcoinUtxo(20002);

  @override
  final int id;
  const BitcoinSerializationIdentifiers(this.id);

  static BitcoinSerializationIdentifiers fromIdentifier(int? value) {
    return values.firstWhere(
      (e) => e.id == value,
      orElse:
          () =>
              throw BuError(
                DefaultErrorType.notFound,
                "No matching BitcoinSerializationIdentifiers found for the given value. null",
              ),
    );
  }

  @override
  bool isValid(int? tag) {
    return tag == id;
  }
}
