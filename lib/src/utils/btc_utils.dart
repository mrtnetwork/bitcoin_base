import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class BtcUtils {
  static bool hasCompressedPubKeyLength(String publicKey) {
    return StringUtils.strip0x(publicKey.toLowerCase()).length == 66;
  }

  static BigInt toSatoshi(String decimal) {
    BigRational dec = BigRational.parseDecimal(decimal);
    dec = dec * BigRational(BigInt.from(10).pow(8));
    return dec.toBigInt();
  }
}
