import 'package:bitcoin/src/bitcoin/constant/constant.dart';
import 'package:bitcoin/src/crypto/ec/ec_public.dart';
import 'package:bitcoin/src/formating/bytes_num_formating.dart';
import 'package:flutter/services.dart';

import 'script.dart';

class ControlBlock {
  ControlBlock({required this.public, this.scriptToSpend, this.scripts});
  late final ECPublic public;
  Script? scriptToSpend;
  Uint8List? scripts;

  Uint8List toBytes() {
    final Uint8List version = Uint8List.fromList([LEAF_VERSION_TAPSCRIPT]);

    final Uint8List pubKey = hexToBytes(public.toXOnlyHex());
    final Uint8List marklePath = scripts ?? Uint8List(0);
    return Uint8List.fromList([...version, ...pubKey, ...marklePath]);
  }

  String toHex() {
    return bytesToHex(toBytes());
  }
}
