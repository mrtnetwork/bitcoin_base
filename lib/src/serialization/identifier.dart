import 'package:blockchain_utils/cbor/serialization/cbor/tag.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

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
              throw ItemNotFoundException(
                name: "BitcoinSerializationIdentifiers",
              ),
    );
  }

  @override
  bool isValid(int? tag) {
    return tag == id;
  }
}
