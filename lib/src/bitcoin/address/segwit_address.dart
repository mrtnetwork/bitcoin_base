import 'package:bitcoin_base/src/bitcoin/address/core.dart';
import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:blockchain_utils/bech32/bech32.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

abstract class SegwitAddress implements BitcoinAddress {
  static int _segwitVersion(String version) {
    if (version == BitcoinOpCodeConst.P2WPKH_ADDRESS_V0 ||
        version == BitcoinOpCodeConst.P2WSH_ADDRESS_V0) {
      return 0;
    } else if (version == BitcoinOpCodeConst.P2TR_ADDRESS_V1) {
      return 1;
    } else {
      throw ArgumentError('A valid segwit version is required.');
    }
  }

  SegwitAddress.fromAddress(
      {required String address,
      BitcoinNetwork? network,
      this.version = BitcoinOpCodeConst.P2WPKH_ADDRESS_V0})
      : segwitNumVersion = _segwitVersion(version) {
    _program = _addressToHash(address, network: network);
  }
  SegwitAddress.fromProgram(
      {required String program,
      this.version = BitcoinOpCodeConst.P2WPKH_ADDRESS_V0})
      : segwitNumVersion = _segwitVersion(version),
        _program = program;
  SegwitAddress.fromScript(
      {required Script script,
      this.version = BitcoinOpCodeConst.P2WPKH_ADDRESS_V0})
      : segwitNumVersion = _segwitVersion(version),
        _program = _scriptToHash(script);

  late final String _program;

  String get getProgram => _program;

  final String version;
  late final int segwitNumVersion;

  String _addressToHash(String address, {BitcoinNetwork? network}) {
    final convert = SegwitBech32Decoder.decode(network?.p2wpkhHrp, address);

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

  static String _scriptToHash(Script script) {
    final toBytes = script.toBytes();
    final toHash = QuickCrypto.sha256Hash(toBytes);
    return BytesUtils.toHexString(toHash);
  }
}

class P2wpkhAddress extends SegwitAddress {
  P2wpkhAddress.fromAddress({required super.address, super.network})
      : super.fromAddress(version: BitcoinOpCodeConst.P2WPKH_ADDRESS_V0);

  P2wpkhAddress.fromProgram({required super.program})
      : super.fromProgram(version: BitcoinOpCodeConst.P2WPKH_ADDRESS_V0);
  P2wpkhAddress.fromScript({required super.script})
      : super.fromScript(version: BitcoinOpCodeConst.P2WPKH_ADDRESS_V0);

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
  P2trAddress.fromAddress({required super.address, super.network})
      : super.fromAddress(version: BitcoinOpCodeConst.P2TR_ADDRESS_V1);
  P2trAddress.fromProgram({required super.program})
      : super.fromProgram(version: BitcoinOpCodeConst.P2TR_ADDRESS_V1);
  P2trAddress.fromScript({required super.script})
      : super.fromScript(version: BitcoinOpCodeConst.P2TR_ADDRESS_V1);

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
  P2wshAddress.fromAddress({required super.address, super.network})
      : super.fromAddress(version: BitcoinOpCodeConst.P2WSH_ADDRESS_V0);
  P2wshAddress.fromProgram({required super.program})
      : super.fromProgram(version: BitcoinOpCodeConst.P2WSH_ADDRESS_V0);
  P2wshAddress.fromScript({required super.script})
      : super.fromScript(version: BitcoinOpCodeConst.P2WSH_ADDRESS_V0);

  /// Returns the scriptPubKey of a P2WPKH witness script
  @override
  Script toScriptPubKey() {
    return Script(script: ['OP_0', _program]);
  }

  /// Returns the type of address
  @override
  BitcoinAddressType get type => BitcoinAddressType.p2wsh;
}
