part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

abstract class SegwitAddress implements BitcoinBaseAddress {
  SegwitAddress.fromAddress(
      {required String address,
      required BasedUtxoNetwork network,
      required this.segwitVersion}) {
    if (!network.supportedAddress.contains(type)) {
      throw DartBitcoinPluginException(
          'network does not support ${type.value} address');
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
          'network does not support ${type.value} address');
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

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! SegwitAddress) return false;
    if (runtimeType != other.runtimeType) return false;
    if (type != other.type) return false;
    return addressProgram == addressProgram &&
        segwitVersion == other.segwitVersion;
  }

  @override
  int get hashCode =>
      HashCodeGenerator.generateHashCode([addressProgram, segwitVersion, type]);
}

class P2wpkhAddress extends SegwitAddress {
  P2wpkhAddress.fromAddress({required super.address, required super.network})
      : super.fromAddress(segwitVersion: _BitcoinAddressUtils.segwitV0);

  P2wpkhAddress.fromProgram({required super.program})
      : super.fromProgram(
            segwitVersion: _BitcoinAddressUtils.segwitV0,
            addresType: SegwitAddressType.p2wpkh);

  /// returns the scriptPubKey of a P2WPKH witness script
  @override
  Script toScriptPubKey() {
    return Script(script: [BitcoinOpcode.op0, addressProgram]);
  }

  /// returns the type of address
  @override
  SegwitAddressType get type => SegwitAddressType.p2wpkh;
}

class P2trAddress extends SegwitAddress {
  P2trAddress.fromAddress({required super.address, required super.network})
      : super.fromAddress(segwitVersion: _BitcoinAddressUtils.segwitV1);
  P2trAddress.fromProgram({required super.program})
      : super.fromProgram(
            segwitVersion: _BitcoinAddressUtils.segwitV1,
            addresType: SegwitAddressType.p2tr);
  P2trAddress.fromInternalKey({
    required List<int> internalKey,
    TaprootTree? treeScript,
    List<int>? merkleRoot,
  }) : super.fromProgram(
            program: BytesUtils.toHexString(TaprootUtils.tweakPublicKey(
                    internalKey,
                    treeScript: treeScript,
                    merkleRoot: merkleRoot)
                .toXonly()),
            segwitVersion: _BitcoinAddressUtils.segwitV1,
            addresType: SegwitAddressType.p2tr);

  /// returns the scriptPubKey of a P2TR witness script
  @override
  Script toScriptPubKey() {
    return Script(script: [BitcoinOpcode.op1, addressProgram]);
  }

  /// returns the type of address
  @override
  SegwitAddressType get type => SegwitAddressType.p2tr;
}

class P2wshAddress extends SegwitAddress {
  P2wshAddress.fromAddress({required super.address, required super.network})
      : super.fromAddress(segwitVersion: _BitcoinAddressUtils.segwitV0);
  P2wshAddress.fromProgram({required super.program})
      : super.fromProgram(
            segwitVersion: _BitcoinAddressUtils.segwitV0,
            addresType: SegwitAddressType.p2wsh);
  P2wshAddress.fromScript({required super.script})
      : super.fromScript(segwitVersion: _BitcoinAddressUtils.segwitV0);

  /// Returns the scriptPubKey of a P2WPKH witness script
  @override
  Script toScriptPubKey() {
    return Script(script: [BitcoinOpcode.op0, addressProgram]);
  }

  /// Returns the type of address
  @override
  SegwitAddressType get type => SegwitAddressType.p2wsh;
}
