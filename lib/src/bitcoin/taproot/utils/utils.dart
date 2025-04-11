import 'dart:typed_data';

import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/constants/constants.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/types/types.dart';
import 'package:bitcoin_base/src/crypto/keypair/ec_public.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class TaprootUtils {
  static List<int> taggedHash(List<int> data, List<int> tagDigest) {
    return QuickCrypto.sha256Hash([...tagDigest, ...tagDigest, ...data]);
  }

  static List<int> tapLeafTaggedHash(List<int> data) {
    return taggedHash(data, TaprootConst.tapLeafHashDomain);
  }

  static List<int> tapSigTaggedHash(List<int> data) {
    return taggedHash(data, TaprootConst.tapSigHshDomain);
  }

  static List<int> tapTweakTaggedHash(List<int> data) {
    return taggedHash(data, TaprootConst.tapTweakHashDomain);
  }

  static List<int> tapleafTaggedHash(
      {required Script script,
      int leafVersion = BitcoinOpCodeConst.leafVersionTapscript}) {
    final leafVarBytes = [
      leafVersion,
      ...IntUtils.prependVarint(script.toBytes())
    ];
    return tapLeafTaggedHash(leafVarBytes);
  }

  static List<int> tapbranchTaggedHash(List<int> a, List<int> b) {
    if (BytesUtils.isLessThanBytes(a, b)) {
      return taggedHash([...a, ...b], TaprootConst.tapBranchHashDomain);
    }
    return taggedHash([...b, ...a], TaprootConst.tapBranchHashDomain);
  }

  static List<int>? generateMerkleProof(
      {required TaprootTree scriptTree, required TaprootLeaf leafScript}) {
    if (scriptTree == leafScript) return [];
    if (scriptTree is TaprootLeaf) {
      return null;
    }
    final branch = scriptTree.cast<TaprootBranch>();
    final a = generateMerkleProof(scriptTree: branch.a, leafScript: leafScript);
    if (a != null) {
      return [...a, ...branch.b.hash()];
    }
    final b = generateMerkleProof(scriptTree: branch.b, leafScript: leafScript);
    if (b != null) {
      return [...b, ...branch.a.hash()];
    }
    return null;
  }

  static ProjectiveECCPoint tweakPublicKey(List<int> pubKey,
      {TaprootTree? treeScript, List<int>? merkleRoot}) {
    if (merkleRoot != null && merkleRoot.length != 32) {
      throw DartBitcoinPluginException(
          "Invalid Merkle root: must be exactly 32 bytes.",
          details: {
            "length": merkleRoot.length,
          });
    }
    List<int>? xKey = pubKey.clone();
    if (xKey.length == EcdsaKeysConst.pubKeyCompressedByteLen) {
      xKey = xKey.sublist(1);
    }
    final tweak =
        calculateTweek(xKey, treeScript: treeScript, merkleRoot: merkleRoot);
    return tweakInternalKey(xKey, tweak);
  }

  static List<int> calculateTweek(List<int> xKey,
      {TaprootTree? treeScript, List<int>? merkleRoot}) {
    if (treeScript != null && merkleRoot != null) {
      throw DartBitcoinPluginException(
          "Provide either a Merkle root or script trees to generate one, but not both.");
    }
    if (xKey.length != 32) {
      throw DartBitcoinPluginException("Invalid XOnlyKey length.",
          details: {"excpected": 32, "length": xKey.length});
    }
    final tweek = tapTweakTaggedHash(
      [...xKey, ...treeScript?.hash() ?? merkleRoot ?? []],
    );
    return tweek;
  }

  static ProjectiveECCPoint tweakInternalKey(
      List<int> internalPubKey, List<int> leafHash) {
    final x = BigintUtils.fromBytes(internalPubKey);
    final n = Curves.generatorSecp256k1 * BigintUtils.fromBytes(leafHash);
    final outPoint = P2TRUtils.liftX(x) + n;
    return outPoint as ProjectiveECCPoint;
  }

  static List<TaprootLeaf> extractLeafs(TaprootTree treeScript) {
    if (treeScript is TaprootLeaf) return [treeScript];
    final branch = treeScript.cast<TaprootBranch>();
    return [...extractLeafs(branch.a), ...extractLeafs(branch.b)];
  }

  static List<TaprootLeaf> extractLeafs2(TaprootTree treeScript) {
    if (treeScript is TaprootLeaf) return [treeScript];
    final branch = treeScript.cast<TaprootBranch>();
    return [...extractLeafs(branch.a), ...extractLeafs(branch.b)];
  }

  /// Computes the Taproot Merkle Root from a list of leaf hashes.
  static List<int>? computeTaprootMerkleRoot(List<List<int>> leavesHashes) {
    if (leavesHashes.isEmpty) return null; // No scripts, key-path spend

    // Sort leaf hashes lexicographically
    leavesHashes.sort((a, b) => BytesUtils.compareBytes(a, b));

    // Process the tree iteratively
    while (leavesHashes.length > 1) {
      List<List<int>> newLevel = [];

      for (int i = 0; i < leavesHashes.length; i += 2) {
        List<int> left = leavesHashes[i];
        List<int> right =
            (i + 1 < leavesHashes.length) ? leavesHashes[i + 1] : left;

        // // Ensure lexicographic order before hashing
        // if (Uint8List.fromList(left).compareTo(Uint8List.fromList(right)) > 0) {
        //   Uint8List temp = left;
        //   left = right;
        //   right = temp;
        // }

        // Compute TapBranch(A, B) = TaggedHash("TapBranch", A || B)
        Uint8List parent = Uint8List.fromList(tapbranchTaggedHash(left, right));
        newLevel.add(parent);
      }

      leavesHashes = newLevel; // Move to the next level
    }

    return leavesHashes.first; // The final hash is the Merkle root
  }

  static List<TapLeafMerkleProof> generateAllPossibleProofs(
      {required TaprootTree treeScript,
      required List<int> xOnlyOrInternalPubKey}) {
    final leafs = extractLeafs(treeScript).toSet();
    return leafs
        .map(
          (e) => TapLeafMerkleProof.generate(
              leafScript: e,
              scriptTree: treeScript,
              xOnlyOrInternalPubKey: xOnlyOrInternalPubKey),
        )
        .toList();
  }

  static List<int> toXOnly(List<int> xOnlyOrInternalPubKey) {
    if (xOnlyOrInternalPubKey.length == EcdsaKeysConst.pointCoordByteLen) {
      return xOnlyOrInternalPubKey;
    }
    if (xOnlyOrInternalPubKey.length ==
        EcdsaKeysConst.pubKeyCompressedByteLen) {
      return xOnlyOrInternalPubKey.sublist(1);
    }
    if (xOnlyOrInternalPubKey.length ==
            EcdsaKeysConst.pubKeyCompressedByteLen ||
        xOnlyOrInternalPubKey.length ==
            EcdsaKeysConst.pubKeyUncompressedByteLen) {
      try {
        return ECPublic.fromBytes(xOnlyOrInternalPubKey).toXOnly();
      } catch (_) {}
    }
    throw DartBitcoinPluginException("Invalid xOnly or Public key.");
  }

  static String toXonlyHex(String xOnlyKey) {
    final bytes = BytesUtils.tryFromHexString(xOnlyKey);
    if (bytes == null || bytes.length != EcdsaKeysConst.pointCoordByteLen) {
      throw DartBitcoinPluginException("Invalid xOnly key.");
    }
    return StringUtils.strip0x(xOnlyKey.toLowerCase());
  }
}
