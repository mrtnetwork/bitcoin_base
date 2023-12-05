/// UtxoAddressDetails represents ownership details associated with a Bitcoin unspent transaction output (UTXO).
/// It includes information such as the public key, Bitcoin address, and multi-signature address (if applicable)
/// of the UTXO owner.
import 'package:bitcoin_base/bitcoin_base.dart';

class UtxoAddressDetails {
  /// PublicKey is the public key associated with the UTXO owner.
  final String? _publicKey;

  /// Address is the Bitcoin address associated with the UTXO owner.
  final BitcoinAddress address;

  /// MultiSigAddress is a pointer to a MultiSignaturAddress instance representing a multi-signature address
  /// associated with the UTXO owner. It may be null if the UTXO owner is not using a multi-signature scheme.
  final MultiSignatureAddress? _multiSigAddress;

  UtxoAddressDetails({
    required String publicKey,
    required this.address,
  })  : _multiSigAddress = null,
        _publicKey = publicKey;

  UtxoAddressDetails.multiSigAddress(
      {required MultiSignatureAddress multiSigAddress, required this.address})
      : _publicKey = null,
        _multiSigAddress = multiSigAddress;

  UtxoAddressDetails.watchOnly(this.address)
      : _publicKey = null,
        _multiSigAddress = null;
}

/// UtxoWithAddress represents an unspent transaction output (UTXO) along with its associated owner details.
/// It combines information about the UTXO itself (BitcoinUtxo) and the ownership details (UtxoAddressDetails).
class UtxoWithAddress {
  /// Utxo is a BitcoinUtxo instance representing the unspent transaction output.
  final BitcoinUtxo utxo;

  /// OwnerDetails is a UtxoAddressDetails instance containing information about the UTXO owner.
  final UtxoAddressDetails ownerDetails;

  UtxoWithAddress({
    required this.utxo,
    required this.ownerDetails,
  });

  ECPublic public() {
    if (isMultiSig()) {
      throw ArgumentError(
          "Cannot access public key in multi-signature address");
    }
    if (ownerDetails._publicKey == null) {
      throw ArgumentError(
          "Cannot access public key in watch only address; use UtxoAddressDetails constractor instead `UtxoAddressDetails.watchOnly`");
    }
    return ECPublic.fromHex(ownerDetails._publicKey!);
  }

  bool isMultiSig() {
    return ownerDetails._multiSigAddress != null;
  }

  MultiSignatureAddress get multiSigAddress => isMultiSig()
      ? ownerDetails._multiSigAddress!
      : throw ArgumentError(
          "The address is not associated with a multi-signature setup");
}

/// BitcoinOutput represents details about a Bitcoin transaction output, including
/// the recipient address and the value of bitcoins sent to that address.
class BitcoinOutput {
  /// Address is a Bitcoin address representing the recipient of the transaction output.
  final BitcoinAddress address;

  /// Value is a pointer to a BigInt representing the amount of bitcoins sent to the recipient.
  final BigInt value;

  BitcoinOutput({
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
  final BitcoinAddressType scriptType;

  /// BlockHeight represents the block height at which this UTXO was confirmed.
  final int? blockHeight;

  BitcoinUtxo({
    required this.txHash,
    required this.value,
    required this.vout,
    required this.scriptType,
    this.blockHeight,
  });

  bool isP2tr() {
    return scriptType == BitcoinAddressType.p2tr;
  }

  bool isSegwit() {
    return scriptType == BitcoinAddressType.p2wpkh ||
        scriptType == BitcoinAddressType.p2wsh ||
        scriptType == BitcoinAddressType.p2tr ||
        isP2shSegwit();
  }

  bool isP2shSegwit() {
    return scriptType == BitcoinAddressType.p2wpkhInP2sh ||
        scriptType == BitcoinAddressType.p2wshInP2sh;
  }

  @override
  String toString() {
    return "txid: $txHash vout: $vout script: ${scriptType.name} value: $value blockHeight: $blockHeight";
  }
}

extension Calculate on List<UtxoWithAddress> {
  BigInt sumOfUtxosValue() {
    BigInt sum = BigInt.zero;
    for (var utxo in this) {
      sum += utxo.utxo.value;
    }
    return sum;
  }

  bool canSpend() {
    final value = sumOfUtxosValue();
    return value > BigInt.zero;
  }
}
