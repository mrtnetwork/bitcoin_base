import 'package:bitcoin_base/src/bitcoin/bitcoin.dart';
import 'package:bitcoin_base/src/cash_token/cash_token.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:bitcoin_base/src/serialization/identifier.dart';
import 'package:bitcoin_base/src/utils/btc_utils.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

abstract class UTXO {
  BitcoinUtxo toUtxo(BitcoinAddressType addressType);
  Map<String, dynamic> toJson();
}

class UtxoAddressDetails {
  /// PublicKey is the public key associated with the UTXO owner.
  final String? publicKey;

  /// Address is the Bitcoin address associated with the UTXO owner.
  final BitcoinBaseAddress address;

  /// MultiSigAddress is a pointer to a MultiSignaturAddress instance representing a multi-signature address
  /// associated with the UTXO owner. It may be null if the UTXO owner is not using a multi-signature scheme.
  final MultiSignatureAddress? _multiSigAddress;

  UtxoAddressDetails._({required String this.publicKey, required this.address})
    : _multiSigAddress = null;
  factory UtxoAddressDetails({
    required String publicKey,
    required BitcoinBaseAddress address,
  }) {
    ECPublic.fromHex(publicKey);
    return UtxoAddressDetails._(publicKey: publicKey, address: address);
  }

  UtxoAddressDetails.multiSigAddress({
    required MultiSignatureAddress multiSigAddress,
    required this.address,
  }) : publicKey = null,
       _multiSigAddress = multiSigAddress;

  UtxoAddressDetails.watchOnly(this.address)
    : publicKey = null,
      _multiSigAddress = null;
}

/// UtxoWithAddress represents an unspent transaction output (UTXO) along with its associated owner details.
/// It combines information about the UTXO itself (BitcoinUtxo) and the ownership details (UtxoAddressDetails).
class UtxoWithAddress {
  /// Utxo is a BitcoinUtxo instance representing the unspent transaction output.
  final BitcoinUtxo utxo;

  /// OwnerDetails is a UtxoAddressDetails instance containing information about the UTXO owner.
  final UtxoAddressDetails ownerDetails;

  const UtxoWithAddress._({
    required this.utxo,
    required this.ownerDetails,
    required this.keyType,
  });
  factory UtxoWithAddress({
    required BitcoinUtxo utxo,
    required UtxoAddressDetails ownerDetails,
  }) {
    return UtxoWithAddress._(
      utxo: utxo,
      ownerDetails: ownerDetails,
      keyType:
          ownerDetails.publicKey != null && !utxo.isSegwit
              ? BtcUtils.determinatePubKeyModeHex(ownerDetails.publicKey!)
              : PublicKeyType.compressed,
    );
  }

  ECPublic public() {
    if (isMultiSig()) {
      throw const DartBitcoinPluginException(
        'Cannot access public key in multi-signature address',
      );
    }
    if (ownerDetails.publicKey == null) {
      throw const DartBitcoinPluginException(
        'Cannot access public key in watch only address; use UtxoAddressDetails constractor instead `UtxoAddressDetails.watchOnly`',
      );
    }
    return ECPublic.fromHex(ownerDetails.publicKey!);
  }

  final PublicKeyType keyType;

  bool isMultiSig() {
    return ownerDetails._multiSigAddress != null;
  }

  MultiSignatureAddress get multiSigAddress =>
      isMultiSig()
          ? ownerDetails._multiSigAddress!
          : throw const DartBitcoinPluginException(
            'The address is not associated with a multi-signature setup',
          );
}

/// Abstract base class representing a generic Bitcoin output.
abstract class BitcoinBaseOutput {
  const BitcoinBaseOutput();

  /// Convert the output to a TxOutput, a generic representation of a transaction output.
  TxOutput get toOutput;

  BigInt get value;
}

abstract class BCHBaseOutput extends BitcoinOutput {
  BCHBaseOutput({required super.address, required super.value});
}

/// Abstract class representing a spendable Bitcoin output, extending BitcoinBaseOutput.
abstract class BitcoinSpendableBaseOutput implements BitcoinBaseOutput {
  /// The Bitcoin address associated with this output.
  abstract final BitcoinBaseAddress address;

  /// The value (amount) of the Bitcoin output.
  @override
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
  BitcoinOutput({required this.address, required this.value});

  @override
  TxOutput get toOutput =>
      TxOutput(amount: value, scriptPubKey: address.toScriptPubKey());
}

/// Represents a custom script-based Bitcoin output, implementing BitcoinBaseOutput.
class BitcoinScriptOutput implements BitcoinBaseOutput {
  /// The custom script associated with this output like "OP_RETURN ....".
  final Script script;

  /// The value (amount) of the Bitcoin output.
  @override
  final BigInt value;

  final CashToken? token;
  const BitcoinScriptOutput({
    required this.script,
    required this.value,
    this.token,
  });

  /// Convert the custom script output to a standard TxOutput.
  @override
  TxOutput get toOutput =>
      TxOutput(amount: value, scriptPubKey: script, cashToken: token);
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
    amount: value,
    scriptPubKey: address.toScriptPubKey(),
    cashToken: token,
  );
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
  @override
  final BigInt value;

  BitcoinBurnableOutput({
    required this.categoryID,
    this.utxoHash,
    BigInt? value,
  }) : value = value ?? BigInt.zero;

  @override
  TxOutput get toOutput =>
      throw DartBitcoinPluginException("Unsupported method.");
}

/// BitcoinUtxo represents an unspent transaction output (UTXO) on the Bitcoin blockchain.
/// It includes details such as the transaction hash (TxHash), the amount of bitcoins (Value),
/// the output index (Vout), the script type (ScriptType), and the block height at which the UTXO
/// was confirmed (BlockHeight).
class BitcoinUtxo with CborTagSerializable, PartialEquality {
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
  final int blockHeight;

  final bool? coinbase;

  BitcoinUtxo copyWith({
    CashToken? token,
    String? txHash,
    BigInt? value,
    int? vout,
    int? blockHeight,
    bool? coinbase,
    BitcoinAddressType? scriptType,
  }) {
    return BitcoinUtxo(
      txHash: txHash ?? this.txHash,
      value: value ?? this.value,
      vout: vout ?? this.vout,
      scriptType: scriptType ?? this.scriptType,
      blockHeight: blockHeight ?? this.blockHeight,
      coinbase: coinbase ?? this.coinbase,
      token: token ?? this.token,
    );
  }

  BitcoinUtxo._({
    required String txHash,
    required this.value,
    required this.vout,
    required this.scriptType,
    required this.blockHeight,
    this.token,
    required this.isP2tr,
    required this.isP2shSegwit,
    required this.isSegwit,
    required this.coinbase,
  }) : txHash = StringUtils.normalizeHex(txHash);
  factory BitcoinUtxo.deserialize({CborObject? object, List<int>? bytes}) {
    final CborListValue values = CborTagSerializable.decodeTaggedValue(
      cborObject: object,
      cborBytes: bytes,
      identifier: BitcoinSerializationIdentifiers.bitcoinUtxo,
    );
    return BitcoinUtxo(
      txHash: values.rawValueAt(0),
      value: values.rawValueAt(1),
      vout: values.rawValueAt(2),
      token: values.maybeObjectAt<CashToken, CborBytesValue>(3, (e) {
        final data = CashToken.deserialize(e.value);
        final token = data.$1;
        if (token == null) {
          throw DartBitcoinPluginException("Invalid cashtoken bytes.");
        }
        return token;
      }),
      scriptType: BitcoinAddressType.fromTag(values.rawValueAt(4)),
      blockHeight: values.rawValueAt(5),
      coinbase: values.rawValueAt(6),
    );
  }

  factory BitcoinUtxo.fromJson(Map<String, dynamic> json) {
    return BitcoinUtxo(
      txHash: json.valueAs("tx_hash"),
      value: json.valueAsBigInt("value"),
      vout: json.valueAs("vout"),
      scriptType: BitcoinAddressType.fromName(json.valueAs("script_type")),
      blockHeight: json.valueAs("block_height"),
      token: json.valueTo<CashToken?, Map<String, dynamic>>(
        key: "token",
        parse: CashToken.fromJson,
      ),
      coinbase: json.valueAs("coinbase"),
    );
  }
  factory BitcoinUtxo({
    required String txHash,
    required BigInt value,
    required int vout,
    required BitcoinAddressType scriptType,
    required int blockHeight,
    bool? coinbase,
    CashToken? token,
  }) {
    final isP2shSegwit =
        scriptType == P2shAddressType.p2wpkhInP2sh ||
        scriptType == P2shAddressType.p2wshInP2sh;
    return BitcoinUtxo._(
      txHash: txHash,
      value: value,
      blockHeight: blockHeight,
      token: token,
      vout: vout,
      scriptType: scriptType,
      coinbase: coinbase,
      isP2tr: scriptType == SegwitAddressType.p2tr,
      isP2shSegwit: isP2shSegwit,
      isSegwit: isP2shSegwit || scriptType.isSegwit,
    );
  }

  /// check if utxos is p2tr
  final bool isP2tr;

  /// check if utxos is segwit
  final bool isSegwit;

  /// check if utxos is p2sh neasted segwit
  final bool isP2shSegwit;

  /// convert utxos to transaction input with specify sequence like ReplaceByeFee (4Bytes)
  TxInput toInput([List<int>? sequence]) {
    return TxInput(txId: txHash, txIndex: vout, sequance: sequence);
  }

  @override
  List<CborObject?> get serializationItems => [
    txHash.toCbor(),
    value.toCbor(),
    vout.toCbor(),
    token?.toBytes().toCborBytes(),
    scriptType.id.toCbor(),
    blockHeight.toCbor(),
    coinbase?.toCbor(),
  ];

  Map<String, dynamic> toJson() {
    return {
      "token": token?.toJson(),
      "tx_hash": txHash,
      "value": value.toString(),
      "vout": vout,
      "script_type": scriptType.name,
      "block_height": blockHeight,
      "coinbase": coinbase,
    };
  }

  @override
  String toString() {
    return 'txid: $txHash vout: $vout script: ${scriptType.name} value: $value blockHeight: $blockHeight';
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      BitcoinSerializationIdentifiers.bitcoinUtxo;

  @override
  List<dynamic> get parts => [txHash, vout];

  bool confirmed() => blockHeight > 0;
}

/// extenstion for calculation on list of utxos
extension ExtUtxoCalculate on List<UtxoWithAddress> {
  /// sum of utxos network values
  BigInt sumOfUtxosValue() {
    var sum = BigInt.zero;
    for (final utxo in this) {
      sum += utxo.utxo.value;
    }
    return sum;
  }

  /// sum of utxos cash token (FToken) amounts
  Map<String, BigInt> sumOfTokenUtxos() {
    final tokens = <String, BigInt>{};
    for (final utxo in this) {
      final token = utxo.utxo.token;
      if (token == null || !token.hasAmount) continue;
      final amount = tokens[token.category] ?? BigInt.zero;
      tokens[token.category] = amount + token.amount;
    }
    return tokens;
  }

  /// check if utxos has satoshi for spending
  bool canSpend() {
    final value = sumOfUtxosValue();
    return value > BigInt.zero;
  }
}
