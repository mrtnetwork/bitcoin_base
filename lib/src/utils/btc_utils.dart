import 'package:blockchain_utils/numbers/big_rational.dart';

class BtcUtils {
  static BigInt toSatoshi(String dec) {
    BigRational decx = BigRational.parseDecimal(dec);
    decx = decx * BigRational(BigInt.from(10).pow(8));
    return decx.toBigInt();
  }
}
