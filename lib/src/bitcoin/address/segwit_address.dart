import 'package:bitcoin_base/src/bitcoin/address/core.dart';
import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:blockchain_utils/bech32/bech32.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

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
      this.version = BitcoinOpCodeConst.P2WPKH_ADDRESS_V0}) {
    if (version == BitcoinOpCodeConst.P2WPKH_ADDRESS_V0 ||
        version == BitcoinOpCodeConst.P2WSH_ADDRESS_V0) {
      segwitNumVersion = 0;
    } else if (version == BitcoinOpCodeConst.P2TR_ADDRESS_V1) {
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
    final convert = SegwitBech32Decoder.decode(null, address);

    final version = convert.$1;
    if (version != segwitNumVersion) {
      throw ArgumentError("Invalid segwit version.");
    }
    return BytesUtils.toHexString(convert.$2);
  }

  /// returns the address's string encoding (Bech32)
  @override
  String toAddress(BitcoinNetwork networkType) {
    final bytes = BytesUtils.fromHexString(_program);
    final sw = SegwitBech32Encoder.encode(
        networkType.p2wpkhHrp, segwitNumVersion, bytes);
    return sw;
  }

  String _scriptToHash(Script script) {
    final toBytes = script.toBytes();
    final toHash = QuickCrypto.sha256Hash(toBytes);
    return BytesUtils.toHexString(toHash);
  }
}

class P2wpkhAddress extends SegwitAddress {
  /// Encapsulates a P2WPKH address.
  P2wpkhAddress(
      {super.address,
      super.program,
      super.version = BitcoinOpCodeConst.P2WPKH_ADDRESS_V0});

  /// returns the scriptPubKey of a P2WPKH witness script
  @override
  Script toScriptPubKey() {
    return Script(script: ['OP_0', _program]);
  }

  /// returns the type of address
  @override
  BitcoinAddressType get type => BitcoinAddressType.p2wpkh;
}

class P2trAddress extends SegwitAddress {
  /// Encapsulates a P2TR (Taproot) address.
  P2trAddress({
    super.program,
    super.address,
  }) : super(version: BitcoinOpCodeConst.P2TR_ADDRESS_V1);

  /// returns the scriptPubKey of a P2TR witness script
  @override
  Script toScriptPubKey() {
    return Script(script: ['OP_1', _program]);
  }

  /// returns the type of address
  @override
  BitcoinAddressType get type => BitcoinAddressType.p2tr;
}

class P2wshAddress extends SegwitAddress {
  /// Encapsulates a P2WSH address.
  P2wshAddress({super.script, super.address})
      : super(version: BitcoinOpCodeConst.P2WSH_ADDRESS_V0);

  /// Returns the scriptPubKey of a P2WPKH witness script
  @override
  Script toScriptPubKey() {
    return Script(script: ['OP_0', _program]);
  }

  /// Returns the type of address
  @override
  BitcoinAddressType get type => BitcoinAddressType.p2wsh;
}
