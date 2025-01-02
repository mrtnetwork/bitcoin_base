import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// A transaction builder specifically designed for the Bitcoin Cash (BCH) and Bitcoin SV (BSV) networks.
/// Implements [BasedBitcoinTransacationBuilder] interface for creating and validating transactions.
///
/// The [ForkedTransactionBuilder] constructs transactions with specified outputs, fees, and additional parameters
/// such as UTXOs, memo, enableRBF (Replace-By-Fee), and more.
///
/// Parameters:
/// - [outPuts]: List of Bitcoin outputs to be included in the transaction.
/// - [fee]: Transaction fee (BigInt) for processing the transaction.
/// - [network]: The target Bitcoin network (Bitcoin Cash or Bitcoin SV).
/// - [utxosInfo]: List of UtxoWithAddress objects providing information about Unspent Transaction Outputs (UTXOs).
/// - [memo]: Optional memo or additional information associated with the transaction.
/// - [enableRBF]: Flag indicating whether Replace-By-Fee (RBF) is enabled. Default is false.
/// - [isFakeTransaction]: Flag indicating whether the transaction is a fake/mock transaction. Default is false.
/// - [inputOrdering]: Ordering preference for transaction inputs. Default is BIP-69.
/// - [outputOrdering]: Ordering preference for transaction outputs. Default is BIP-69.
///
/// Note: The constructor automatically validates the builder by calling the [_validateBuilder] method.
class ForkedTransactionBuilder implements BasedBitcoinTransacationBuilder {
  final List<BitcoinBaseOutput> outPuts;
  final BigInt fee;
  final BasedUtxoNetwork network;
  final List<UtxoWithAddress> utxosInfo;
  final String? memo;
  final bool enableRBF;
  final bool isFakeTransaction;
  final BitcoinOrdering inputOrdering;
  final BitcoinOrdering outputOrdering;
  ForkedTransactionBuilder(
      {required this.outPuts,
      required this.fee,
      required this.network,
      required List<UtxoWithAddress> utxos,
      this.inputOrdering = BitcoinOrdering.bip69,
      this.outputOrdering = BitcoinOrdering.bip69,
      this.memo,
      this.enableRBF = false,
      this.isFakeTransaction = false})
      : utxosInfo = utxos {
    _validateBuilder();
  }

  void _validateBuilder() {
    if (network is! BitcoinCashNetwork && network is! BitcoinSVNetwork) {
      throw const DartBitcoinPluginException(
          'invalid network. use ForkedTransactionBuilder for BitcoinCashNetwork and BSVNetwork otherwise use BitcoinTransactionBuilder');
    }

    /// validate every address is related to network
    /// exception if failed.
    for (final i in utxosInfo) {
      i.ownerDetails.address.toAddress(network);
    }
    for (final i in outPuts) {
      if (i is BitcoinOutput) {
        i.address.toAddress(network);
      }
    }
  }

  /// This method is used to create a dummy transaction,
  /// allowing us to obtain the size of the original transaction
  /// before conducting the actual transaction. This helps us estimate the transaction cost
  static int estimateTransactionSize(
      {required List<UtxoWithAddress> utxos,
      required List<BitcoinBaseOutput> outputs,
      required BitcoinCashNetwork network,
      String? memo,
      bool enableRBF = false}) {
    final transactionBuilder = ForkedTransactionBuilder(

        /// Now, we provide the UTXOs we want to spend.
        utxos: utxos,

        /// We select transaction outputs
        outPuts: outputs,

        /// Transaction fee
        /// Ensure that you have accurately calculated the amounts.
        /// If the sum of the outputs, including the transaction fee,
        /// does not match the total amount of UTXOs,
        /// it will result in an error. Please double-check your calculations.
        fee: BigInt.from(10000000000000),

        /// network, testnet, mainnet
        network: network,

        /// If you like the note write something else and leave it blank
        memo: memo,

        /// RBF, or Replace-By-Fee, is a feature in Bitcoin that allows you to increase the fee of an unconfirmed
        /// transaction that you've broadcasted to the network.
        /// This feature is useful when you want to speed up a
        /// transaction that is taking longer than expected to get confirmed due to low transaction fees.
        enableRBF: true,

        /// We consider the transaction to be fake so that it doesn't check the amounts
        /// and doesn't generate errors when determining the transaction size.
        isFakeTransaction: true);

    /// 72 bytes (64 byte signature, 6-7 byte Der encoding length + sighash)
    const fakeECDSASignatureBytes =
        '010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101';

    final transaction = transactionBuilder
        .buildTransaction((trDigest, utxo, multiSigPublicKey, int sighash) {
      return fakeECDSASignatureBytes;
    });

    /// Now we need the size of the transaction.
    final size = transaction.getSize();

    return size;
  }

  /// It is used to make the appropriate scriptSig
  Script _buildInputScriptPubKeys(UtxoWithAddress utxo) {
    if (utxo.isMultiSig()) {
      final script = utxo.multiSigAddress.multiSigScript;
      switch (utxo.utxo.scriptType) {
        case P2shAddressType.p2pkhInP2sh:
        case P2shAddressType.p2pkhInP2shwt:
        case P2shAddressType.p2pkhInP2sh32:
        case P2shAddressType.p2pkhInP2sh32wt:
          return script;
        default:
          throw DartBitcoinPluginException(
              'unsuported multi-sig type ${utxo.utxo.scriptType} for ${network.conf.coinName.name}');
      }
    }

    final senderPub = utxo.public();
    switch (utxo.utxo.scriptType) {
      case PubKeyAddressType.p2pk:
      case P2shAddressType.p2pkInP2sh:
      case P2shAddressType.p2pkInP2shwt:
      case P2shAddressType.p2pkInP2sh32:
      case P2shAddressType.p2pkInP2sh32wt:
        return senderPub.toRedeemScript(mode: utxo.keyType);
      case P2pkhAddressType.p2pkh:
      case P2shAddressType.p2pkhInP2sh:
      case P2shAddressType.p2pkhInP2sh32:
      case P2pkhAddressType.p2pkhwt:
      case P2shAddressType.p2pkhInP2shwt:
      case P2shAddressType.p2pkhInP2sh32wt:
        return senderPub.toAddress(mode: utxo.keyType).toScriptPubKey();
      default:
        throw DartBitcoinPluginException(
            '${utxo.utxo.scriptType} does not sudpport on ${network.conf.coinName.name}');
    }
  }

  /// generateTransactionDigest generates and returns a transaction digest for a given input in the context of a Bitcoin
  /// transaction. The digest is used for signing the transaction input. The function takes into account whether the
  /// associated UTXO is Segregated Witness (SegWit) or Pay-to-Taproot (P2TR), and it computes the appropriate digest
  /// based on these conditions.
//
  /// Parameters:
  /// - scriptPubKeys: representing the scriptPubKey for the transaction output being spent.
  /// - input: An integer indicating the index of the input being processed within the transaction.
  /// - utox: A UtxoWithAddress instance representing the unspent transaction output (UTXO) associated with the input.
  /// - transaction: A BtcTransaction representing the Bitcoin transaction being constructed.
  /// - taprootAmounts: A List of BigInt containing taproot-specific amounts for P2TR inputs (ignored for non-P2TR inputs).
  /// - tapRootPubKeys: A List of of Script representing taproot public keys for P2TR inputs (ignored for non-P2TR inputs).
//
  /// Returns:
  /// - List<int>: representing the transaction digest to be used for signing the input.
  List<int> _generateTransactionDigest(
      {required Script scriptPubKeys,
      required int input,
      required UtxoWithAddress utox,
      required BtcTransaction transaction,
      int sighash =
          BitcoinOpCodeConst.SIGHASH_ALL | BitcoinOpCodeConst.SIGHASH_FORKED}) {
    return transaction.getTransactionSegwitDigit(
        txInIndex: input,
        script: scriptPubKeys,
        amount: utox.utxo.value,
        token: utox.utxo.token,
        sighash: sighash);
  }

  /// buildP2wshOrP2shScriptSig constructs and returns a script signature (represented as a List of strings)
  /// for a Pay-to-Witness-Script-Hash (P2WSH) or Pay-to-Script-Hash (P2SH) input. The function combines the
  /// signed transaction digest with the script details of the multi-signature address owned by the UTXO owner.
  //
  /// Parameters:
  /// - signedDigest: A List of strings containing the signed transaction digest elements.
  /// - utx: A UtxoWithAddress instance representing the unspent transaction output (UTXO) and its owner details.
  //
  /// Returns:
  /// - List<String>: A List of strings representing the script signature for the P2WSH or P2SH input.
  List<String> _buildMiltisigUnlockingScript(
      List<String> signedDigest, UtxoWithAddress utx) {
    /// The constructed script signature consists of the signed digest elements followed by
    /// the script details of the multi-signature address.
    return ['', ...signedDigest, utx.multiSigAddress.multiSigScript.toHex()];
  }

/*
Unlocking Script (scriptSig): The scriptSig is also referred to as
the unlocking script because it provides data and instructions to unlock
a specific output. It contains information and cryptographic signatures
that demonstrate the right to spend the bitcoins associated with the corresponding scriptPubKey output.
*/
  List<String> _buildUnlockingScript(String signedDigest, UtxoWithAddress utx) {
    final senderPub = utx.public();
    switch (utx.utxo.scriptType) {
      case PubKeyAddressType.p2pk:
        return [signedDigest];
      case P2pkhAddressType.p2pkh:
      case P2pkhAddressType.p2pkhwt:
        return [signedDigest, senderPub.toHex(mode: utx.keyType)];
      case P2shAddressType.p2pkhInP2sh:
      case P2shAddressType.p2pkhInP2shwt:
      case P2shAddressType.p2pkhInP2sh32:
      case P2shAddressType.p2pkhInP2sh32wt:
        final script = senderPub.toAddress(mode: utx.keyType).toScriptPubKey();
        return [
          signedDigest,
          senderPub.toHex(mode: utx.keyType),
          script.toHex()
        ];
      case P2shAddressType.p2pkInP2sh:
      case P2shAddressType.p2pkInP2shwt:
      case P2shAddressType.p2pkInP2sh32:
      case P2shAddressType.p2pkInP2sh32wt:
        final script = senderPub.toRedeemScript(mode: utx.keyType);
        return [signedDigest, script.toHex()];
      default:
        throw DartBitcoinPluginException(
            'Cannot send from this type of address ${utx.utxo.scriptType}');
    }
  }

  Tuple<List<TxInput>, List<UtxoWithAddress>> _buildInputs() {
    var sortedUtxos = List<UtxoWithAddress>.from(utxosInfo);

    if (inputOrdering == BitcoinOrdering.shuffle) {
      sortedUtxos = sortedUtxos..shuffle();
    } else if (inputOrdering == BitcoinOrdering.bip69) {
      sortedUtxos = sortedUtxos
        ..sort(
          (a, b) {
            final txidComparison = a.utxo.txHash.compareTo(b.utxo.txHash);
            if (txidComparison == 0) {
              return a.utxo.vout - b.utxo.vout;
            }
            return txidComparison;
          },
        );
    }
    final inputs = sortedUtxos.map((e) => e.utxo.toInput()).toList();
    if (enableRBF && inputs.isNotEmpty) {
      inputs[0] = inputs[0]
          .copyWith(sequence: BitcoinOpCodeConst.REPLACE_BY_FEE_SEQUENCE);
    }
    return Tuple(List<TxInput>.unmodifiable(inputs),
        List<UtxoWithAddress>.unmodifiable(sortedUtxos));
  }

  List<TxOutput> _buildOutputs() {
    var outputs = outPuts
        .where((element) => element is! BitcoinBurnableOutput)
        .map((e) => e.toOutput)
        .toList();

    if (memo != null) {
      outputs
          .add(TxOutput(amount: BigInt.zero, scriptPubKey: _opReturn(memo!)));
    }

    if (outputOrdering == BitcoinOrdering.shuffle) {
      outputs = outputs..shuffle();
    } else if (outputOrdering == BitcoinOrdering.bip69) {
      outputs = outputs
        ..sort(
          (a, b) {
            final valueComparison = a.amount.compareTo(b.amount);
            if (valueComparison == 0) {
              return BytesUtils.compareBytes(
                  a.scriptPubKey.toBytes(), b.scriptPubKey.toBytes());
            }
            return valueComparison;
          },
        );
    }
    return List<TxOutput>.unmodifiable(outputs);
  }

/*
The primary use case for OP_RETURN is data storage. You can embed various types of
data within the OP_RETURN output, such as text messages, document hashes, or metadata
related to a transaction. This data is permanently recorded on the blockchain and can
be retrieved by anyone who examines the blockchain's history.
*/
  Script _opReturn(String message) {
    final toHex = BytesUtils.toHexString(StringUtils.toBytes(message));
    return Script(script: ['OP_RETURN', toHex]);
  }

  /// Total amount to spend excluding fees
  BigInt _sumOutputAmounts(List<TxOutput> outputs) {
    var sum = BigInt.zero;
    for (final e in outputs) {
      sum += e.amount;
    }
    return sum;
  }

  /// Total token amount to spend.
  Map<String, BigInt> _sumTokenOutputAmounts(List<TxOutput> outputs) {
    final tokens = <String, BigInt>{};
    for (final utxo in outputs) {
      if (utxo.cashToken == null) continue;
      final token = utxo.cashToken!;
      if (!token.hasAmount) continue;
      if (tokens.containsKey(token.category)) {
        tokens[token.category] = tokens[token.category]! + token.amount;
      } else {
        tokens[token.category] = token.amount;
      }
    }
    return tokens;
  }

  void _validate(
      {required List<UtxoWithAddress> utxos,
      required List<TxOutput> outputs,
      required BigInt sumAmountsWithFee,
      required BigInt sumUtxoAmount,
      required BigInt sumOutputAmounts}) {
    if (isFakeTransaction) return;
    if (sumAmountsWithFee != sumUtxoAmount) {
      throw DartBitcoinPluginException('Sum value of utxo not spending',
          details: {
            'inputAmount': sumUtxoAmount,
            'fee': fee,
            'outputAmount': sumOutputAmounts
          });
    }

    /// sum of token amounts
    final sumOfTokenUtxos = utxos.sumOfTokenUtxos();

    /// sum of token output amounts
    final sumTokenOutputAmouts = _sumTokenOutputAmounts(outputs);
    for (final i in sumOfTokenUtxos.entries) {
      if (sumTokenOutputAmouts[i.key] != i.value) {
        var amount = sumTokenOutputAmouts[i.key] ?? BigInt.zero;
        amount += outPuts
            .whereType<BitcoinBurnableOutput>()
            .where((element) => element.categoryID == i.key)
            .fold(
                BigInt.zero,
                (previousValue, element) =>
                    previousValue + (element.value ?? BigInt.zero));

        if (amount != i.value) {
          throw DartBitcoinPluginException(
              'Sum token value of UTXOs not spending. use BitcoinBurnableOutput if you want to burn tokens.',
              details: {
                'token': i.key,
                'inputValue': i.value,
                'outputValue': amount
              });
        }
      }
    }
    for (final i in utxos) {
      final token = i.utxo.token;
      if (token != null && token.hasNFT) {
        if (token.hasAmount) continue;
        final hasOneoutput = outPuts.whereType<BitcoinTokenOutput>().any(
            (element) =>
                element.utxoHash == i.utxo.txHash &&
                element.token.category == token.category);
        if (hasOneoutput) continue;
        final hasBurnableOutput = outPuts
            .whereType<BitcoinBurnableOutput>()
            .any((element) =>
                element.utxoHash == i.utxo.txHash &&
                element.categoryID == token.category);
        if (hasBurnableOutput) continue;
        throw DartBitcoinPluginException(
            'Some NFTs in the inputs lack the corresponding spending in the outputs. If you intend to burn tokens, consider utilizing the BitcoinBurnableOutput.',
            details: {'category id': token.category});
      }
    }
  }

  @override
  Map<String, int> getSignatureCount() {
    final sortedInputs = _buildInputs();
    final inputs = sortedInputs.item1;
    final utxos = sortedInputs.item2;
    final count = <String, int>{};

    for (var i = 0; i < inputs.length; i++) {
      final indexUtxo = utxos[i];

      if (indexUtxo.isMultiSig()) {
        final multiSigAddress = indexUtxo.multiSigAddress;
        var sumMultiSigWeight = 0;
        final mutlsiSigSignatures = <String>[];
        for (var ownerIndex = 0;
            ownerIndex < multiSigAddress.signers.length;
            ownerIndex++) {
          for (var weight = 0;
              weight < multiSigAddress.signers[ownerIndex].weight;
              weight++) {
            if (mutlsiSigSignatures.length >= multiSigAddress.threshold) {
              break;
            }
            mutlsiSigSignatures.add('');
            count[multiSigAddress.signers[ownerIndex].publicKey] =
                (count[multiSigAddress.signers[ownerIndex].publicKey] ?? 0) + 1;
          }
          sumMultiSigWeight += multiSigAddress.signers[ownerIndex].weight;
          if (sumMultiSigWeight >= multiSigAddress.threshold) {
            break;
          }
        }
        if (sumMultiSigWeight < multiSigAddress.threshold) {
          throw const DartBitcoinPluginException(
              'some multisig signature does not exist');
        }
        continue;
      }
      final pubkey = indexUtxo.public().toHex();
      count[pubkey] = (count[pubkey] ?? 0) + 1;
    }
    return count;
  }

  @override
  BtcTransaction buildTransaction(BitcoinSignerCallBack sign) {
    /// build inputs
    final sortedInputs = _buildInputs();

    final inputs = sortedInputs.item1;

    final utxos = sortedInputs.item2;

    /// build outout
    final outputs = _buildOutputs();

    /// sum of amounts you filled in outputs
    final sumOutputAmounts = _sumOutputAmounts(outputs);

    /// sum of UTXOS amount
    final sumUtxoAmount = utxos.sumOfUtxosValue();

    /// sum of outputs amount + transcation fee
    final sumAmountsWithFee = (sumOutputAmounts + fee);

    _validate(
        utxos: utxos,
        outputs: outputs,
        sumAmountsWithFee: sumAmountsWithFee,
        sumUtxoAmount: sumUtxoAmount,
        sumOutputAmounts: sumOutputAmounts);

    /// create new transaction with inputs and outputs and isSegwit transaction or not
    // BtcTransaction transaction = BtcTransaction.fromRaw(
    //     "0200000001b8249c5a6cf8f24815377222e4c2bab32154151c367111134ef7ce11c651e4c600000000fd5b0300483045022100b4e774511598efbdf256aaa127f2104c5f25e29311936a75034857901c72fa180220232410ec31b9809b0293a7a2c8c0ade53ca4bdde064ac1baaa27d545678891b84147304402203014d1beaa73fc289d0201bff61a40d1e853103d624fb8520cc6b4afea00d3c10220643eed02e2830b7f751b7355a889e4ab4c02d01df0ca71621d4f5affe5cb3a5d41483045022100bf73bd48dcef332924c7578ff7a5b9d3817ecdb2ad2a4148f56069705365427c022044ce67ca87c3e1309ba43fcb3c23a3618ba0dbd44a802c22efab78b42b9a8e3e41483045022100a3d90b8f959850f9e2655b38e61a8e5323a363803bd62ab0560509e9cd675dae022064ba98f689c21f66e0839660bf15c7a0c44e0e65384d82996a4f3b73a55daef141473044022033128a7572b0bc7d22c6cd2080a882b7e03b15167b1d88b6405fa0131ab6254602207d960421e8a1a2e85431b6398a9af742fb492c967c3acac9fd38d82d7c54756e41483045022100c00232655b098d529deea53dcfffa5b25dc4a2015a52b1b587ae73c813a8d4a502201d100762ddb4779d1c484790a1b38cf369f634ee33541d8ec0ec45c2470141ba4147304402201503e2e7bab40cd5a083c0e03506ad1c260d17b821a142be2591e05fa5bdc86d02201d0280a2fc78a2af4bf7f1245bd8bf3384ada22098ba84645958ff1715655630414730440220090757399dc9f989ff1a7d998af385cd9490fe07c2c216b54967d4138067312a02204c3bb010902d72e90a1133cc8ae34cb629e139863f62ab259f25e5cac2125779414d13015821030f0fb9a244ad31a369ee02b7abfbbb0bfa3812b9a39ed93346d03d67d412d17721022f1b310f4c065331bc0d79ba4661bb9822d67d7c4a1b0a1892e1fd0cd23aa68d210299c2aa85d2b21a62f396907a802a58e521dafd5bddaccbd72786eea189bc4dc921021a7a569e91dbf60581509c7fc946d1003b60c7dee85299538db6353538d595742103a92c9b7cac68758de5783ed8e5123598e4ad137091e42987d3bad8a08e35bf3d21034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa21036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f721031d16453b3ab3132acb0a5bc16cc49690d819a585267a15cd5a064e2a0ad4059958ae0000000001f0780f000000000017a914e5d65da9624e4754827edb627fe31d4c75954a388700000000");
    // transaction = transaction.copyWith(inputs: inputs);
    final transaction =
        BtcTransaction(inputs: inputs, outputs: outputs, hasSegwit: false);
    const sighash =
        BitcoinOpCodeConst.SIGHASH_ALL | BitcoinOpCodeConst.SIGHASH_FORKED;

    /// Well, now let's do what we want for each input
    for (var i = 0; i < inputs.length; i++) {
      final indexUtxo = utxos[i];

      /// We receive the owner's ScriptPubKey
      final script = _buildInputScriptPubKeys(indexUtxo);

      /// We generate transaction digest for current input
      final digest = _generateTransactionDigest(
          scriptPubKeys: script,
          input: i,
          utox: indexUtxo,
          transaction: transaction,
          sighash: sighash);

      /// handle multisig address
      if (indexUtxo.isMultiSig()) {
        final multiSigAddress = indexUtxo.multiSigAddress;
        var sumMultiSigWeight = 0;
        final mutlsiSigSignatures = <String>[];
        for (var ownerIndex = 0;
            ownerIndex < multiSigAddress.signers.length;
            ownerIndex++) {
          /// now we need sign the transaction digest
          final sig = sign(digest, indexUtxo,
              multiSigAddress.signers[ownerIndex].publicKey, sighash);
          if (sig.isEmpty) continue;
          for (var weight = 0;
              weight < multiSigAddress.signers[ownerIndex].weight;
              weight++) {
            if (mutlsiSigSignatures.length >= multiSigAddress.threshold) {
              break;
            }
            mutlsiSigSignatures.add(sig);
          }
          sumMultiSigWeight += multiSigAddress.signers[ownerIndex].weight;
          if (sumMultiSigWeight >= multiSigAddress.threshold) {
            break;
          }
        }
        if (sumMultiSigWeight < multiSigAddress.threshold) {
          throw const DartBitcoinPluginException(
              'some multisig signature does not exist');
        }

        _addScripts(
            input: inputs[i], signatures: mutlsiSigSignatures, utxo: indexUtxo);
        continue;
      }

      /// now we need sign the transaction digest
      final sig =
          sign(digest, indexUtxo, indexUtxo.ownerDetails.publicKey!, sighash);
      _addScripts(input: inputs[i], signatures: [sig], utxo: indexUtxo);
    }
    final ea = BtcTransaction.fromRaw(transaction.serialize());
    assert(ea.serialize() == transaction.serialize(), transaction.serialize());
    return transaction;
  }

  @override
  Future<BtcTransaction> buildTransactionAsync(
      BitcoinSignerCallBackAsync sign) async {
    /// build inputs
    final sortedInputs = _buildInputs();

    final inputs = sortedInputs.item1;

    final utxos = sortedInputs.item2;

    /// build outout
    final outputs = _buildOutputs();

    /// sum of amounts you filled in outputs
    final sumOutputAmounts = _sumOutputAmounts(outputs);

    /// sum of UTXOS amount
    final sumUtxoAmount = utxos.sumOfUtxosValue();

    /// sum of outputs amount + transcation fee
    final sumAmountsWithFee = (sumOutputAmounts + fee);

    _validate(
        utxos: utxos,
        outputs: outputs,
        sumAmountsWithFee: sumAmountsWithFee,
        sumUtxoAmount: sumUtxoAmount,
        sumOutputAmounts: sumOutputAmounts);

    /// create new transaction with inputs and outputs and isSegwit transaction or not
    final transaction =
        BtcTransaction(inputs: inputs, outputs: outputs, hasSegwit: false);

    const sighash =
        BitcoinOpCodeConst.SIGHASH_ALL | BitcoinOpCodeConst.SIGHASH_FORKED;

    /// Well, now let's do what we want for each input
    for (var i = 0; i < inputs.length; i++) {
      final indexUtxo = utxos[i];

      /// We receive the owner's ScriptPubKey
      final script = _buildInputScriptPubKeys(indexUtxo);

      /// We generate transaction digest for current input
      final digest = _generateTransactionDigest(
          scriptPubKeys: script,
          input: i,
          utox: indexUtxo,
          transaction: transaction,
          sighash: sighash);

      /// handle multisig address
      if (indexUtxo.isMultiSig()) {
        final multiSigAddress = indexUtxo.multiSigAddress;
        var sumMultiSigWeight = 0;
        final mutlsiSigSignatures = <String>[];
        for (var ownerIndex = 0;
            ownerIndex < multiSigAddress.signers.length;
            ownerIndex++) {
          /// now we need sign the transaction digest
          final sig = await sign(digest, indexUtxo,
              multiSigAddress.signers[ownerIndex].publicKey, sighash);

          if (sig.isEmpty) continue;
          for (var weight = 0;
              weight < multiSigAddress.signers[ownerIndex].weight;
              weight++) {
            if (mutlsiSigSignatures.length >= multiSigAddress.threshold) {
              break;
            }
            mutlsiSigSignatures.add(sig);
          }

          sumMultiSigWeight += multiSigAddress.signers[ownerIndex].weight;
          if (sumMultiSigWeight >= multiSigAddress.threshold) {
            break;
          }
        }
        if (sumMultiSigWeight < multiSigAddress.threshold) {
          throw const DartBitcoinPluginException(
              'some multisig signature does not exist');
        }

        _addScripts(
            input: inputs[i], signatures: mutlsiSigSignatures, utxo: indexUtxo);
        continue;
      }

      /// now we need sign the transaction digest
      final sig = await sign(
          digest, indexUtxo, indexUtxo.ownerDetails.publicKey!, sighash);
      _addScripts(input: inputs[i], signatures: [sig], utxo: indexUtxo);
    }
    return transaction;
  }

  void _addScripts(
      {required UtxoWithAddress utxo,
      required TxInput input,
      required List<String> signatures}) {
    /// ok we signed, now we need unlocking script for this input
    final scriptSig = utxo.isMultiSig()
        ? _buildMiltisigUnlockingScript(signatures, utxo)
        : _buildUnlockingScript(signatures.first, utxo);
    input.scriptSig = Script(script: scriptSig);
  }
}
