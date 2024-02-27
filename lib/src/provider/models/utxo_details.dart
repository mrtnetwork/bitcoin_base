import 'package:bitcoin_base/bitcoin_base.dart';

abstract class UTXO {
  BitcoinUtxo toUtxo(BitcoinAddressType addressType);
}

class UtxoAddressDetails {
  /// PublicKey is the public key associated with the UTXO owner.
  final String? _publicKey;

  /// Address is the Bitcoin address associated with the UTXO owner.
  final BitcoinBaseAddress address;

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

/// Abstract base class representing a generic Bitcoin output.
abstract class BitcoinBaseOutput {
  const BitcoinBaseOutput();

  /// Convert the output to a TxOutput, a generic representation of a transaction output.
  TxOutput get toOutput;
}

/// Abstract class representing a spendable Bitcoin output, extending BitcoinBaseOutput.
abstract class BitcoinSpendableBaseOutput implements BitcoinBaseOutput {
  /// The Bitcoin address associated with this output.
  abstract final BitcoinBaseAddress address;

  /// The value (amount) of the Bitcoin output.
  abstract final BigInt value;
}

/// BitcoinOutput represents details about a Bitcoin transaction output, including
/// the recipient address and the value of bitcoins sent to that address.
class BitcoinOutput implements BitcoinSpendableBaseOutput {
  /// Address is a Bitcoin address representing the recipient of the transaction output.
  @override
  final BitcoinBaseAddress address;

  /// Value is a pointer to a BigInt representing the amount of bitcoins sent to the recipient.
  @override
  final BigInt value;
  // final CashToken? token;
  BitcoinOutput({
    required this.address,
    required this.value,
  });

  @override
  TxOutput get toOutput =>
      TxOutput(amount: value, scriptPubKey: address.toScriptPubKey());
}

/// Represents a custom script-based Bitcoin output, implementing BitcoinBaseOutput.
class BitcoinScriptOutput implements BitcoinBaseOutput {
  /// The custom script associated with this output like "OP_RETURN ....".
  final Script script;

  /// The value (amount) of the Bitcoin output.
  final BigInt value;
  const BitcoinScriptOutput({
    required this.script,
    required this.value,
  });

  /// Convert the custom script output to a standard TxOutput.
  @override
  TxOutput get toOutput =>
      TxOutput(amount: value, scriptPubKey: script, cashToken: null);
}

/// BitcoinTokenOutput represents details about a Bitcoin cash transaction with cash token output, including
/// the recipient address, token and the value of bitcoins sent to that address.
class BitcoinTokenOutput implements BitcoinSpendableBaseOutput {
  /// Address is a Bitcoin address representing the recipient of the transaction output.
  @override
  final BitcoinBaseAddress address;
  @override
  final BigInt value;
  final CashToken token;
  final String? utxoHash;
  BitcoinTokenOutput({
    required this.address,
    required this.value,
    required this.token,
    this.utxoHash,
  });

  /// Convert the custom script output to a standard TxOutput.
  @override
  TxOutput get toOutput => TxOutput(
      amount: value, scriptPubKey: address.toScriptPubKey(), cashToken: token);
}

/// Represents a burnable output, specifically related to [BitcoinTokenOutput] for burning Cash Tokens.
/// It is essential to use [ForkedTransactionBuilder] to validate inputs and outputs before spending.
///
/// For burning NFT or FT tokens, include [BitcoinBurnableOutput] in the output list. If the input and output values
/// do not match, an exception will be thrown during validation.
class BitcoinBurnableOutput extends BitcoinBaseOutput {
  /// The hash of the UTXO associated with this burnable output (optional).
  final String? utxoHash;

  /// The Cash Token category ID  for the burnable output.
  final String categoryID;

  /// The value (amount) of the burnable output (optional only for token with hasAmount flags).
  final BigInt? value;

  BitcoinBurnableOutput({
    required this.categoryID,
    this.utxoHash,
    this.value,
  });

  @override
  TxOutput get toOutput => throw UnimplementedError();
}

/// BitcoinUtxo represents an unspent transaction output (UTXO) on the Bitcoin blockchain.
/// It includes details such as the transaction hash (TxHash), the amount of bitcoins (Value),
/// the output index (Vout), the script type (ScriptType), and the block height at which the UTXO
/// was confirmed (BlockHeight).
class BitcoinUtxo {
  final CashToken? token;

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
    this.token,
  });

  /// check if utxos is p2tr
  bool isP2tr() {
    return scriptType == SegwitAddresType.p2tr;
  }

  /// check if utxos is segwit
  bool isSegwit() {
    return scriptType.isSegwit || isP2shSegwit();
  }

  /// checl if utxos is p2sh neasted segwit
  bool isP2shSegwit() {
    return scriptType == P2shAddressType.p2wpkhInP2sh ||
        scriptType == P2shAddressType.p2wshInP2sh;
  }

  /// convert utxos to transaction input with specify sequence like ReplaceByeFee (4Bytes)
  TxInput toInput([List<int>? sequence]) {
    return TxInput(txId: txHash, txIndex: vout, sequance: sequence);
  }

  @override
  String toString() {
    return "txid: $txHash vout: $vout script: ${scriptType.value} value: $value blockHeight: $blockHeight";
  }
}

/// extenstion for calculation on list of utxos
extension Calculate on List<UtxoWithAddress> {
  /// sum of utxos network values
  BigInt sumOfUtxosValue() {
    BigInt sum = BigInt.zero;
    for (var utxo in this) {
      sum += utxo.utxo.value;
    }
    return sum;
  }

  /// sum of utxos cash token (FToken) amounts
  Map<String, BigInt> sumOfTokenUtxos() {
    final Map<String, BigInt> tokens = {};
    for (var utxo in this) {
      if (utxo.utxo.token == null) continue;
      final token = utxo.utxo.token!;
      if (!token.hasAmount) continue;
      if (tokens.containsKey(token.category)) {
        tokens[token.category] = tokens[token.category]! + token.amount;
      } else {
        tokens[token.category] = token.amount;
      }
    }
    return tokens;
  }

  /// check if utxos has satoshi for spending
  bool canSpend() {
    final value = sumOfUtxosValue();
    return value > BigInt.zero;
  }
}
