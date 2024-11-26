library bitcoin_crypto;

import 'package:bitcoin_base/src/bitcoin/script/op_code/constant_lib.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
export 'keypair/ec_private.dart';
export 'keypair/ec_public.dart';

/// Function: taggedHash
/// Description: Computes a tagged hash of the input data with a provided tag.
/// Input:
///   - List<int> data - The data to be hashed.
///   - String tag - A unique tag to differentiate the hash.
/// Output: List<int> - The resulting tagged hash.
/// Note: This function combines the provided tag with the input data to create a unique
/// hash by applying a double SHA-256 hash.
List<int> taggedHash(List<int> data, String tag) {
  /// Calculate the hash of the tag as List<int>.
  final tagDigest = QuickCrypto.sha256Hash(List<int>.from(tag.codeUnits));

  /// Concatenate the tag hash with itself and the input data.
  final concat = List<int>.from([...tagDigest, ...tagDigest, ...data]);

  /// Compute a double SHA-256 hash of the concatenated data.
  return QuickCrypto.sha256Hash(concat);
}

List<int> toTapleafTaggedHash(List<int> scriptBytes) {
  final leafVarBytes = [
    BitcoinOpCodeConst.LEAF_VERSION_TAPSCRIPT,
    ...IntUtils.prependVarint(scriptBytes)
  ];
  return taggedHash(leafVarBytes, "TapLeaf");
}
