import 'package:bitcoin_base/src/bitcoin/address/core.dart';
import 'package:bitcoin_base/src/bitcoin/address/validate.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:blockchain_utils/base58/base58.dart';
import 'package:blockchain_utils/bech32/bch_bech32.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/bip/ecc/keys/secp256k1_keys_ecdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

abstract class LegacyAddress implements BitcoinAddress {
  /// Represents a Bitcoin address
  ///
  /// [hash160] the hash160 string representation of the address; hash160 represents
  /// two consequtive hashes of the public key or the redeam script, first
  /// a SHA-256 and then an RIPEMD-160
  LegacyAddress.fromHash160(String addrHash) {
    if (!isValidHash160(addrHash)) {
      throw ArgumentError("Invalid value for parameter hash160.");
    }
    _h160 = addrHash;
  }
  LegacyAddress.fromAddress(
      {required String address, required BasedUtxoNetwork network}) {
    final decode = decodeLagacyAddress(address, type, network: network);
    if (decode == null) {
      throw ArgumentError("Invalid ${network.conf.coinName.name} address");
    }
    _h160 = BytesUtils.toHexString(decode);
  }
  LegacyAddress.fromScript({required Script script})
      : _h160 = _scriptToHash160(script);
  LegacyAddress._();

  late final String _h160;

  /// returns the address's hash160 hex string representation
  String get getH160 {
    if (type == BitcoinAddressType.p2pk) throw UnimplementedError();
    return _h160;
  }

  static String _scriptToHash160(Script s) {
    final b = s.toBytes();
    final h160 = QuickCrypto.hash160(b);
    return BytesUtils.toHexString(h160);
  }

  @override
  String toAddress(BasedUtxoNetwork network) {
    List<int> hashToBytes = BytesUtils.fromHexString(_h160);
    return _lagacyToAddress(network, hashToBytes);
  }

  String _lagacyToAddress(BasedUtxoNetwork network, List<int> scriptBytes) {
    if (network is BitcoinCashNetwork) {
      return _toBchAddress(network, scriptBytes);
    }
    switch (type) {
      case BitcoinAddressType.p2wpkhInP2sh:
      case BitcoinAddressType.p2wshInP2sh:
      case BitcoinAddressType.p2pkhInP2sh:
      case BitcoinAddressType.p2pkInP2sh:
        scriptBytes = [...network.p2shNetVer, ...scriptBytes];
        break;
      case const (BitcoinAddressType.p2pkh) || const (BitcoinAddressType.p2pk):
        scriptBytes = [...network.p2pkhNetVer, ...scriptBytes];
        break;
      default:
    }

    return Base58Encoder.checkEncode(scriptBytes);
  }

  String _toBchAddress(BasedUtxoNetwork network, List<int> scriptBytes) {
    String hrp;
    List<int> netVersion;
    if (type.isP2sh) {
      hrp = network.conf.params.p2shStdHrp!;
      netVersion = network.conf.params.p2shStdNetVer!;
    } else {
      hrp = network.conf.params.p2pkhStdHrp!;
      netVersion = network.conf.params.p2pkhStdNetVer!;
    }
    return BchBech32Encoder.encode(hrp, netVersion, scriptBytes);
  }

  void _validateP2shType() {
    final isValid = type == BitcoinAddressType.p2pkInP2sh ||
        type == BitcoinAddressType.p2pkhInP2sh ||
        type == BitcoinAddressType.p2wpkhInP2sh ||
        type == BitcoinAddressType.p2wshInP2sh;
    if (!isValid) {
      throw ArgumentError("invalid p2sh type");
    }
  }
}

class P2shAddress extends LegacyAddress {
  P2shAddress.fromScript(
      {required super.script, this.type = BitcoinAddressType.p2pkInP2sh})
      : super.fromScript() {
    _validateP2shType();
  }

  P2shAddress.fromAddress(
      {required super.address,
      required super.network,
      this.type = BitcoinAddressType.p2pkInP2sh})
      : super.fromAddress() {
    _validateP2shType();
  }
  P2shAddress.fromHash160(
      {required String addrHash, this.type = BitcoinAddressType.p2pkInP2sh})
      : super.fromHash160(addrHash) {
    _validateP2shType();
  }

  @override
  final BitcoinAddressType type;

  void _validateP2shSupport(BasedUtxoNetwork network) {
    if (network is BitcoinNetwork || network is LitecoinNetwork) return;
    if (type == BitcoinAddressType.p2wshInP2sh ||
        type == BitcoinAddressType.p2wpkhInP2sh) {
      throw ArgumentError("Bitcoin forks that do not support Segwit");
    }
  }

  @override
  String toAddress(BasedUtxoNetwork network) {
    _validateP2shSupport(network);
    return super.toAddress(network);
  }

  /// Returns the scriptPubKey (P2SH) that corresponds to this address
  @override
  Script toScriptPubKey() {
    return Script(script: ['OP_HASH160', _h160, 'OP_EQUAL']);
  }
}

class P2pkhAddress extends LegacyAddress {
  P2pkhAddress.fromScript({required super.script}) : super.fromScript();
  P2pkhAddress.fromAddress({required super.address, required super.network})
      : super.fromAddress();
  P2pkhAddress.fromHash160({required String addrHash})
      : super.fromHash160(addrHash);

  @override
  Script toScriptPubKey() {
    return Script(script: [
      'OP_DUP',
      'OP_HASH160',
      _h160,
      'OP_EQUALVERIFY',
      'OP_CHECKSIG'
    ]);
  }

  @override
  BitcoinAddressType get type => BitcoinAddressType.p2pkh;
}

class P2pkAddress extends LegacyAddress {
  P2pkAddress({required String publicKey}) : super._() {
    final toBytes = BytesUtils.fromHexString(publicKey);
    if (!Secp256k1PublicKeyEcdsa.isValidBytes(toBytes)) {
      throw ArgumentError("The public key is wrong");
    }
    publicHex = publicKey;
  }
  late final String publicHex;

  /// Returns the scriptPubKey (P2SH) that corresponds to this address
  @override
  Script toScriptPubKey() {
    return Script(script: [publicHex, 'OP_CHECKSIG']);
  }

  @override
  String toAddress(BasedUtxoNetwork network) {
    final bytes = BytesUtils.fromHexString(publicHex);
    List<int> ripemd160Hash = QuickCrypto.hash160(bytes);
    return _lagacyToAddress(network, ripemd160Hash);
  }

  @override
  BitcoinAddressType get type => BitcoinAddressType.p2pk;
}
