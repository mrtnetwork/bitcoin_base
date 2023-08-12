import 'package:bitcoin/src/bech32/bech32.dart' as bech32;
import 'package:bitcoin/src/crypto/crypto.dart';
import 'package:bitcoin/src/formating/bytes_num_formating.dart';

import 'package:bitcoin/src/models/network.dart';
import 'package:bitcoin/src/bitcoin/address/core.dart';
import 'package:bitcoin/src/bitcoin/constant/constant.dart';
import 'package:bitcoin/src/bitcoin/script/script.dart';

abstract class SegwitAddress implements BitcoinAddress {
  SegwitAddress(
      {String? address,
      String? program,
      Script? script,
      this.version = P2WPKH_ADDRESS_V0}) {
    if (version == P2WPKH_ADDRESS_V0 || version == P2WSH_ADDRESS_V0) {
      segwitNumVersion = 0;
    } else if (version == P2TR_ADDRESS_V1) {
      segwitNumVersion = 1;
    } else {
      throw ArgumentError('A valid segwit version is required.');
    }
    if (program != null) {
      _program = program;
    } else if (address != null) {
      _program = addressToHash(address);
    } else if (script != null) {
      _program = scriptToHash(script);
    }
  }

  late final String _program;

  String get getProgram => _program;

  final String version;
  late final int segwitNumVersion;

  String addressToHash(String address) {
    final convert = bech32.decodeBech32(address);
    if (convert == null) {
      throw ArgumentError("Invalid value for parameter address.");
    }
    final version = convert.$1;
    if (version != segwitNumVersion) {
      throw ArgumentError("Invalid segwit version.");
    }
    return bytesToHex(convert.$2);
  }

  String toAddress(NetworkInfo networkType) {
    final bytes = hexToBytes(_program);
    final sw = bech32.encodeBech32(networkType.bech32, segwitNumVersion, bytes);
    if (sw == null) {
      throw ArgumentError("invalid address");
    }

    return sw;
  }

  String scriptToHash(Script s) {
    final toBytes = s.toBytes();
    final h = singleHash(toBytes);
    return bytesToHex(h);
  }
}

class P2wpkhAddress extends SegwitAddress {
  P2wpkhAddress(
      {super.address, super.program, super.version = P2WPKH_ADDRESS_V0});
  @override
  List<String> toScriptPubKey() {
    return ['OP_0', _program];
  }

  @override
  AddressType get type => AddressType.p2wpkh;
}

class P2trAddress extends SegwitAddress {
  P2trAddress({
    super.program,
    super.address,
  }) : super(version: P2TR_ADDRESS_V1);
  @override
  List<String> toScriptPubKey() {
    return ['OP_1', _program];
  }

  @override
  AddressType get type => AddressType.p2tr;
}

class P2wshAddress extends SegwitAddress {
  P2wshAddress({required super.script}) : super(version: P2WSH_ADDRESS_V0);
  @override
  List<String> toScriptPubKey() {
    return ['OP_0', _program];
  }

  @override
  AddressType get type => AddressType.p2wsh;
}
