import 'dart:convert';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/binary/utils.dart';

class BCHTransactionBuilder {
  final List<BitcoinOutput> outPuts;
  final BigInt fee;
  final BasedUtxoNetwork network;
  final List<UtxoWithAddress> utxos;
  final String? memo;
  final bool enableRBF;
  final bool isFakeTransaction;
  BCHTransactionBuilder({
    required this.outPuts,
    required this.fee,
    required this.network,
    required this.utxos,
    this.memo,
    this.enableRBF = false,
    this.isFakeTransaction = false,
  }) {
    _validateBuilder();
  }

  void _validateBuilder() {
    if (network is! BitcoinCashNetwork) {
      throw ArgumentError(
          "invalid network for BCHTransactionBuilder use  BitcoinCashNetwork");
    }
    for (final i in utxos) {
      i.ownerDetails.address.toAddress(network);
    }
    for (final i in outPuts) {
      i.address.toAddress(network);
    }
  }

  /// This method is used to create a dummy transaction,
  /// allowing us to obtain the size of the original transaction
  /// before conducting the actual transaction. This helps us estimate the transaction cost
  static int estimateTransactionSize(
      {required List<UtxoWithAddress> utxos,
      required List<BitcoinAddress> outputs,
      required BitcoinNetwork network,
      String? memo,
      bool enableRBF = false}) {
    final sum = utxos.sumOfUtxosValue();

    /// We consider the total amount for the output because,
    /// in all cases, the size of the amount is 8 bytes.
    final outs =
        outputs.map((e) => BitcoinOutput(address: e, value: sum)).toList();
    final transactionBuilder = BCHTransactionBuilder(
      /// Now, we provide the UTXOs we want to spend.
      utxos: utxos,

      /// We select transaction outputs
      outPuts: outs,

      /// Transaction fee
      /// Ensure that you have accurately calculated the amounts.
      /// If the sum of the outputs, including the transaction fee,
      /// does not match the total amount of UTXOs,
      /// it will result in an error. Please double-check your calculations.
      fee: BigInt.from(0),

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
      isFakeTransaction: true,
    );

    /// 71 bytes (64 byte signature, 6-7 byte Der encoding length)
    const String fakeECDSASignatureBytes =
        "0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101";

    final transaction = transactionBuilder
        .buildTransaction((trDigest, utxo, multiSigPublicKey, int sighash) {
      return fakeECDSASignatureBytes;
    });

    /// Now we need the size of the transaction.
    final size = transaction.getSize();

    return size;
  }

  /// It is used to make the appropriate scriptSig
  Script buildInputScriptPubKeys(UtxoWithAddress utxo) {
    if (utxo.isMultiSig()) {
      final script = utxo.multiSigAddress.multiSigScript;
      switch (utxo.utxo.scriptType) {
        case BitcoinAddressType.p2pkhInP2sh:
          return script;
        default:
          throw ArgumentError(
              "unsuported multi-sig type ${utxo.utxo.scriptType} for ${network.conf.coinName.name}");
      }
    }

    final senderPub = utxo.public();
    switch (utxo.utxo.scriptType) {
      case BitcoinAddressType.p2pk:
      case BitcoinAddressType.p2pkInP2sh:
        return senderPub.toRedeemScript();
      case BitcoinAddressType.p2pkh:
      case BitcoinAddressType.p2pkhInP2sh:
        return senderPub.toAddress().toScriptPubKey();
      default:
        throw ArgumentError(
            "${utxo.utxo.scriptType} does not support on ${network.conf.coinName.name}");
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
  List<int> generateTransactionDigest(
    Script scriptPubKeys,
    int input,
    UtxoWithAddress utox,
    BtcTransaction transaction,
  ) {
    return transaction.getTransactionSegwitDigit(
        txInIndex: input,
        script: scriptPubKeys,
        amount: utox.utxo.value,
        sighash:
            BitcoinOpCodeConst.SIGHASH_ALL | BitcoinOpCodeConst.SIGHASH_FORKED);
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
  List<String> buildMiltisigUnlockingScript(
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
  List<String> buildUnlockingScript(String signedDigest, UtxoWithAddress utx) {
    final senderPub = utx.public();
    if (utx.utxo.isSegwit()) {
      switch (utx.utxo.scriptType) {
        case BitcoinAddressType.p2wshInP2sh:
        case BitcoinAddressType.p2wsh:
          final script = senderPub.toP2wshScript();
          return ['', signedDigest, script.toHex()];
        default:
          // final script = senderPub.toAddress().toScriptPubKey();
          return [signedDigest, senderPub.toHex()];
      }
    } else {
      switch (utx.utxo.scriptType) {
        case BitcoinAddressType.p2pk:
          return [signedDigest];
        case BitcoinAddressType.p2pkh:
          return [signedDigest, senderPub.toHex()];
        case BitcoinAddressType.p2pkhInP2sh:
          final script = senderPub.toAddress().toScriptPubKey();
          return [signedDigest, senderPub.toHex(), script.toHex()];
        case BitcoinAddressType.p2pkInP2sh:
          final script = senderPub.toRedeemScript();
          return [signedDigest, script.toHex()];
        default:
          throw Exception(
              'Cannot send from this type of address ${utx.utxo.scriptType}');
      }
    }
  }

  List<TxInput> buildInputs() {
    final sequence = enableRBF
        ? (Sequence(
                seqType: BitcoinOpCodeConst.TYPE_REPLACE_BY_FEE,
                value: 0,
                isTypeBlock: true))
            .forInputSequence()
        : null;
    final inputs = <TxInput>[];
    for (int i = 0; i < utxos.length; i++) {
      final e = utxos[i];
      inputs.add(TxInput(
          txId: e.utxo.txHash,
          txIndex: e.utxo.vout,
          sequance: i == 0 && enableRBF ? sequence : null));
    }
    return inputs;
  }

  List<TxOutput> buildOutputs() {
    final outputs = <TxOutput>[];
    for (final e in outPuts) {
      outputs.add(
          TxOutput(amount: e.value, scriptPubKey: buildOutputScriptPubKey(e)));
    }
    return outputs;
  }

/*
the scriptPubKey of a UTXO (Unspent Transaction Output) is used as the locking
script that defines the spending conditions for the bitcoins associated
with that UTXO. When creating a Bitcoin transaction, the spending conditions
specified by the scriptPubKey must be satisfied by the corresponding scriptSig
in the transaction input to spend the UTXO.
*/
  Script buildOutputScriptPubKey(BitcoinOutput addr) {
    return addr.address.toScriptPubKey();
  }

/*
The primary use case for OP_RETURN is data storage. You can embed various types of
data within the OP_RETURN output, such as text messages, document hashes, or metadata
related to a transaction. This data is permanently recorded on the blockchain and can
be retrieved by anyone who examines the blockchain's history.
*/
  Script opReturn(String message) {
    try {
      BytesUtils.fromHexString(message);
      return Script(script: ["OP_RETURN", message]);

      /// ignore: empty_catches
    } catch (e) {}
    final toBytes = utf8.encode(message);
    final toHex = BytesUtils.toHexString(toBytes);
    return Script(script: ["OP_RETURN", toHex]);
  }

  /// Total amount to spend excluding fees
  BigInt sumOutputAmounts() {
    BigInt sum = BigInt.zero;
    for (final e in outPuts) {
      sum += e.value;
    }
    return sum;
  }

  BtcTransaction buildTransaction(BitcoinSignerCallBack sign) {
    /// build inputs
    final inputs = buildInputs();

    /// build outout
    final outputs = buildOutputs();

    /// check if you set memos or not
    if (memo != null) {
      outputs.add(TxOutput(amount: BigInt.zero, scriptPubKey: opReturn(memo!)));
    }

    /// sum of amounts you filled in outputs
    final sumOutputAmounts = this.sumOutputAmounts();

    /// sum of UTXOS amount
    final sumUtxoAmount = utxos.sumOfUtxosValue();

    /// sum of outputs amount + transcation fee
    final sumAmountsWithFee = (sumOutputAmounts + fee);

    /// We will check whether you have spent the correct amounts or not
    if (!isFakeTransaction && sumAmountsWithFee != sumUtxoAmount) {
      throw Exception('Sum value of utxo not spending');
    }

    /// create new transaction with inputs and outputs and isSegwit transaction or not
    final transaction =
        BtcTransaction(inputs: inputs, outputs: outputs, hasSegwit: false);

    const int sighash =
        BitcoinOpCodeConst.SIGHASH_ALL | BitcoinOpCodeConst.SIGHASH_FORKED;

    /// Well, now let's do what we want for each input
    for (int i = 0; i < inputs.length; i++) {
      /// We receive the owner's ScriptPubKey
      final script = buildInputScriptPubKeys(utxos[i]);

      /// We generate transaction digest for current input
      final digest =
          generateTransactionDigest(script, i, utxos[i], transaction);

      /// handle multisig address
      if (utxos[i].isMultiSig()) {
        final multiSigAddress = utxos[i].multiSigAddress;
        int sumMultiSigWeight = 0;
        final mutlsiSigSignatures = <String>[];
        for (int ownerIndex = 0;
            ownerIndex < multiSigAddress.signers.length;
            ownerIndex++) {
          /// now we need sign the transaction digest
          final sig = sign(digest, utxos[i],
              multiSigAddress.signers[ownerIndex].publicKey, sighash);
          if (sig.isEmpty) continue;
          for (int weight = 0;
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
        if (sumMultiSigWeight != multiSigAddress.threshold) {
          throw StateError("some multisig signature does not exist");
        }

        addScripts(
            input: inputs[i], signatures: mutlsiSigSignatures, utxo: utxos[i]);
        continue;
      }

      /// now we need sign the transaction digest
      final sig = sign(digest, utxos[i], utxos[i].public().toHex(), sighash);
      addScripts(input: inputs[i], signatures: [sig], utxo: utxos[i]);
    }

    return transaction;
  }

  void addScripts({
    required UtxoWithAddress utxo,
    required TxInput input,
    required List<String> signatures,
  }) {
    /// ok we signed, now we need unlocking script for this input
    final scriptSig = utxo.isMultiSig()
        ? buildMiltisigUnlockingScript(signatures, utxo)
        : buildUnlockingScript(signatures.first, utxo);

    input.scriptSig = Script(script: scriptSig);
  }
}
