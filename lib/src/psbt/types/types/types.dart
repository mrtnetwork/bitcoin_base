import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class PsbtTapTree {
  final int depth;
  final int leafVersion;
  final Script script;
  PsbtTapTree({
    required int depth,
    required int leafVersion,
    required this.script,
  }) : depth = depth.asU8,
       leafVersion = leafVersion.asU8;
  List<int> serialize() {
    final scriptBytes = IntUtils.prependVarint(script.toBytes());
    return [depth, leafVersion, ...scriptBytes];
  }

  Map<String, dynamic> toJson() {
    return {
      "depth": depth,
      "leafVersion": leafVersion,
      "script": script.toJson(),
    };
  }
}
