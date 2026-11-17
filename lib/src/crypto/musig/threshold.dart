import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/crypto/keypair/ec_private.dart';
import 'package:bitcoin_base/src/crypto/keypair/ec_public.dart';
import 'package:bitcoin_base/src/crypto/musig/signer.dart';

/// One k-of-n subset: its own aggregate key, signer, and tapscript leaf.
///
/// MuSig2 key aggregation (BIP-327) is n-of-n, so a k-of-n policy is expressed
/// as a Taproot script tree with one aggregated key per allowed subset; the
/// spend reveals only the subset that signed.
class Musig2ThresholdLeaf {
  const Musig2ThresholdLeaf({
    required this.members,
    required this.signer,
    required this.leaf,
  });

  /// Group members covered by this leaf (exactly [threshold] keys).
  final List<ECPublic> members;

  /// Signer aggregated over [members] only.
  final Musig2Signer signer;

  /// `<subsetAggKey> OP_CHECKSIG` leaf.
  final TaprootLeaf leaf;
}

/// A k-of-n MuSig2 policy compiled to a Taproot script tree.
///
class Musig2ThresholdTree {
  const Musig2ThresholdTree._({required this.tree, required this.leaves});

  /// Root of the script tree (a [TaprootLeaf] when there is one subset).
  final TaprootTree tree;

  /// One entry per allowed subset, in combination order.
  final List<Musig2ThresholdLeaf> leaves;

  /// Builds a k-of-n tree over [publicKeys].
  ///
  /// [privateKeys] optionally attaches held secrets (matched by public key);
  /// subsets without all secrets keep a public-only signer usable for address
  /// derivation. [sortKeys] is forwarded to [Musig2Signer.generate].
  factory Musig2ThresholdTree.buildKofN({
    required List<ECPublic> publicKeys,
    required int threshold,
    Map<ECPublic, ECPrivate> privateKeys = const {},
    bool sortKeys = true,
  }) {
    if (threshold < 2) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Musig2 threshold must be at least 2.",
      );
    }
    if (threshold > publicKeys.length) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Musig2 threshold ($threshold) exceeds group size (${publicKeys.length}).",
      );
    }
    final combos = _combinations(publicKeys, threshold);
    final built =
        combos.map((members) {
          final secrets = [
            for (final m in members)
              if (privateKeys[m] != null) privateKeys[m]!,
          ];
          final signer = Musig2Signer.generate(
            members,
            privateKeys: secrets,
            sortKeys: sortKeys,
          );
          final leaf = TaprootLeaf(
            script: Script(
              script: [
                signer.aggPublicKey.toXOnlyHex(),
                BitcoinOpcode.opCheckSig,
              ],
            ),
          );
          return Musig2ThresholdLeaf(
            members: members,
            signer: signer,
            leaf: leaf,
          );
        }).toList();
    TaprootTree tree = built.first.leaf;
    for (final entry in built.skip(1)) {
      tree = TaprootBranch(a: tree, b: entry.leaf);
    }
    return Musig2ThresholdTree._(tree: tree, leaves: built);
  }

  /// Finds the leaf covering exactly [members] (order-insensitive).
  Musig2ThresholdLeaf leafFor(List<ECPublic> members) {
    return leaves.firstWhere(
      (e) =>
          e.members.length == members.length &&
          members.every(e.members.contains),
      orElse:
          () =>
              throw BuError(
                DefaultErrorType.invalidArgument,
                "No threshold leaf covers the given members.",
              ),
    );
  }

  static List<List<ECPublic>> _combinations(List<ECPublic> items, int k) {
    final result = <List<ECPublic>>[];
    void walk(int start, List<ECPublic> current) {
      if (current.length == k) {
        result.add(List.of(current));
        return;
      }
      for (var i = start; i < items.length; i++) {
        current.add(items[i]);
        walk(i + 1, current);
        current.removeLast();
      }
    }

    walk(0, []);
    return result;
  }
}
