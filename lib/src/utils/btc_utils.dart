import 'package:bitcoin_base/src/crypto/keypair/ec_public.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class BtcUtils {
  static PublicKeyType isCompressedPubKey(String publicKey) {
    final isCompressed =
        StringUtils.strip0x(publicKey.toLowerCase()).length == 66;
    if (isCompressed) return PublicKeyType.compressed;
    return PublicKeyType.uncompressed;
  }

  static BigInt toSatoshi(String decimal) {
    var dec = BigRational.parseDecimal(decimal);
    dec = dec * BigRational(BigInt.from(10).pow(8));
    return dec.toBigInt();
  }
}
