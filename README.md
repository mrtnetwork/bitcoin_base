# Bitcoin Dart Package

A comprehensive Bitcoin library for Dart that provides functionality to create, sign, and send Bitcoin transactions. This library supports a wide range of Bitcoin transaction types and features, making it suitable for various use cases.

## Features

- Create and sign Bitcoin transactions
- Addresses
  - Legacy Keys and Addresses (P2PK, P2PKH, P2SH)
  - Segwit Addresses (P2WPKH, P2SH-P2WPKH, P2WSH and P2SH-P2WSH, Taproot (segwit v1))
- Support for different transaction types:
  - Legacy transactions (P2PKH, P2SH(P2PK), P2SH(P2PKH) )
      - Transaction with P2PKH input and outputs
      - Create a P2PKH Transaction with different SIGHASHes
      - Create a P2SH Address
      - Create (spent) a P2SH Transaction
- Segwit Transactions
  - Transaction to pay to a P2WPKH, P2WSH, P2SH(segwit)
  - Spend from a P2SH(P2WPKH) nested segwit address
  - Spend from a P2SH(P2WSH) nested segwit address
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
      final mn = BIP39.generateMnemonic();

      /// accsess to private and public keys
      final masterWallet = HdWallet.fromMnemonic(mn);
      HdWallet.fromXPrivateKey(masterWallet.toXpriveKey());

      /// sign legacy and segwit transaction
      masterWallet.privateKey.signInput(txDigest);

      /// sign taproot transaction
      masterWallet.privateKey.signTapRoot(txDigest);

      /// sign message
      masterWallet.privateKey.signMessage(txDigest);

      /// tprv8ZgxMBicQKsPdEtasyf3Qc1vAycp7pVSf6oAcnN4XAeYuntXsUargabb3Rcdo78YKzAxARfVLah4nfkUfYDrWodRWA9YEstwSrV5ZNvApvt
      masterWallet.toXpriveKey(network: NetworkInfo.TESTNET);

      /// accsess to publicKey
      /// tpubD6NzVbkrYhZ4WhvNmdKdp1g2k18kH9gMEQPwuJQMwSSwkH9JVsQSs5DTDZKeJTiTvLinuTwdL4zf6CJAWE79VwhxHn9tDcq33Xj7BgLKZEH
      final xPublic = masterWallet.toXpublicKey(network: NetworkInfo.TESTNET);
      final publicMasterWallet = HdWallet.fromXpublicKey(xPublic);

      /// derive new path from master wallet
      HdWallet.drivePath(masterWallet, "m/44'/0'/0'/0/0/0");

      /// derive new path from public wallet
      final publicWallet = HdWallet.drivePath(publicMasterWallet, "m/0/1");

      final publicKey = publicWallet.publicKey;

      /// return public key
      publicKey.toHex(compressed: true);

      /// p2pkh address for testnet network
      /// mxukNgWdBF1ibtpCpnNnPR5Zz2FPjvyuCf
      publicKey.toAddress().toAddress(NetworkInfo.TESTNET);

      /// p2sh(p2pk) address for testnet network
      /// 2NE2r3EK7fFYZREaNFVLyEw2UcEUEGjVgF2
      publicKey.toP2pkInP2sh().toAddress(NetworkInfo.TESTNET);

      /// p2sh(p2pkh) address for testnet network
      /// 2MyaJKV4g1R5pWA4LC16pqVqDFtGrn134nP
      publicKey.toP2pkhInP2sh().toAddress(NetworkInfo.TESTNET);

      /// p2sh(p2wpkh) address for testnet network
      /// 82VHvngNBzjXsb5ZUqHD5hgXKdUdstLsA
      publicKey.toP2wpkhInP2sh().toAddress(NetworkInfo.TESTNET);

      /// p2sh(p2wsh) address for testnet network 1-1 multisig segwit script
      /// JuynVHdGZY362FodskamvvWSP9Jj58KgA
      publicKey.toP2wshInP2sh().toAddress(NetworkInfo.TESTNET);

      /// p2wpkh address
      /// tb1qhmyuz38dy22qlspdnwl6khsycvjpeallzwwcp7
      publicKey.toSegwitAddress().toAddress(NetworkInfo.TESTNET);

      /// p2wsh address 1-1 multisig segwit script
      /// tb1qax8ahkqhm2cvappkdqupjp7w07ervya3rllpechnez6j7hzu7hqq963clk
      publicKey.toP2wshAddress().toAddress(NetworkInfo.TESTNET);

      /// p2tr address
      /// tb1p6hwljzyudccfd3d9ckrh5wqmx786kenmu0caud0ru6e3k2yc5rdq76sw7y
      publicKey.toTaprootAddress().toAddress(NetworkInfo.TESTNET);
  
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

