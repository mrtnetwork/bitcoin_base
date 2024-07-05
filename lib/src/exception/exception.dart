import 'package:blockchain_utils/blockchain_utils.dart';

class BitcoinBasePluginException extends BlockchainUtilsException {
  @override
  final String message;
  @override
  final Map<String, dynamic>? details;
  const BitcoinBasePluginException(this.message, {this.details});
}
