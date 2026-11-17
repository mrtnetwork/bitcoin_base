import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:bitcoin_base/src/provider/models/multisig_script.dart';

/// Utils for the multi-signature inputs of the transaction builders.
class BtcMultisigUtils {
  /// Builds the ordered list of the signatures of a multi-signature input.
  ///
  /// The multi-signature script of a [MultiSignatureAddress] is
  /// `OP_M <public keys> OP_N OP_CHECKMULTISIG` where the public key of every
  /// signer is repeated as many times as its weight. The signatures of a
  /// `OP_CHECKMULTISIG` script are matched to the public keys of the script in
  /// the same order (the public keys that are not signed are skipped) and,
  /// since the same public key is present more than once in the script, the
  /// signature of a signer with a weight of `w` is used `w` times.
  ///
  /// [signatures] contains the signature of every signer keyed by the signer's
  /// public key, a signer without a signature is considered as "not signed".
  static List<String> buildSignatures({
    required MultiSignatureAddress multiSigAddress,
    required Map<String, String> signatures,
  }) {
    final threshold = multiSigAddress.threshold;
    final result = <String>[];
    final missing = <String>[];
    for (final signer in multiSigAddress.signers) {
      if (result.length >= threshold) break;
      final signature = findSignature(signatures, signer);
      if (signature == null || signature.isEmpty) {
        missing.add(signer.publicKey);
        continue;
      }
      for (var w = 0; w < signer.weight && result.length < threshold; w++) {
        result.add(signature);
      }
    }
    if (result.length < threshold) {
      throw BuError(
        DefaultErrorType.invalidState,
        'some multisig signature does not exist',
        details: {
          'threshold': '$threshold',
          'missingSigners': missing.join(','),
        },
      );
    }
    return result;
  }

  /// Finds the signature of the given signer inside the provided signatures.
  static String? findSignature(
    Map<String, String> signatures,
    MultiSignatureSigner signer,
  ) {
    final signature = signatures[signer.publicKey];
    if (signature != null) return signature;

    /// the public key can be provided with a different encoding
    /// (compressed or uncompressed), so the normalized value is checked too.
    for (final entry in signatures.entries) {
      final normalized = normalizePublicKey(entry.key, signer.keyType);
      if (normalized != null && normalized == signer.publicKey) {
        return entry.value;
      }
    }
    return null;
  }

  /// Normalizes the given public key with the given encoding.
  static String? normalizePublicKey(String publicKey, PublicKeyType keyType) {
    try {
      return ECPublic.fromHex(publicKey).toHex(mode: keyType);
    } catch (_) {
      return null;
    }
  }
}
