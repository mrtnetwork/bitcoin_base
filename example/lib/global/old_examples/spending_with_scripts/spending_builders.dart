import 'package:bitcoin_base/bitcoin_base.dart';

BtcTransaction buildP2wpkTransaction({
  required List<BitcoinOutput> receiver,
  required String Function(List<int>, String publicKey, int sighash) sign,
  required List<UtxoWithAddress> utxo,
}) {
  // We define transaction inputs by specifying the transaction ID and index.
  final txin = utxo
      .map((e) => TxInput(txId: e.utxo.txHash, txIndex: e.utxo.vout))
      .toList();
  // in a SegWit (Segregated Witness) transaction, the witness data serves as the unlocking script
  // for the transaction inputs. In traditional non-SegWit transactions,
  // the unlocking script is part of the scriptSig field, which contains
  // the signatures and other data required to spend a transaction output.
  // However, in SegWit transactions, the unlocking script (also known as the witness or witness script)
  // is moved to a separate part of the transaction called the "witness" field
  final List<TxWitnessInput> witnesses = [];

  // Create transaction outputs
  // Parameters
  //  amount: This is the quantity of Bitcoin being sent to the recipient's address.
  //  It represents the value of the transaction output in Bitcoin.

  //  scriptPubKey: This is a script that specifies the conditions that must be met in order to spend the output.
  //  It includes the recipient's Bitcoin address (encoded in a specific way)
  //  and can also include additional conditions or requirements based on the type of script used.
  final List<TxOutput> txOut = receiver
      .map((e) =>
          TxOutput(amount: e.value, scriptPubKey: e.address.toScriptPubKey()))
      .toList();

  // create BtcTransaction instance with inputs, outputs and segwit
  // For P2TR, P2WPKH, P2WSH, and P2SH (SegWit) transactions, we need to set 'hasSegwit' to true.
  BtcTransaction tx = BtcTransaction(inputs: txin, outputs: txOut);

  for (int i = 0; i < txin.length; i++) {
    // For SegWit transactions (excluding P2TR), we use the 'getTransactionSegwitDigit' method
    // to obtain the input digest for signing.
    final txDigit = tx.getTransactionSegwitDigit(
        // index of input
        txInIndex: i,
        // script pub key of spender address
        script: utxo[i].public().toAddress().toScriptPubKey(),
        // amount of utxo
        amount: utxo[i].utxo.value);
    // sign transaction
    final signedTx =
        sign(txDigit, utxo[i].public().toHex(), BitcoinOpCodeConst.sighashAll);

    // create unlock script

    // P2WPKH: (Pay-to-Witness-Public-Key-Hash): When you're spending from a SegWit P2WPKH address,
    // you typically create a SegWit transaction. You'll use the witness (witnessScript) to provide
    // the required signatures, and the transaction will indicate it's a SegWit transaction.

    // P2WSH (Pay-to-Witness-Script-Hash): Similarly, for P2WSH addresses, you create SegWit transactions,
    // and the witness data (signatures and script) is separated from the transaction data.
    final p2wpkhWitness =
        TxWitnessInput(stack: [signedTx, utxo[i].public().toHex()]);
    witnesses.add(p2wpkhWitness);
  }
  tx = tx.copyWith(witnesses: witnesses);
  return tx;
}

BtcTransaction buildP2WSHTransaction({
  required List<BitcoinOutput> receiver,
  required String Function(List<int>, String publicKey, int sighash) sign,
  required List<UtxoWithAddress> utxo,
}) {
  // We define transaction inputs by specifying the transaction ID and index.
  final txin = utxo
      .map((e) => TxInput(txId: e.utxo.txHash, txIndex: e.utxo.vout))
      .toList();

  // in a SegWit (Segregated Witness) transaction, the witness data serves as the unlocking script
  // for the transaction inputs. In traditional non-SegWit transactions,
  // the unlocking script is part of the scriptSig field, which contains
  // the signatures and other data required to spend a transaction output.
  // However, in SegWit transactions, the unlocking script (also known as the witness or witness script)
  // is moved to a separate part of the transaction called the "witness" field
  final List<TxWitnessInput> witnesses = [];

  // Create transaction outputs
  // Parameters
  //  amount: This is the quantity of Bitcoin being sent to the recipient's address.
  //  It represents the value of the transaction output in Bitcoin.

  //  scriptPubKey: This is a script that specifies the conditions that must be met in order to spend the output.
  //  It includes the recipient's Bitcoin address (encoded in a specific way)
  //  and can also include additional conditions or requirements based on the type of script used.
  final List<TxOutput> txOut = receiver
      .map((e) =>
          TxOutput(amount: e.value, scriptPubKey: e.address.toScriptPubKey()))
      .toList();

  // create BtcTransaction instance with inputs, outputs and segwit
  // For P2TR, P2WPKH, P2WSH, and P2SH (SegWit) transactions, we need to set 'hasSegwit' to true.
  BtcTransaction tx = BtcTransaction(inputs: txin, outputs: txOut);
  for (int i = 0; i < txin.length; i++) {
    // For SegWit transactions (excluding P2TR), we use the 'getTransactionSegwitDigit' method
    // to obtain the input digest for signing.
    final txDigit = tx.getTransactionSegwitDigit(
        // index of utxo
        txInIndex: i,
        // P2WSH scripts
        script: utxo[i].public().toP2wshScript(),
        // amount of utxo
        amount: utxo[i].utxo.value);

    // sign transaction
    final signedTx = sign(txDigit, utxo[i].public().toP2wshScript().toHex(),
        BitcoinOpCodeConst.sighashAll);

    // create unlock script

    // P2WPKH: (Pay-to-Witness-Public-Key-Hash): When you're spending from a SegWit P2WPKH address,
    // you typically create a SegWit transaction. You'll use the witness (witnessScript) to provide
    // the required signatures, and the transaction will indicate it's a SegWit transaction.

    // P2WSH (Pay-to-Witness-Script-Hash): Similarly, for P2WSH addresses, you create SegWit transactions,
    // and the witness data (signatures and script) is separated from the transaction data.
    final p2wshWitness =
        TxWitnessInput(stack: ['', signedTx, utxo[i].public().toHex()]);
    witnesses.add(p2wshWitness);
  }

  tx = tx.copyWith(witnesses: witnesses);
  return tx;
}

BtcTransaction buildP2pkhTransaction({
  required List<BitcoinOutput> receiver,
  required String Function(List<int>, String publicKey, int sighash) sign,
  required List<UtxoWithAddress> utxo,
}) {
  // We define transaction inputs by specifying the transaction ID and index.
  final txin = utxo
      .map((e) => TxInput(txId: e.utxo.txHash, txIndex: e.utxo.vout))
      .toList();

  // Create transaction outputs
  // Parameters
  //  amount: This is the quantity of Bitcoin being sent to the recipient's address.
  //  It represents the value of the transaction output in Bitcoin.

  //  scriptPubKey: This is a script that specifies the conditions that must be met in order to spend the output.
  //  It includes the recipient's Bitcoin address (encoded in a specific way)
  //  and can also include additional conditions or requirements based on the type of script used.
  final List<TxOutput> txOut = receiver
      .map((e) =>
          TxOutput(amount: e.value, scriptPubKey: e.address.toScriptPubKey()))
      .toList();

  // For P2TR, P2WPKH, P2WSH, and P2SH (SegWit) transactions, in this case we need to set 'hasSegwit' to false.
  final tx = BtcTransaction(inputs: txin, outputs: txOut);
  for (int i = 0; i < txin.length; i++) {
    // For None-SegWit transactions, we use the 'getTransactionDigest' method
    // to obtain the input digest for signing.
    final txDigit = tx.getTransactionDigest(
      // index of utxo
      txInIndex: i,
      // spender script pub key
      script: utxo[i].public().toAddress().toScriptPubKey(),
    );

    // sign transaction
    final signedTx =
        sign(txDigit, utxo[i].public().toHex(), BitcoinOpCodeConst.sighashAll);

    // set unlocking script for current index
    txin[i].scriptSig = Script(script: [signedTx, utxo[i].public().toHex()]);
  }

  return tx;
}

BtcTransaction buildP2shNoneSegwitTransaction({
  required List<BitcoinOutput> receiver,
  required String Function(List<int>, String publicKey, int sighash) sign,
  required List<UtxoWithAddress> utxo,
}) {
  // We define transaction inputs by specifying the transaction ID and index.
  final txin = utxo
      .map((e) => TxInput(txId: e.utxo.txHash, txIndex: e.utxo.vout))
      .toList();

  // Create transaction outputs
  // Parameters
  //  amount: This is the quantity of Bitcoin being sent to the recipient's address.
  //  It represents the value of the transaction output in Bitcoin.

  //  scriptPubKey: This is a script that specifies the conditions that must be met in order to spend the output.
  //  It includes the recipient's Bitcoin address (encoded in a specific way)
  //  and can also include additional conditions or requirements based on the type of script used.
  final List<TxOutput> txOut = receiver
      .map((e) =>
          TxOutput(amount: e.value, scriptPubKey: e.address.toScriptPubKey()))
      .toList();

  // For P2TR, P2WPKH, P2WSH, and P2SH (SegWit) transactions, in this caase we need to set 'hasSegwit' to false.
  final tx = BtcTransaction(inputs: txin, outputs: txOut);
  for (int i = 0; i < txin.length; i++) {
    final ownerPublic = utxo[i].public();
    final scriptPubKey =
        utxo[i].ownerDetails.address.type == P2shAddressType.p2pkhInP2sh
            ? ownerPublic.toAddress().toScriptPubKey()
            : ownerPublic.toRedeemScript();
    // For None-SegWit transactions, we use the 'getTransactionDigest' method
    // to obtain the input digest for signing.
    final txDigit = tx.getTransactionDigest(
      // index of utxo
      txInIndex: i,
      // script pub key
      script: scriptPubKey,
    );
    // sign transaction
    final signedTx =
        sign(txDigit, utxo[i].public().toHex(), BitcoinOpCodeConst.sighashAll);

    // set unlocking script for current index
    switch (utxo[i].ownerDetails.address.type) {
      case P2shAddressType.p2pkhInP2sh:
        txin[i].scriptSig = Script(
            script: [signedTx, ownerPublic.toHex(), scriptPubKey.toHex()]);
        break;
      case P2shAddressType.p2pkInP2sh:
        txin[i].scriptSig = Script(script: [signedTx, scriptPubKey.toHex()]);
        break;
      default:
        throw ArgumentError("invalid address type");
    }
  }

  return tx;
}

BtcTransaction buildP2SHSegwitTransaction({
  required List<BitcoinOutput> receiver,
  required String Function(List<int>, String publicKey, int sighash) sign,
  required List<UtxoWithAddress> utxo,
}) {
  // We define transaction inputs by specifying the transaction ID and index.
  final txin = utxo
      .map((e) => TxInput(txId: e.utxo.txHash, txIndex: e.utxo.vout))
      .toList();

  // Create transaction outputs
  // Parameters
  //  amount: This is the quantity of Bitcoin being sent to the recipient's address.
  //  It represents the value of the transaction output in Bitcoin.

  //  scriptPubKey: This is a script that specifies the conditions that must be met in order to spend the output.
  //  It includes the recipient's Bitcoin address (encoded in a specific way)
  //  and can also include additional conditions or requirements based on the type of script used.
  final List<TxOutput> txOut = receiver
      .map((e) =>
          TxOutput(amount: e.value, scriptPubKey: e.address.toScriptPubKey()))
      .toList();
  // in a SegWit (Segregated Witness) transaction, the witness data serves as the unlocking script
  // for the transaction inputs. In traditional non-SegWit transactions,
  // the unlocking script is part of the scriptSig field, which contains
  // the signatures and other data required to spend a transaction output.
  // However, in SegWit transactions, the unlocking script (also known as the witness or witness script)
  // is moved to a separate part of the transaction called the "witness" field
  final List<TxWitnessInput> witnesses = [];

  // For P2TR, P2WPKH, P2WSH, and P2SH (SegWit) transactions, we need to set 'hasSegwit' to true.
  final tx = BtcTransaction(inputs: txin, outputs: txOut);

  for (int i = 0; i < txin.length; i++) {
    final ownerPublic = utxo[i].public();
    final scriptPubKey =
        utxo[i].ownerDetails.address.type == P2shAddressType.p2wpkhInP2sh
            ? ownerPublic.toAddress().toScriptPubKey()
            : ownerPublic.toP2wshScript();

    // For SegWit transactions (excluding P2TR), we use the 'getTransactionSegwitDigit' method
    // to obtain the input digest for signing.
    final txDigit = tx.getTransactionSegwitDigit(
        // index of utxo
        txInIndex: i,
        // script pub key
        script: scriptPubKey,
        // amount of utxo
        amount: utxo[i].utxo.value);

    // sign transaction
    final signedTx =
        sign(txDigit, utxo[i].public().toHex(), BitcoinOpCodeConst.sighashAll);

    // In a SegWit P2SH (Pay-to-Script-Hash) transaction, you will find both a scriptSig field and a witness field.
    //  This combination is used to maintain compatibility with non-SegWit Bitcoin nodes while taking advantage
    //  of Segregated Witness (SegWit).

    // ScriptSig: This field contains a P2SH redeem script.
    // This redeem script is a script that encloses the witness script (the actual spending condition).
    // Non-SegWit nodes use this script to validate the transaction as they do
    // not understand the witness structure.

    // Witness: This field contains segregated witness data.
    // It includes the signatures and any additional data required to unlock the transaction inputs.
    // SegWit nodes use this data to validate the transaction and check the signatures.
    switch (utxo[i].ownerDetails.address.type) {
      case P2shAddressType.p2wpkhInP2sh:
        witnesses.add(TxWitnessInput(stack: [signedTx, ownerPublic.toHex()]));
        final script = ownerPublic.toSegwitAddress().toScriptPubKey();
        txin[i].scriptSig = Script(script: [script.toHex()]);
        break;
      case P2shAddressType.p2wshInP2sh:
        witnesses.add(TxWitnessInput(stack: [signedTx, scriptPubKey.toHex()]));
        final script = ownerPublic.toP2wshAddress().toScriptPubKey();
        txin[i].scriptSig = Script(script: [script.toHex()]);
        break;
      default:
        throw ArgumentError("invalid address type");
    }
  }

  return tx;
}

BtcTransaction buildP2trTransaction({
  required List<BitcoinOutput> receiver,
  required String Function(List<int>, String publicKey, int sighash) sign,
  required List<UtxoWithAddress> utxo,
}) {
  // We define transaction inputs by specifying the transaction ID and index.
  final txin = utxo
      .map((e) => TxInput(txId: e.utxo.txHash, txIndex: e.utxo.vout))
      .toList();

  // Create transaction outputs
  // Parameters
  //  amount: This is the quantity of Bitcoin being sent to the recipient's address.
  //  It represents the value of the transaction output in Bitcoin.

  //  scriptPubKey: This is a script that specifies the conditions that must be met in order to spend the output.
  //  It includes the recipient's Bitcoin address (encoded in a specific way)
  //  and can also include additional conditions or requirements based on the type of script used.
  final List<TxOutput> txOut = receiver
      .map((e) =>
          TxOutput(amount: e.value, scriptPubKey: e.address.toScriptPubKey()))
      .toList();

  // For P2TR, P2WPKH, P2WSH, and P2SH (SegWit) transactions, we need to set 'hasSegwit' to true.
  BtcTransaction tx = BtcTransaction(inputs: txin, outputs: txOut);

  // in a SegWit (Segregated Witness) transaction, the witness data serves as the unlocking script
  // for the transaction inputs. In traditional non-SegWit transactions,
  // the unlocking script is part of the scriptSig field, which contains
  // the signatures and other data required to spend a transaction output.
  // However, in SegWit transactions, the unlocking script (also known as the witness or witness script)
  // is moved to a separate part of the transaction called the "witness" field
  final List<TxWitnessInput> witnesses = [];

  for (int i = 0; i < txin.length; i++) {
    // For P2TR transactions, we use the 'getTransactionTaprootDigset' method
    // to obtain the input digest for signing.
    // For Tapleaf (Tapscript), you should create the script yourself.
    final txDigit = tx.getTransactionTaprootDigset(
      // utxo index
      txIndex: i,
      // In Taproot,  when you create a transaction digest for signing,
      // you typically need to include all the scriptPubKeys of the UTXOs
      // being spent and their corresponding amounts.
      // This information is required to ensure that the transaction is properly structured and secure
      scriptPubKeys:
          utxo.map((e) => e.ownerDetails.address.toScriptPubKey()).toList(),
      amounts: utxo.map((e) => e.utxo.value).toList(),

      sighash: BitcoinOpCodeConst.sighashDefault,
    );

    // sign transaction using `signBip340` method of thransaction
    final signedTx =
        sign(txDigit, utxo[i].public().toHex(), BitcoinOpCodeConst.sighashAll);

    // add witness for current index
    witnesses.add(TxWitnessInput(stack: [signedTx]));
  }
  tx = tx.copyWith(witnesses: witnesses);

  return tx;
}
