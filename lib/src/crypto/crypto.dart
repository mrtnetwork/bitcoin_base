library bitcoin_crypto;

import 'package:pointycastle/export.dart';
import "dart:typed_data";
export 'ec/ec_private.dart';
export 'ec/ec_public.dart';
// ignore: implementation_imports
import 'package:pointycastle/src/platform_check/platform_check.dart'
    as platform;

// Function: doubleSh256
// Description: Performs a double SHA-256 hash on the input data.
// Input: Uint8List value - The data to be hashed.
// Output: Uint8List - The result of applying SHA-256 twice on the input data.
// Note: This function is commonly used in cryptographic operations to enhance security.
// It applies SHA-256 hash function twice (double hashing) to the input data for added protection.
Uint8List doubleSh256(Uint8List value) {
  // Initialize a SHA-256 digest.
  Digest digest = SHA256Digest();

  // Apply SHA-256 twice (double hashing) to the input data.
  return digest.process(digest.process(value));
}

// Function: hash160
// Description: Computes the RIPEMD-160 hash of the SHA-256 hash of the input data.
// Input: Uint8List buffer - The data to be hashed.
// Output: Uint8List - The resulting RIPEMD-160 hash.
// Note: This function is commonly used in Bitcoin and other blockchain-related operations
// to create hash representations of public keys and addresses.
Uint8List hash160(Uint8List buffer) {
  // Compute the SHA-256 hash of the input data.
  Uint8List tmp = SHA256Digest().process(buffer);

  // Compute the RIPEMD-160 hash of the SHA-256 hash.
  return RIPEMD160Digest().process(tmp);
}

// Function: doubleHash
// Description: Computes a double SHA-256 hash of the input data.
// Input: Uint8List buffer - The data to be hashed.
// Output: Uint8List - The resulting double SHA-256 hash.
// Note: Double hashing is a common cryptographic technique used to enhance data security.
Uint8List doubleHash(Uint8List buffer) {
  // Compute the first SHA-256 hash of the input data.
  Uint8List tmp = SHA256Digest().process(buffer);

  // Compute the second SHA-256 hash of the first hash.
  return SHA256Digest().process(tmp);
}

// Function: singleHash
// Description: Computes a single SHA-256 hash of the input data.
// Input: Uint8List buffer - The data to be hashed.
// Output: Uint8List - The resulting single SHA-256 hash.
// Note: This function calculates a single SHA-256 hash of the input data.
Uint8List singleHash(Uint8List buffer) {
  // Compute a single SHA-256 hash of the input data.
  return SHA256Digest().process(buffer);
}

// Function: taggedHash
// Description: Computes a tagged hash of the input data with a provided tag.
// Input:
//   - Uint8List data - The data to be hashed.
//   - String tag - A unique tag to differentiate the hash.
// Output: Uint8List - The resulting tagged hash.
// Note: This function combines the provided tag with the input data to create a unique
// hash by applying a double SHA-256 hash.
Uint8List taggedHash(Uint8List data, String tag) {
  // Calculate the hash of the tag as Uint8List.
  final tagDigest = singleHash(Uint8List.fromList(tag.codeUnits));

  // Concatenate the tag hash with itself and the input data.
  final concat = Uint8List.fromList([...tagDigest, ...tagDigest, ...data]);

  // Compute a double SHA-256 hash of the concatenated data.
  return singleHash(concat);
}

FortunaRandom? _randomGenerator;
// Variable: _randomGenerator
// Description: An instance of the FortunaRandom generator for generating random data.

// Function: generateRandom
// Description: Generates random data of the specified size using the FortunaRandom generator.
// Input: int size - The size of the random data to generate (default is 32 bytes).
// Output: Uint8List - The generated random data.
// Note: This function initializes the FortunaRandom generator if it's not already initialized,
// seeds it with platform entropy, and then generates random data of the specified size.
Uint8List generateRandom({int size = 32}) {
  if (_randomGenerator == null) {
    // Initialize the FortunaRandom generator and seed it with platform entropy.
    _randomGenerator = FortunaRandom();
    _randomGenerator!.seed(KeyParameter(
        platform.Platform.instance.platformEntropySource().getBytes(32)));
  }

  // Generate random data of the specified size.
  final r = _randomGenerator!.nextBytes(size);

  return r;
}
