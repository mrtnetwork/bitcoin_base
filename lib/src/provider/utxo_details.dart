/// UtxoOwnerDetails represents ownership details associated with a Bitcoin unspent transaction output (UTXO).
/// It includes information such as the public key, Bitcoin address, and multi-signature address (if applicable)
/// of the UTXO owner.
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/bitcoin/address/core.dart';

import 'multisig_script.dart';

class UtxoOwnerDetails {
  /// PublicKey is the public key associated with the UTXO owner.
  final String? publicKey;

  /// Address is the Bitcoin address associated with the UTXO owner.
  final BitcoinAddress address;

  /// MultiSigAddress is a pointer to a MultiSignaturAddress instance representing a multi-signature address
  /// associated with the UTXO owner. It may be null if the UTXO owner is not using a multi-signature scheme.
  final MultiSignatureAddress? multiSigAddress;

  UtxoOwnerDetails({
    this.publicKey,
    required this.address,
    this.multiSigAddress,
  }) : assert(publicKey != null || multiSigAddress != null,
            "use publicKey for normal transaction and multiSigAddress for multi-sig address");
}

/// UtxoWithOwner represents an unspent transaction output (UTXO) along with its associated owner details.
/// It combines information about the UTXO itself (BitcoinUtxo) and the ownership details (UtxoOwnerDetails).
class UtxoWithOwner {
  /// Utxo is a BitcoinUtxo instance representing the unspent transaction output.
  final BitcoinUtxo utxo;

  /// OwnerDetails is a UtxoOwnerDetails instance containing information about the UTXO owner.
  final UtxoOwnerDetails ownerDetails;

  UtxoWithOwner({
    required this.utxo,
    required this.ownerDetails,
  });

  ECPublic public() {
    if (isMultiSig()) {
      throw ArgumentError(
          "Cannot access public key in multi-signature address; use owner's public keys");
    }
    return ECPublic.fromHex(ownerDetails.publicKey!);
  }

  bool isMultiSig() {
    return ownerDetails.multiSigAddress != null;
  }
}

/// BitcoinOutputDetails represents details about a Bitcoin transaction output, including
/// the recipient address and the value of bitcoins sent to that address.
class BitcoinOutputDetails {
  /// Address is a Bitcoin address representing the recipient of the transaction output.
  final BitcoinAddress address;

  /// Value is a pointer to a BigInt representing the amount of bitcoins sent to the recipient.
  final BigInt value;

  BitcoinOutputDetails({
    required this.address,
    required this.value,
  });
}

/// BitcoinUtxo represents an unspent transaction output (UTXO) on the Bitcoin blockchain.
/// It includes details such as the transaction hash (TxHash), the amount of bitcoins (Value),
/// the output index (Vout), the script type (ScriptType), and the block height at which the UTXO
/// was confirmed (BlockHeight).
class BitcoinUtxo {
  /// TxHash is the unique identifier of the transaction containing this UTXO.
  final String txHash;

  /// Value is a pointer to a BigInt representing the amount of bitcoins associated with this UTXO.
  final BigInt value;

  /// Vout is the output index within the transaction that corresponds to this UTXO.
  final int vout;

  /// ScriptType specifies the type of Bitcoin script associated with this UTXO.
  final AddressType scriptType;

  /// BlockHeight represents the block height at which this UTXO was confirmed.
  final int blockHeight;

  BitcoinUtxo({
    required this.txHash,
    required this.value,
    required this.vout,
    required this.scriptType,
    required this.blockHeight,
  });

  bool isP2tr() {
    return scriptType == AddressType.p2tr;
  }

  bool isSegwit() {
    return scriptType == AddressType.p2wpkh ||
        scriptType == AddressType.p2wsh ||
        scriptType == AddressType.p2tr ||
        isP2shSegwit();
  }

  bool isP2shSegwit() {
    return scriptType == AddressType.p2wpkhInP2sh ||
        scriptType == AddressType.p2wshInP2sh;
  }
}

extension Calculate on List<UtxoWithOwner> {
  BigInt sumOfUtxosValue() {
    BigInt sum = BigInt.zero;
    for (var utxo in this) {
      sum += utxo.utxo.value;
    }
    return sum;
  }

  bool canSpend() {
    final value = sumOfUtxosValue();
    return value.compareTo(BigInt.zero) != 0;
  }
}
