import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/crypto/keypair/ec_public.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// Spending information for an address, including the scripts required to
/// spend P2SH / P2WSH / Taproot outputs.
///
class BitcoinSpenderAddress {
  final BitcoinNetworkAddress address;
  final Script? p2shRedeemScript;
  final Script? witnessScript;
  final List<int>? taprootInternal;
  BitcoinSpenderAddress._({
    required this.address,
    required this.p2shRedeemScript,
    required this.witnessScript,
    required List<int>? taprootInternal,
  }) : taprootInternal = taprootInternal?.asImmutableBytes;
  factory BitcoinSpenderAddress({
    required BitcoinNetworkAddress address,
    Script? p2shRedeemScript,
    Script? witnessScript,
    List<int>? taprootInternal,
  }) {
    BitcoinBaseAddress currentAddress = address.baseAddress;
    final type = address.type;
    bool isP2shSegwit = type.isP2sh && witnessScript != null;
    bool isWitness = type == SegwitAddressType.p2wsh;
    final addressScript = address.baseAddress.toScriptPubKey();
    if (type.isP2sh) {
      if (p2shRedeemScript == null) {
        throw BuError(
          DefaultErrorType.invalidArgument,
          "Missing p2sh redeem script.",
        );
      }
      P2shAddress p2shAddress;
      if (witnessScript != null) {
        final addr = P2wshAddress.fromScript(script: witnessScript);
        p2shAddress = P2shAddress.fromScript(
          script: addr.toScriptPubKey(),
          type: P2shAddressType.p2wshInP2sh,
        );
        if (p2shAddress.toScriptPubKey() != currentAddress.toScriptPubKey()) {
          throw BuError(
            DefaultErrorType.invalidArgument,
            "Invalid p2sh redeem script.",
          );
        }
      } else {
        if (BitcoinScriptUtils.isP2wsh(p2shRedeemScript)) {
          throw BuError(
            DefaultErrorType.invalidAddress,
            "Missing nested segwit p2sh witness script.",
          );
        }
        bool isP2wpkh = BitcoinScriptUtils.isP2wpkh(p2shRedeemScript);
        p2shAddress = P2shAddress.fromScript(
          script: p2shRedeemScript,
          type:
              isP2wpkh
                  ? P2shAddressType.p2wpkhInP2sh
                  : P2shAddressType.p2pkInP2sh,
        );
      }
      if (addressScript != p2shAddress.toScriptPubKey()) {
        throw BuError(
          DefaultErrorType.invalidArgument,
          "Invalid p2sh or witness script.",
        );
      }
      currentAddress = p2shAddress;
    } else if (isWitness) {
      if (witnessScript == null) {
        throw BuError(
          DefaultErrorType.invalidArgument,
          "Missing p2wsh witness script.",
        );
      }
      final addr = P2wshAddress.fromScript(script: witnessScript);
      if (addr.toScriptPubKey() != addressScript) {
        throw BuError(
          DefaultErrorType.invalidArgument,
          "Invalid p2wsh witness script.",
        );
      }
    } else if (type.isP2tr) {
      if (taprootInternal == null) {
        throw BuError(
          DefaultErrorType.badPublicKey,
          "Missing taproot internal key.",
        );
      }
      if (taprootInternal.length != EcdsaKeysConst.pointCoordByteLen) {
        taprootInternal = ECPublic.fromBytes(taprootInternal).toXOnly();
      }
      final addr = P2trAddress.fromInternalKey(internalKey: taprootInternal);
      if (addr.toScriptPubKey() != addressScript) {
        throw BuError(
          DefaultErrorType.badPublicKey,
          "Invalid taproot internal key.",
        );
      }
    }
    return BitcoinSpenderAddress._(
      address: BitcoinNetworkAddress.fromBaseAddress(
        address: currentAddress,
        network: address.network,
      ),
      p2shRedeemScript: type.isP2sh ? p2shRedeemScript : null,
      witnessScript:
          type.isP2sh || isP2shSegwit || isWitness ? witnessScript : null,
      taprootInternal: type.isP2tr ? taprootInternal : null,
    );
  }
}
