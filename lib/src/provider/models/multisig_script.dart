import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/utils/btc_utils.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// MultiSignatureSigner is an interface that defines methods required for representing
/// signers in a multi-signature scheme. A multi-signature signer typically includes
/// information about their public key and weight within the scheme.
class MultiSignatureSigner {
  MultiSignatureSigner._(this.publicKey, this.weight, this.keyType);

  /// PublicKey returns the public key associated with the signer.
  final String publicKey;

  /// Weight returns the weight or significance of the signer within the multi-signature scheme.
  /// The weight is used to determine the number of signatures required for a valid transaction.
  final int weight;

  final PublicKeyType keyType;

  /// creates a new instance of a multi-signature signer with the
  /// specified public key and weight.
  factory MultiSignatureSigner(
      {required String publicKey, required int weight}) {
    final pubkeyMode = BtcUtils.determinatePubKeyModeHex(publicKey);

    return MultiSignatureSigner._(
        ECPublic.fromHex(publicKey).toHex(mode: pubkeyMode),
        weight,
        pubkeyMode);
  }
}

/// MultiSignatureAddress represents a multi-signature Bitcoin address configuration, including
/// information about the required signers, threshold, the address itself,
/// and the script details used for multi-signature transactions.
class MultiSignatureAddress {
  static const List<P2shAddressType> legacySupportP2shTypes = [
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkhInP2sh32,
    P2shAddressType.p2pkhInP2shwt,
    P2shAddressType.p2pkhInP2sh32wt
  ];
  final bool canSelectSegwit;

  /// Signers is a collection of signers participating in the multi-signature scheme.
  final List<MultiSignatureSigner> signers;

  /// Threshold is the minimum number of signatures required to spend the bitcoins associated
  /// with this address.
  final int threshold;

  // /// Address represents the Bitcoin address associated with this multi-signature configuration.
  // final BitcoinAddress address;

  /// ScriptDetails provides details about the multi-signature script used in transactions,
  /// including "OP_M", compressed public keys, "OP_N", and "OP_CHECKMULTISIG."
  final Script multiSigScript;

  BitcoinBaseAddress toP2wshAddress({required BasedUtxoNetwork network}) {
    if (network is! LitecoinNetwork && network is! BitcoinNetwork) {
      throw DartBitcoinPluginException(
          '${network.conf.coinName.name} Bitcoin forks that do not support Segwit. use toP2shAddress');
    }
    if (!canSelectSegwit) {
      throw const DartBitcoinPluginException(
          "One of the signer's accounts used an uncompressed public key.");
    }
    return P2wshAddress.fromScript(script: multiSigScript);
  }

  BitcoinBaseAddress toP2wshInP2shAddress({required BasedUtxoNetwork network}) {
    final p2wsh = toP2wshAddress(network: network);
    return P2shAddress.fromScript(
        script: p2wsh.toScriptPubKey(), type: P2shAddressType.p2wshInP2sh);
  }

  BitcoinBaseAddress toP2shAddress(
      [P2shAddressType addressType = P2shAddressType.p2pkhInP2sh]) {
    if (!legacySupportP2shTypes.contains(addressType)) {
      throw DartBitcoinPluginException(
          "invalid p2sh type please use one of them ${legacySupportP2shTypes.map((e) => "$e").join(", ")}");
    }

    if (addressType.hashLength == 32) {
      return P2shAddress.fromHash160(
          addrHash: BytesUtils.toHexString(
              QuickCrypto.sha256DoubleHash(multiSigScript.toBytes())),
          type: addressType);
    }
    return P2shAddress.fromScript(script: multiSigScript, type: addressType);
  }

  BitcoinBaseAddress fromType(
      {required BasedUtxoNetwork network,
      required BitcoinAddressType addressType}) {
    switch (addressType) {
      case SegwitAddressType.p2wsh:
        return toP2wshAddress(network: network);
      case P2shAddressType.p2wshInP2sh:
        return toP2wshInP2shAddress(network: network);
      case P2shAddressType.p2pkhInP2sh:
      case P2shAddressType.p2pkhInP2sh32:
      case P2shAddressType.p2pkhInP2shwt:
      case P2shAddressType.p2pkhInP2sh32wt:
        return toP2shAddress(addressType as P2shAddressType);
      default:
        throw const DartBitcoinPluginException(
            'invalid multisig address type. use of of them [BitcoinAddressType.p2wsh, BitcoinAddressType.p2wshInP2sh, BitcoinAddressType.p2pkhInP2sh]');
    }
  }

  MultiSignatureAddress._(
      {required this.signers,
      required this.threshold,
      required this.multiSigScript,
      required this.canSelectSegwit});

  /// CreateMultiSignatureAddress creates a new instance of a MultiSignatureAddress, representing
  /// a multi-signature Bitcoin address configuration. It allows you to specify the minimum number
  /// of required signatures (threshold), provide the collection of signers participating in the
  /// multi-signature scheme, and specify the address type.
  factory MultiSignatureAddress(
      {required int threshold, required List<MultiSignatureSigner> signers}) {
    final sumWeight =
        signers.fold<int>(0, (sum, signer) => sum + signer.weight);
    if (threshold > 16 || threshold < 1) {
      throw const DartBitcoinPluginException(
          'The threshold should be between 1 and 16');
    }
    if (sumWeight > 16) {
      throw const DartBitcoinPluginException(
          'The total weight of the owners should not exceed 16');
    }
    if (sumWeight < threshold) {
      throw const DartBitcoinPluginException(
          'The total weight of the signatories should reach the threshold');
    }
    final multiSigScript = <String>['OP_$threshold'];
    for (final signer in signers) {
      for (var w = 0; w < signer.weight; w++) {
        multiSigScript.add(signer.publicKey);
      }
    }
    multiSigScript.addAll(['OP_$sumWeight', 'OP_CHECKMULTISIG']);
    final script = Script(script: multiSigScript);
    return MultiSignatureAddress._(
        signers: signers,
        threshold: threshold,
        multiSigScript: script,
        canSelectSegwit: signers.every((e) => e.keyType.isCompressed));
  }
}

class P2trMultiSignatureSigner {
  P2trMultiSignatureSigner._(this.xOnly, this.weight);

  final String xOnly;

  /// Weight returns the weight or significance of the signer within the multi-signature scheme.
  /// The weight is used to determine the number of signatures required for a valid transaction.
  final int weight;

  factory P2trMultiSignatureSigner(
      {required String xOnly, required int weight}) {
    return P2trMultiSignatureSigner._(TaprootUtils.toXonlyHex(xOnly), weight);
  }
}

class P2trMultiSignatureAddress {
  /// Signers is a collection of signers participating in the multi-signature scheme.
  final List<P2trMultiSignatureSigner> signers;

  /// Threshold is the minimum number of signatures required to spend the bitcoins associated
  /// with this address.
  final int threshold;

  /// ScriptDetails provides details about the multi-signature script used in transactions,
  /// including "OP_M", compressed public keys, "OP_N", and "OP_CHECKMULTISIG."
  final Script multiSigScript;
  P2trMultiSignatureAddress._(
      {required List<P2trMultiSignatureSigner> signers,
      required this.threshold,
      required this.multiSigScript})
      : signers = signers.immutable;

  factory P2trMultiSignatureAddress(
      {required int threshold,
      required List<P2trMultiSignatureSigner> signers}) {
    final sumWeight =
        signers.fold<int>(0, (sum, signer) => sum + signer.weight);
    if (threshold > 15 || threshold < 1) {
      throw const DartBitcoinPluginException(
          'The threshold should be between 1 and 15');
    }
    if (sumWeight > 15) {
      throw const DartBitcoinPluginException(
          'The total weight of the owners should not exceed 15');
    }
    if (sumWeight < threshold) {
      throw const DartBitcoinPluginException(
          'The total weight of the signatories should reach the threshold');
    }
    final multiSigScript = <String>[];
    for (int i = 0; i < signers.length; i++) {
      final signer = signers[i];
      for (var w = 0; w < signer.weight; w++) {
        if (i == 0 && w == 0) {
          multiSigScript.add(signer.xOnly);
          multiSigScript.add(BitcoinOpcode.opCheckSig.name);
          continue;
        }
        multiSigScript.add(signer.xOnly);
        multiSigScript.add("OP_CHECKSIGADD");
      }
    }
    multiSigScript.addAll(['OP_$threshold', 'OP_NUMEQUAL']);
    final script = Script(script: multiSigScript);
    return P2trMultiSignatureAddress._(
        signers: signers, threshold: threshold, multiSigScript: script);
  }
}
