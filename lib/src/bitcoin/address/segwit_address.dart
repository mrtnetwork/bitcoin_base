part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

abstract class SegwitAddress implements BitcoinBaseAddress {
  SegwitAddress.fromAddress(
      {required String address,
      required BasedUtxoNetwork network,
      required this.segwitVersion}) {
    if (!network.supportedAddress.contains(type)) {
      throw DartBitcoinPluginException(
          "network does not support ${type.value} address");
    }
    addressProgram = _BitcoinAddressUtils.toSegwitProgramWithVersionAndNetwork(
        address: address, version: segwitVersion, network: network);
  }
  SegwitAddress.fromProgram(
      {required String program,
      required this.segwitVersion,
      required SegwitAddressType addresType})
      : addressProgram =
            _BitcoinAddressUtils.validateAddressProgram(program, addresType);
  SegwitAddress.fromScript(
      {required Script script, required this.segwitVersion})
      : addressProgram = _BitcoinAddressUtils.segwitScriptToSHA256(script);

  @override
  late final String addressProgram;

  final int segwitVersion;

  @override
  String toAddress(BasedUtxoNetwork network) {
    if (!network.supportedAddress.contains(type)) {
      throw DartBitcoinPluginException(
          "network does not support ${type.value} address");
    }
    return _BitcoinAddressUtils.segwitToAddress(
        addressProgram: addressProgram,
        network: network,
        segwitVersion: segwitVersion);
  }

  @override
  String pubKeyHash() {
    return _BitcoinAddressUtils.pubKeyHash(toScriptPubKey());
  }
}

class P2wpkhAddress extends SegwitAddress {
  P2wpkhAddress.fromAddress(
      {required String address, required BasedUtxoNetwork network})
      : super.fromAddress(
            segwitVersion: _BitcoinAddressUtils.segwitV0,
            address: address,
            network: network);

  P2wpkhAddress.fromProgram({required String program})
      : super.fromProgram(
            segwitVersion: _BitcoinAddressUtils.segwitV0,
            addresType: SegwitAddressType.p2wpkh,
            program: program);
  P2wpkhAddress.fromScript({required Script script})
      : super.fromScript(
            segwitVersion: _BitcoinAddressUtils.segwitV0, script: script);

  /// returns the scriptPubKey of a P2WPKH witness script
  @override
  Script toScriptPubKey() {
    return Script(script: ['OP_0', addressProgram]);
  }

  /// returns the type of address
  @override
  SegwitAddressType get type => SegwitAddressType.p2wpkh;
}

class P2trAddress extends SegwitAddress {
  P2trAddress.fromAddress(
      {required String address, required BasedUtxoNetwork network})
      : super.fromAddress(
            segwitVersion: _BitcoinAddressUtils.segwitV1,
            address: address,
            network: network);
  P2trAddress.fromProgram({required String program})
      : super.fromProgram(
            segwitVersion: _BitcoinAddressUtils.segwitV1,
            addresType: SegwitAddressType.p2tr,
            program: program);
  P2trAddress.fromScript({required Script script})
      : super.fromScript(
            segwitVersion: _BitcoinAddressUtils.segwitV1, script: script);

  /// returns the scriptPubKey of a P2TR witness script
  @override
  Script toScriptPubKey() {
    return Script(script: ['OP_1', addressProgram]);
  }

  /// returns the type of address
  @override
  SegwitAddressType get type => SegwitAddressType.p2tr;
}

class P2wshAddress extends SegwitAddress {
  P2wshAddress.fromAddress(
      {required String address, required BasedUtxoNetwork network})
      : super.fromAddress(
            segwitVersion: _BitcoinAddressUtils.segwitV0,
            address: address,
            network: network);
  P2wshAddress.fromProgram({required String program})
      : super.fromProgram(
            segwitVersion: _BitcoinAddressUtils.segwitV0,
            addresType: SegwitAddressType.p2wsh,
            program: program);
  P2wshAddress.fromScript({required Script script})
      : super.fromScript(
            segwitVersion: _BitcoinAddressUtils.segwitV0, script: script);

  /// Returns the scriptPubKey of a P2WPKH witness script
  @override
  Script toScriptPubKey() {
    return Script(script: ['OP_0', addressProgram]);
  }

  /// Returns the type of address
  @override
  SegwitAddressType get type => SegwitAddressType.p2wsh;
}
