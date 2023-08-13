import 'package:bitcoin_base/src/bech32/bech32.dart' as bech32;
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';

import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/bitcoin/address/core.dart';
import 'package:bitcoin_base/src/bitcoin/constant/constant.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';

abstract class SegwitAddress implements BitcoinAddress {
  /// Represents a Bitcoin segwit address
  ///
  /// [program] for segwit v0 this is the hash string representation of either the address;
  /// it can be either a public key hash (P2WPKH) or the hash of the script (P2WSH)
  /// for segwit v1 (aka taproot) this is the public key
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
      _program = _addressToHash(address);
    } else if (script != null) {
      _program = _scriptToHash(script);
    }
  }

  late final String _program;

  String get getProgram => _program;

  final String version;
  late final int segwitNumVersion;

  String _addressToHash(String address) {
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

  /// returns the address's string encoding (Bech32)
  String toAddress(NetworkInfo networkType) {
    final bytes = hexToBytes(_program);
    final sw = bech32.encodeBech32(networkType.bech32, segwitNumVersion, bytes);
    if (sw == null) {
      throw ArgumentError("invalid address");
    }

    return sw;
  }

  String _scriptToHash(Script s) {
    final toBytes = s.toBytes();
    final h = singleHash(toBytes);
    return bytesToHex(h);
  }
}

class P2wpkhAddress extends SegwitAddress {
  /// Encapsulates a P2WPKH address.
  P2wpkhAddress(
      {super.address, super.program, super.version = P2WPKH_ADDRESS_V0});

  /// returns the scriptPubKey of a P2WPKH witness script
  @override
  List<String> toScriptPubKey() {
    return ['OP_0', _program];
  }

  /// returns the type of address
  @override
  AddressType get type => AddressType.p2wpkh;
}

class P2trAddress extends SegwitAddress {
  /// Encapsulates a P2TR (Taproot) address.
  P2trAddress({
    super.program,
    super.address,
  }) : super(version: P2TR_ADDRESS_V1);

  /// returns the scriptPubKey of a P2TR witness script
  @override
  List<String> toScriptPubKey() {
    return ['OP_1', _program];
  }

  /// returns the type of address
  @override
  AddressType get type => AddressType.p2tr;
}

class P2wshAddress extends SegwitAddress {
  /// Encapsulates a P2WSH address.
  P2wshAddress({required super.script}) : super(version: P2WSH_ADDRESS_V0);

  /// Returns the scriptPubKey of a P2WPKH witness script
  @override
  List<String> toScriptPubKey() {
    return ['OP_0', _program];
  }

  /// Returns the type of address
  @override
  AddressType get type => AddressType.p2wsh;
}
