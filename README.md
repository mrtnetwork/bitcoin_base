# Bitcoin Dart Package

A comprehensive Bitcoin library for Dart that provides functionality to create, sign, and send Bitcoin transactions. This library supports a wide range of Bitcoin transaction types and features, making it suitable for various use cases.

## Features

- Create and sign Bitcoin transactions
- Addresses
  - Legacy Keys and Addresses (P2PK, P2PKH, P2SH)
  - Segwit Addresses (P2WPKH, P2SH-P2WPKH, P2WSH and P2SH-P2WSH, Taproot (segwit v1))
- Support for different transaction types:
  - Legacy transactions (P2PKH, P2SH)
      - Transaction with P2PKH input and outputs
      - Create a P2PKH Transaction with different SIGHASHes
      - Create a P2SH Address
      - Create (spent) a P2SH Transaction
- Segwit Transactions
  - Transaction to pay to a P2WPKH
  - Spend from a P2SH(P2WPKH) nested segwit address
- Timelock Transactions
  - Create a P2SH address with a relative timelock
  - Spend from a timelocked address
- Taproot (segwit v1) Transactions
  - Spend from a taproot address
  - Spend a multi input that contains both taproot and legacy UTXOs
  - Send to taproot address that contains a single script path spend
  - Spend taproot from key path (has single alternative script path spend)
  - Spend taproot from script path (has single alternative script path spend)
  - Send to taproot address that contains two scripts path spends
  - Send to taproot address that contains three scripts path spends
- Sign
  - sign message
  - sign transactions
  - Schnorr sign (segwit transactions)
  - support different `sighash`
  - get public key of signature

## Example
A large number of examples and tests have been prepared you can see them in the [test folder](https://github.com/MohsenHaydari/bitcoin/tree/main/test)

- Keys and addresses
```
      // private key
      final prive = ECPrivate.fromWif("");
      prive.signMessage(message) // sign message
      prive.signInput(txDigest) // sign legacy and segwit 
      prive.signTapRoot(txDigest) // sign taprot 
      prive.getPublic() // public key

      // publick key
      final public = prive.getPublic();
      public.verify(message, signature); // verify message
      ECPublic.getSignaturPublic(message, signatur) // get public of signatur
      public.toAddress(); // P2pkhAddress
      public.toSegwitAddress(); // P2wpkhAddress  addres
      final script = Script(script: [public.toHex(), 'OP_CHECKSIG']);
      final addr = P2shAddress(script: script); // p2sh address
      ....
      final script = Script(script: [
        'OP_1',
        prive.getPublic().toHex(),
        'OP_1',
        'OP_CHECKMULTISIG'
      ]);
      final pw = P2wshAddress(script: script); // p2wsh addres
      final addr = public.toTaprootAddress(); // taproot addres
  
```
- spend P2PK/P2PKH
  
```
  final txin = utxo.map((e) => TxInput(txId: e.txId, txIndex: e.vout)).toList(); // p2pk UTXO
  final List<TxOutput> txOut = [
    TxOutput(
        amount: value,
        scriptPubKey: Script(script: receiver.toScriptPubKey()))
  ];
  if (hasChanged) {
    txOut.add(TxOutput(
        amount: changedValue,
        scriptPubKey: Script(script: senderAddress.toScriptPubKey())));
  }
  final tx = BtcTransaction(inputs: txin, outputs: txOut);
  for (int i = 0; i < txin.length; i++) {
    final sc = senderPub.toRedeemScript();
    final txDigit =
        tx.getTransactionDigit(txInIndex: i, script: sc, sighash: sighash);
    final signedTx = prive.signInput(txDigit, sighash);
    txin[i].scriptSig = Script(script: [signedTx]);
  }
  tx.serialize(); // ready for broadcast
  
```
- spend P2PKH/P2WKH
  
```
  final txin = utxo.map((e) => TxInput(txId: e.txId, txIndex: e.vout)).toList(); // P2PKH UTXO
  final List<TxOutput> txOut = [
    TxOutput(
        amount: value,
        scriptPubKey: Script(script: receiver.toScriptPubKey()))
  ];
  if (hasChanged) {
    final senderAddress = senderPub.toAddress();
    txOut.add(TxOutput(
        amount: changedValue,
        scriptPubKey: Script(script: senderAddress.toScriptPubKey()))); // changed address
  }
  final tx = BtcTransaction(inputs: txin, outputs: txOut, hasSegwit: false);
  for (int b = 0; b < txin.length; b++) {
    final txDigit = tx.getTransactionDigit(
        txInIndex: b,
        script: Script(script: senderPub.toAddress().toScriptPubKey()),
        sighash: sighash);
    final signedTx = sign(txDigit, sigHash: sighash);
    txin[b].scriptSig = Script(script: [signedTx, senderPub.toHex()]);
  }
  tx.serialize(); // ready for broadcast
  
```
- spend P2WKH/P2SH
  
```
  final txin = utxo.map((e) => TxInput(txId: e.txId, txIndex: e.vout)).toList(); // p2wkh utxo
  final List<TxWitnessInput> w = [];
  final List<TxOutput> txOut = [
    TxOutput(
        amount: value,
        scriptPubKey: receiver.toRedeemScript().toP2shScriptPubKey())
  ];
  if (hasChanged) {
    txOut.add(TxOutput(
        amount: changedValue,
        scriptPubKey:
            Script(script: senderPub.toSegwitAddress().toScriptPubKey()))); // changed address
  }
  final tx = BtcTransaction(inputs: txin, outputs: txOut, hasSegwit: true);
  for (int i = 0; i < txin.length; i++) {
    // get segwit transaction digest
    final txDigit = tx.getTransactionSegwitDigit(
        txInIndex: i,
        script: Script(script: senderPub.toAddress().toScriptPubKey()),
        sighash: sighash,
        amount: utxo[i].value);
    final signedTx = sign(txDigit,sighas);
    w.add(TxWitnessInput(stack: [signedTx, senderPub.toHex()]));
  }
  tx.witnesses.addAll(w);
  tx.serialize(); // ready for broadcast
  
```

## Contributing

Contributions are welcome! Please follow these guidelines:
 - Fork the repository and create a new branch.
 - Make your changes and ensure tests pass.
 - Submit a pull request with a detailed description of your changes.

## Feature requests and bugs #

Please file feature requests and bugs in the issue tracker.

