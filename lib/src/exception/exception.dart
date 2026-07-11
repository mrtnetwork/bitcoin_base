import 'package:bitcoin_base/src/serialization/identifier.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class DartBitcoinPluginException extends IException {
  const DartBitcoinPluginException(super.message, {super.details});

  factory DartBitcoinPluginException.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: BitcoinSerializationIdentifiers.bitcoinPluginError,
    );
    return DartBitcoinPluginException(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BitcoinSerializationIdentifiers get serializationIdentifier =>
      BitcoinSerializationIdentifiers.bitcoinPluginError;

  @override
  BlockchainNetwork? get relatedNetwork => BlockchainNetwork.bitcoinAndRelated;
}
