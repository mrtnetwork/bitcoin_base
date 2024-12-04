import 'package:blockchain_utils/blockchain_utils.dart';

class DartBitcoinPluginException extends BlockchainUtilsException {
  const DartBitcoinPluginException(String message,
      {Map<String, dynamic>? details})
      : super(message, details: details);
}
