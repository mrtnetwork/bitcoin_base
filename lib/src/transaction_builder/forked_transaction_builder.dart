import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/provider/models/multisig_script.dart';
import 'package:bitcoin_base/src/provider/models/utxo_details.dart';
import 'package:bitcoin_base/src/transaction_builder/builder.dart';
import 'package:bitcoin_base/src/transaction_builder/btc_multisig_utils.dart';
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
/// - [memo]: Optional memo or additional information associated with the transaction.
/// - [enableRBF]: Flag indicating whether Replace-By-Fee (RBF) is enabled. Default is false.
/// - [isFakeTransaction]: Flag indicating whether the transaction is a fake/mock transaction. Default is false.
/// - [inputOrdering]: Ordering preference for transaction inputs. Default is BIP-69.
/// - [outputOrdering]: Ordering preference for transaction outputs. Default is BIP-69.
///
/// Note: The constructor automatically validates the builder by calling the [_validateBuilder] method.
class ForkedTransactionBuilder extends BasedBitcoinTransacationBuilder {
  final String? memo;
  final bool enableRBF;
  final bool isFakeTransaction;
  final BuBytes locktime;

  ForkedTransactionBuilder({
    required super.outPuts,
    required super.fee,
    required super.network,
    required super.utxos,
    super.inputOrdering = BitcoinOrdering.bip69,
    super.outputOrdering = BitcoinOrdering.bip69,
    this.memo,
    this.enableRBF = false,
    this.isFakeTransaction = false,
    List<int> locktime = BitcoinOpCodeConst.defaultTxLocktime,
  }) : locktime = locktime.asImmutableBytes {
    _validateBuilder();
  }

  void _validateBuilder() {
    switch (network) {
      case BitcoinCashNetwork _:
      case BitcoinSVNetwork _:
        break;
      default:
        throw BuError(
          DefaultErrorType.invalidArgument,
          'invalid network. use ForkedTransactionBuilder for BitcoinCashNetwork and BSVNetwork otherwise use BitcoinTransactionBuilder',
          details: {"network": network.name},
        );
    }

    /// validate every address is related to network
    /// exception if failed.
    for (final i in utxos) {
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
  static int estimateTransactionSize({
    required List<UtxoWithAddress> utxos,
    required List<BitcoinBaseOutput> outputs,
    required BasedUtxoNetwork network,
    String? memo,
    bool enableRBF = false,
  }) {
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
      enableRBF: enableRBF,

      /// We consider the transaction to be fake so that it doesn't check the amounts
      /// and doesn't generate errors when determining the transaction size.
      isFakeTransaction: true,
    );

    /// 72 bytes (64 byte signature, 6-7 byte Der encoding length + sighash)
    const fakeECDSASignatureBytes =
        '010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101';

    final transaction = transactionBuilder.buildTransaction((
      trDigest,
      utxo,
      multiSigPublicKey,
      int sighash,
    ) {
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
          throw BuError(
            DefaultErrorType.unsupported,
            'unsuported multi-sig type ${utxo.utxo.scriptType} for ${network.conf.coinName.name}',
          );
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
        throw BuError(
          DefaultErrorType.unsupported,
          '${utxo.utxo.scriptType} does not sudpport on ${network.conf.coinName.name}',
        );
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
  /// - `BuBytes`: representing the transaction digest to be used for signing the input.
  BuBytes _generateTransactionDigest({
    required Script scriptPubKeys,
    required int input,
    required UtxoWithAddress utox,
    required BtcTransaction transaction,
    int sighash =
        BitcoinOpCodeConst.sighashAll | BitcoinOpCodeConst.sighashForked,
  }) {
    return transaction
        .getTransactionSegwitDigit(
          txInIndex: input,
          script: scriptPubKeys,
          amount: utox.utxo.value,
          token: utox.utxo.token,
          sighash: sighash,
        )
        .asImmutableBytes;
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
  /// - `List<String>`: A List of strings representing the script signature for the P2WSH or P2SH input.
  List<String> _buildMiltisigUnlockingScript(
    List<String> signedDigest,
    UtxoWithAddress utx,
  ) {
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
          script.toHex(),
        ];
      case P2shAddressType.p2pkInP2sh:
      case P2shAddressType.p2pkInP2shwt:
      case P2shAddressType.p2pkInP2sh32:
      case P2shAddressType.p2pkInP2sh32wt:
        final script = senderPub.toRedeemScript(mode: utx.keyType);
        return [signedDigest, script.toHex()];
      default:
        throw BuError(
          DefaultErrorType.unsupported,
          'Cannot send from this type of address ${utx.utxo.scriptType}',
        );
    }
  }

  (List<TxInput>, List<UtxoWithAddress>) _buildInputs() {
    final sortedUtxos = List<UtxoWithAddress>.from(utxos);

    if (inputOrdering == BitcoinOrdering.shuffle) {
      sortedUtxos.shuffle();
    } else if (inputOrdering == BitcoinOrdering.bip69) {
      sortedUtxos.sort((a, b) {
        final txidComparison = a.utxo.txHash.compareTo(b.utxo.txHash);
        if (txidComparison == 0) {
          return a.utxo.vout - b.utxo.vout;
        }
        return txidComparison;
      });
    }
    final inputs = sortedUtxos.map((e) => e.utxo.toInput()).toList();
    if (enableRBF) {
      for (int i = 0; i < inputs.length; i++) {
        inputs[i] = inputs[i].copyWith(
          sequence: BitcoinOpCodeConst.replaceByFeeSequence,
        );
      }
    }
    return (
      List<TxInput>.unmodifiable(inputs),
      List<UtxoWithAddress>.unmodifiable(sortedUtxos),
    );
  }

  List<TxOutput> _buildOutputs() {
    var outputs =
        outPuts
            .where((element) => element is! BitcoinBurnableOutput)
            .map((e) => e.toOutput)
            .toList();

    if (memo != null) {
      outputs.add(
        TxOutput(amount: BigInt.zero, scriptPubKey: _opReturn(memo!)),
      );
    }

    if (outputOrdering == BitcoinOrdering.shuffle) {
      outputs = outputs..shuffle();
    } else if (outputOrdering == BitcoinOrdering.bip69) {
      outputs =
          outputs..sort((a, b) {
            final valueComparison = a.amount.compareTo(b.amount);
            if (valueComparison == 0) {
              return BytesUtils.compareBytes(
                a.scriptPubKey.toBytes(),
                b.scriptPubKey.toBytes(),
              );
            }
            return valueComparison;
          });
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
    for (final out in outputs) {
      final token = out.cashToken;
      if (token == null || !token.hasAmount) continue;
      final amount = tokens[token.category] ?? BigInt.zero;
      tokens[token.category] = amount + token.amount;
    }
    return tokens;
  }

  void _validate({
    required List<UtxoWithAddress> utxos,
    required List<TxOutput> outputs,
    required BigInt sumAmountsWithFee,
    required BigInt sumUtxoAmount,
    required BigInt sumOutputAmounts,
  }) {
    if (isFakeTransaction) return;
    if (sumAmountsWithFee != sumUtxoAmount) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        'Sum of UTXO values does not equal outputs plus fee.',
        details: {
          'inputAmount': sumUtxoAmount.toString(),
          'fee': fee.toString(),
          'outputAmount': sumOutputAmounts.toString(),
        },
      );
    }

    /// sum of token amounts
    final sumOfTokenUtxos = utxos.sumOfTokenUtxos();

    /// sum of token output amounts
    final sumTokenOutputAmouts = _sumTokenOutputAmounts(outputs);
    for (final i in sumOfTokenUtxos.entries) {
      if (sumTokenOutputAmouts[i.key] != i.value) {
        BigInt amount = sumTokenOutputAmouts[i.key] ?? BigInt.zero;
        amount += outPuts
            .whereType<BitcoinBurnableOutput>()
            .where((element) => element.categoryID == i.key)
            .fold(
              BigInt.zero,
              (previousValue, element) => previousValue + (element.value),
            );

        if (amount != i.value) {
          throw BuError(
            DefaultErrorType.invalidArgument,
            'Sum token value of UTXOs not spending. use BitcoinBurnableOutput if you want to burn tokens.',
            details: {
              'token': i.key,
              'inputValue': i.value.toString(),
              'outputValue': amount.toString(),
            },
          );
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
              element.token.category == token.category,
        );
        if (hasOneoutput) continue;
        final hasBurnableOutput = outPuts
            .whereType<BitcoinBurnableOutput>()
            .any(
              (element) =>
                  element.utxoHash == i.utxo.txHash &&
                  element.categoryID == token.category,
            );
        if (hasBurnableOutput) continue;
        throw BuError(
          DefaultErrorType.invalidArgument,
          'Some NFTs in the inputs lack the corresponding spending in the outputs. If you intend to burn tokens, consider utilizing the BitcoinBurnableOutput.',
          details: {'category id': token.category},
        );
      }
    }
  }

  @override
  Map<String, int> getSignatureCount() {
    final sortedInputs = _buildInputs();
    final inputs = sortedInputs.$1;
    final utxos = sortedInputs.$2;
    final count = <String, int>{};

    for (var i = 0; i < inputs.length; i++) {
      final indexUtxo = utxos[i];

      if (indexUtxo.isMultiSig()) {
        final multiSigAddress = indexUtxo.multiSigAddress;
        var sumMultiSigWeight = 0;
        final mutlsiSigSignatures = <String>[];
        for (
          var ownerIndex = 0;
          ownerIndex < multiSigAddress.signers.length;
          ownerIndex++
        ) {
          for (
            var weight = 0;
            weight < multiSigAddress.signers[ownerIndex].weight;
            weight++
          ) {
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
          throw BuError(
            DefaultErrorType.invalidState,
            'some multisig signature does not exist',
          );
        }
        continue;
      }
      final pubkey = indexUtxo.public().toHex();
      count[pubkey] = (count[pubkey] ?? 0) + 1;
    }
    return count;
  }

  /// Prepares the transaction and all the data required to sign its inputs.
  _PreparedTransaction _prepareTransaction() {
    /// build inputs
    final sortedInputs = _buildInputs();

    final inputs = sortedInputs.$1;

    final utxos = sortedInputs.$2;

    /// build outout
    final outputs = _buildOutputs();

    /// sum of amounts you filled in outputs
    final sumOutputAmounts = _sumOutputAmounts(outputs);

    /// sum of UTXOs amount
    final sumUtxoAmount = utxos.sumOfUtxosValue();

    /// sum of outputs amount + transaction fee
    final sumAmountsWithFee = (sumOutputAmounts + fee);

    _validate(
      utxos: utxos,
      outputs: outputs,
      sumAmountsWithFee: sumAmountsWithFee,
      sumUtxoAmount: sumUtxoAmount,
      sumOutputAmounts: sumOutputAmounts,
    );

    /// create new transaction with inputs and outputs and isSegwit transaction or not
    final transaction = BtcTransaction(
      inputs: inputs,
      outputs: outputs,
      locktime: locktime,
    );

    return (
      inputs: inputs,
      utxos: utxos,
      outputs: outputs,
      transaction: transaction,
    );
  }

  /// Transaction digest and sighash type of the given input.
  ({BuBytes digest, int sighash}) _inputDigest({
    required int index,
    required UtxoWithAddress utxo,
    required BtcTransaction transaction,
  }) {
    const sighash =
        BitcoinOpCodeConst.sighashAll | BitcoinOpCodeConst.sighashForked;

    /// We receive the owner's ScriptPubKey
    final script = _buildInputScriptPubKeys(utxo);

    /// We generate transaction digest for current input
    final digest = _generateTransactionDigest(
      scriptPubKeys: script,
      input: index,
      utox: utxo,
      transaction: transaction,
      sighash: sighash,
    );

    return (digest: digest, sighash: sighash);
  }

  /// Signs the given input and returns its signatures.
  ///
  /// A multi-signature input is signed by the [multiSigSign] callback, that is
  /// called once for the input and returns the signature of every signer.
  /// When it is not provided the legacy behaviour is used and the [sign]
  /// callback is called once for every signer of the multi-signature address.
  List<String> _signInput({
    required int index,
    required UtxoWithAddress utxo,
    required BtcTransaction transaction,
    required BitcoinSignerCallBack sign,
    BitcoinMultiSigSignerCallBack? multiSigSign,
  }) {
    final inputDigest = _inputDigest(
      index: index,
      utxo: utxo,
      transaction: transaction,
    );
    final digest = inputDigest.digest;
    final sighash = inputDigest.sighash;

    /// handle multisig address
    if (utxo.isMultiSig()) {
      final multiSigAddress = utxo.multiSigAddress;
      final signatures =
          multiSigSign != null
              ? multiSigSign(
                digest,
                utxo,
                multiSigAddress.signers.map((e) => e.publicKey).toList(),
                sighash,
              )
              : _legacyMultiSigSignatures(
                digest: digest,
                utxo: utxo,
                multiSigAddress: multiSigAddress,
                sighash: sighash,
                sign: sign,
              );
      return BtcMultisigUtils.buildSignatures(
        multiSigAddress: multiSigAddress,
        signatures: signatures,
      );
    }

    /// now we need sign the transaction digest
    return [sign(digest, utxo, utxo.ownerDetails.publicKey!, sighash)];
  }

  /// Collects the signature of every signer of a multi-signature input using
  /// the legacy signer, that is called once for each signer of the address.
  Map<String, String> _legacyMultiSigSignatures({
    required BuBytes digest,
    required UtxoWithAddress utxo,
    required MultiSignatureAddress multiSigAddress,
    required int sighash,
    required BitcoinSignerCallBack sign,
  }) {
    final signatures = <String, String>{};
    var sumMultiSigWeight = 0;
    for (final signer in multiSigAddress.signers) {
      /// now we need sign the transaction digest
      final signature = sign(digest, utxo, signer.publicKey, sighash);
      if (signature.isEmpty) continue;
      signatures[signer.publicKey] = signature;
      sumMultiSigWeight += signer.weight;
      if (sumMultiSigWeight >= multiSigAddress.threshold) {
        break;
      }
    }
    return signatures;
  }

  @override
  BtcTransaction buildTransaction(
    BitcoinSignerCallBack sign, {
    BitcoinMultiSigSignerCallBack? multiSigSign,
  }) {
    /// prepare the transaction and the data needed to sign its inputs
    final prepared = _prepareTransaction();

    /// Well, now let's do what we want for each input
    for (var i = 0; i < prepared.inputs.length; i++) {
      final utxo = prepared.utxos[i];

      /// now we need sign the transaction digest
      final signatures = _signInput(
        index: i,
        utxo: utxo,
        transaction: prepared.transaction,
        sign: sign,
        multiSigSign: multiSigSign,
      );

      _addScripts(
        input: prepared.inputs[i],
        signatures: signatures,
        utxo: utxo,
      );
    }

    return prepared.transaction;
  }

  @override
  Future<BtcTransaction> buildTransactionAsync(
    BitcoinSignerCallBackAsync sign, {
    BitcoinMultiSigSignerCallBackAsync? multiSigSign,
  }) async {
    /// prepare the transaction and the data needed to sign its inputs
    final prepared = _prepareTransaction();

    /// Well, now let's do what we want for each input
    for (var i = 0; i < prepared.inputs.length; i++) {
      final utxo = prepared.utxos[i];

      /// now we need sign the transaction digest
      final signatures = await _signInputAsync(
        index: i,
        utxo: utxo,
        transaction: prepared.transaction,
        sign: sign,
        multiSigSign: multiSigSign,
      );

      _addScripts(
        input: prepared.inputs[i],
        signatures: signatures,
        utxo: utxo,
      );
    }

    return prepared.transaction;
  }

  /// Signs the given input and returns its signatures.
  ///
  /// A multi-signature input is signed by the [multiSigSign] callback, that is
  /// called once for the input and returns the signature of every signer.
  /// When it is not provided the legacy behaviour is used and the [sign]
  /// callback is called once for every signer of the multi-signature address.
  Future<List<String>> _signInputAsync({
    required int index,
    required UtxoWithAddress utxo,
    required BtcTransaction transaction,
    required BitcoinSignerCallBackAsync sign,
    BitcoinMultiSigSignerCallBackAsync? multiSigSign,
  }) async {
    final inputDigest = _inputDigest(
      index: index,
      utxo: utxo,
      transaction: transaction,
    );
    final digest = inputDigest.digest;
    final sighash = inputDigest.sighash;

    /// handle multisig address
    if (utxo.isMultiSig()) {
      final multiSigAddress = utxo.multiSigAddress;
      final signatures =
          multiSigSign != null
              ? await multiSigSign(
                digest,
                utxo,
                multiSigAddress.signers.map((e) => e.publicKey).toList(),
                sighash,
              )
              : await _legacyMultiSigSignaturesAsync(
                digest: digest,
                utxo: utxo,
                multiSigAddress: multiSigAddress,
                sighash: sighash,
                sign: sign,
              );
      return BtcMultisigUtils.buildSignatures(
        multiSigAddress: multiSigAddress,
        signatures: signatures,
      );
    }

    /// now we need sign the transaction digest
    return [await sign(digest, utxo, utxo.ownerDetails.publicKey!, sighash)];
  }

  /// Collects the signature of every signer of a multi-signature input using
  /// the legacy signer, that is called once for each signer of the address.
  Future<Map<String, String>> _legacyMultiSigSignaturesAsync({
    required BuBytes digest,
    required UtxoWithAddress utxo,
    required MultiSignatureAddress multiSigAddress,
    required int sighash,
    required BitcoinSignerCallBackAsync sign,
  }) async {
    final signatures = <String, String>{};
    var sumMultiSigWeight = 0;
    for (final signer in multiSigAddress.signers) {
      /// now we need sign the transaction digest
      final signature = await sign(digest, utxo, signer.publicKey, sighash);
      if (signature.isEmpty) continue;
      signatures[signer.publicKey] = signature;
      sumMultiSigWeight += signer.weight;
      if (sumMultiSigWeight >= multiSigAddress.threshold) {
        break;
      }
    }
    return signatures;
  }

  void _addScripts({
    required UtxoWithAddress utxo,
    required TxInput input,
    required List<String> signatures,
  }) {
    /// ok we signed, now we need unlocking script for this input
    final scriptSig =
        utxo.isMultiSig()
            ? _buildMiltisigUnlockingScript(signatures, utxo)
            : _buildUnlockingScript(signatures.first, utxo);
    input.scriptSig = Script(script: scriptSig);
  }
}

/// The transaction and the data required to sign its inputs.
typedef _PreparedTransaction =
    ({
      List<TxInput> inputs,
      List<UtxoWithAddress> utxos,
      List<TxOutput> outputs,
      BtcTransaction transaction,
    });
