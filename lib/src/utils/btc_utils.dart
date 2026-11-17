import 'package:bitcoin_base/src/crypto/keypair/ec_public.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class BtcUtils {
  static PublicKeyType determinatePubKeyModeHex(String publicKey) {
    publicKey = StringUtils.strip0x(publicKey.toLowerCase());
    if (publicKey.length != EcdsaKeysConst.pubKeyCompressedByteLen * 2 &&
        publicKey.length != EcdsaKeysConst.pubKeyUncompressedByteLen * 2) {
      throw BuError(
        DefaultErrorType.invalidLength,
        "Invalid Secp256k1 public key hex length.",
      );
    }
    final isCompressed =
        publicKey.length == EcdsaKeysConst.pubKeyCompressedByteLen * 2;
    if (isCompressed) return PublicKeyType.base;
    return PublicKeyType.uncompressed;
  }

  static PublicKeyType determinatePubKeyMode(List<int> publicKey) {
    if (publicKey.length != EcdsaKeysConst.pubKeyCompressedByteLen &&
        publicKey.length != EcdsaKeysConst.pubKeyUncompressedByteLen) {
      throw BuError(
        DefaultErrorType.invalidLength,
        "Invalid Secp256k1 public key length.",
      );
    }
    final isCompressed =
        publicKey.length == EcdsaKeysConst.pubKeyCompressedByteLen;
    if (isCompressed) return PublicKeyType.base;
    return PublicKeyType.uncompressed;
  }

  static BigInt toSatoshi(String decimal) {
    var dec = BigRational.parseDecimal(decimal);
    dec = dec * BigRational(BigInt.from(10).pow(8));
    return dec.toBigInt();
  }

  static String toBtc(BigInt amount) {
    BigRational dec = BigRational(amount);
    dec = dec / BigRational(BigInt.from(10).pow(8));
    return dec.toDecimal(digits: 8);
  }
}
