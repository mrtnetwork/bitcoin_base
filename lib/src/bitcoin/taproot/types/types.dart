import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/utils/utils.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// Abstract class representing a Taproot tree structure (leaf or branch).
abstract class TaprootTree {
  const TaprootTree();
  List<int> hash();
  String toHex() {
    return BytesUtils.toHexString(hash());
  }

  T cast<T extends TaprootTree>() {
    if (this is! T) {
      throw DartBitcoinPluginException(
          "Invalid cast: expected ${T.runtimeType}, but found $runtimeType.",
          details: {"expected": "$T", "type": runtimeType.toString()});
    }
    return this as T;
  }

  Map<String, dynamic> toJson();
  factory TaprootTree.fromJson(Map<String, dynamic> json) {
    if (json.containsKey("a")) {
      return TaprootBranch.fromJson(json);
    }
    return TaprootLeaf.fromJson(json);
  }
}

/// Represents a Taproot script leaf node (a script inside a Taproot tree).
class TaprootLeaf extends TaprootTree {
  final Script script;
  final int leafVersion;
  final List<int> _hash;

  factory TaprootLeaf.fromJson(Map<String, dynamic> json) {
    return TaprootLeaf(
        script: Script.fromJson(json["script"]),
        leafVersion: IntUtils.parse(json["leaf_version"]));
  }
  TaprootLeaf(
      {required this.script,
      this.leafVersion = BitcoinOpCodeConst.leafVersionTapscript})
      : _hash = TaprootUtils.tapleafTaggedHash(
                script: script, leafVersion: leafVersion)
            .asImmutableBytes;
  @override
  Map<String, dynamic> toJson() {
    return {
      "script": script.toJson(),
      "leaf_version": leafVersion,
    };
  }

  @override
  List<int> hash() {
    return _hash.clone();
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is TaprootLeaf && BytesUtils.bytesEqual(_hash, other._hash)) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode => HashCodeGenerator.generateBytesHashCode(_hash);
}

/// Represents an internal node (Merkle branch) in the Taproot tree.
class TaprootBranch extends TaprootTree {
  final List<int> _branch;
  final TaprootTree a;
  final TaprootTree b;

  TaprootBranch._({required this.a, required this.b, required List<int> branch})
      : _branch = branch.asImmutableBytes;
  factory TaprootBranch({required TaprootTree a, required TaprootTree b}) {
    final aHash = a.hash();
    final bHash = b.hash();
    final branch = TaprootUtils.tapbranchTaggedHash(aHash, bHash);
    if (BytesUtils.isLessThanBytes(aHash, bHash)) {
      return TaprootBranch._(a: a, b: b, branch: branch);
    }
    return TaprootBranch._(a: b, b: a, branch: branch);
  }
  factory TaprootBranch.fromJson(Map<String, dynamic> json) {
    return TaprootBranch(
        a: TaprootTree.fromJson(json["a"]), b: TaprootTree.fromJson(json["b"]));
  }
  @override
  Map<String, dynamic> toJson() {
    return {"a": a.toJson(), "b": b.toJson()};
  }

  @override
  List<int> hash() {
    return _branch.clone();
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is TaprootBranch &&
        BytesUtils.bytesEqual(_branch, other._branch)) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode => HashCodeGenerator.generateBytesHashCode(_branch);
}

class TaprootControlBlock {
  TaprootControlBlock._(
      {required List<int> xOnly,
      required List<int> merklePath,
      required this.leafVersion})
      : merklePath = merklePath.asImmutableBytes,
        xOnly = xOnly.asImmutableBytes;
  factory TaprootControlBlock(
      {required List<int> xOnly,
      required int leafVersion,
      List<int>? merklePath}) {
    if (merklePath != null &&
        merklePath.isNotEmpty &&
        (merklePath.length % QuickCrypto.sha256DigestSize != 0)) {
      throw DartBitcoinPluginException(
          "Invalid Merkle path: Length (${merklePath.length}) is not a multiple of ${QuickCrypto.sha256DigestSize} bytes.");
    }
    if (xOnly.length != EcdsaKeysConst.pointCoordByteLen) {
      throw DartBitcoinPluginException(
          "Invalid x-only public key length: Expected ${EcdsaKeysConst.pointCoordByteLen} bytes, got ${xOnly.length} bytes.");
    }
    return TaprootControlBlock._(
        xOnly: xOnly, merklePath: merklePath ?? [], leafVersion: leafVersion);
  }
  factory TaprootControlBlock.generate(
      {required List<int> xOnlyOrInternalPubKey,
      required TaprootLeaf leafScript,
      required TaprootTree scriptTree}) {
    final proof = TaprootUtils.generateMerkleProof(
        scriptTree: scriptTree, leafScript: leafScript);
    if (proof == null) {
      throw DartBitcoinPluginException(
          "Leaf script not found in the provided Taproot script tree.");
    }
    List<int> xOnly;
    if (xOnlyOrInternalPubKey.length == EcdsaKeysConst.pointCoordByteLen) {
      xOnly = xOnlyOrInternalPubKey;
    } else {
      try {
        xOnly = ECPublic.fromBytes(xOnlyOrInternalPubKey).toXOnly();
      } catch (_) {
        throw DartBitcoinPluginException(
            "Invalid xOnlyOrInternalPubKey: It must be a valid x-only or secp256k1 public key.");
      }
    }
    final keyBytes =
        TaprootUtils.tweakPublicKey(xOnly, treeScript: scriptTree).toBytes();
    final parity = keyBytes[0] & 1;
    final leafVersion = leafScript.leafVersion | parity;
    return TaprootControlBlock(
        xOnly: xOnly, merklePath: proof, leafVersion: leafVersion);
  }

  factory TaprootControlBlock.deserialize(List<int> bytes) {
    if (bytes.length < EcdsaKeysConst.pubKeyCompressedByteLen) {
      throw DartBitcoinPluginException("Invalid control block bytes length.");
    }
    final path = bytes.sublist(EcdsaKeysConst.pubKeyCompressedByteLen);
    if (path.length % QuickCrypto.sha256DigestSize != 0) {
      throw DartBitcoinPluginException(
          "Invalid control block: too short (must be at least 33 bytes, got ${bytes.length})");
    }
    return TaprootControlBlock(
        xOnly: bytes.sublist(1, EcdsaKeysConst.pubKeyCompressedByteLen),
        leafVersion: bytes[0],
        merklePath: path);
  }

  final List<int> xOnly;
  final List<int> merklePath;
  final int leafVersion;

  List<int> toBytes() {
    return [leafVersion, ...xOnly, ...merklePath];
  }

  String toHex() {
    return BytesUtils.toHexString(toBytes());
  }
}

class TapLeafMerkleProof {
  final TaprootLeaf script;
  final TaprootControlBlock controlBlock;
  const TapLeafMerkleProof({required this.script, required this.controlBlock});
  factory TapLeafMerkleProof.generate(
      {required List<int> xOnlyOrInternalPubKey,
      required TaprootLeaf leafScript,
      required TaprootTree scriptTree}) {
    return TapLeafMerkleProof(
        script: leafScript,
        controlBlock: TaprootControlBlock.generate(
            xOnlyOrInternalPubKey: xOnlyOrInternalPubKey,
            leafScript: leafScript,
            scriptTree: scriptTree));
  }
  factory TapLeafMerkleProof.fromJson(Map<String, dynamic> json) {
    return TapLeafMerkleProof(
        script: TaprootLeaf.fromJson(json['script']),
        controlBlock: TaprootControlBlock.deserialize(
            BytesUtils.fromHexString(json["control_block"])));
  }
  Map<String, dynamic> toJson() {
    return {"script": script.toJson(), "control_block": controlBlock.toHex()};
  }
}
