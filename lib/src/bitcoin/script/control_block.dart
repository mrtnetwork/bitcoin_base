import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/crypto/keypair/ec_public.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

import 'script.dart';

class ControlBlock {
  ControlBlock({required this.public, this.scriptToSpend, List<int>? scripts})
      : scripts = BytesUtils.tryToBytes(scripts, unmodifiable: true);
  final ECPublic public;
  final Script? scriptToSpend;
  final List<int>? scripts;

  List<int> toBytes() {
    final version = <int>[BitcoinOpCodeConst.LEAF_VERSION_TAPSCRIPT];

    final pubKey = BytesUtils.fromHexString(public.toXOnlyHex());
    final marklePath = scripts ?? [];
    return [...version, ...pubKey, ...marklePath];
  }

  String toHex() {
    return BytesUtils.toHexString(toBytes());
  }
}
