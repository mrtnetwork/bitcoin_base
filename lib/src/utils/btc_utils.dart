import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';

class BtcUtils {
  static BigInt toSatoshi(String decimal) {
    BigRational dec = BigRational.parseDecimal(decimal);
    dec = dec * BigRational(BigInt.from(10).pow(8));
    return dec.toBigInt();
  }
}
