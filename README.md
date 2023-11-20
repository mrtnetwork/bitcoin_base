# BITCOIN Dart Package
a comprehensive and versatile Dart library for all your Bitcoin transaction needs. offers robust support for various Bitcoin transaction types, including spending transactions, Bitcoin address management, Bitcoin Schnorr signatures, BIP-39 mnemonic phrase generation, hierarchical deterministic (HD) wallet derivation, and Web3 Secret Storage Definition.

For BIP32 HD wallet, BIP39, and Secret storage definitions, please refer to the [blockchain_utils](https://github.com/mrtnetwork/blockchain_utils) package.

This package was inspired by the [python-bitcoin-utils](https://github.com/karask/python-bitcoin-utils) package and turned into Dart

## Features

### Transaction Types
This comprehensive package provides robust support for a wide array of Bitcoin transaction types, encompassing the full spectrum of Bitcoin transaction capabilities. Whether you need to execute standard payments, facilitate complex multi-signature wallets, leverage Segregated Witness (SegWit) transactions for lower fees and enhanced scalability, or embrace the privacy and flexibility of Pay-to-Taproot (P2TR) transactions, this package has you covered. Additionally, it empowers users to engage in legacy transactions, create time-locked transactions, and harness the security of multisignature (multisig) transactions. With this package, you can seamlessly navigate the diverse landscape of Bitcoin transactions, ensuring your interactions with the Bitcoin network are secure, efficient, and tailored to your specific needs.

- P2PKH (Pay-to-Public-Key-Hash): The most common transaction type, it sends funds to a recipient's public key hash. Provides security and anonymity.

- P2SH (Pay-to-Script-Hash): Allows more complex scripts to be used, enhancing Bitcoin's capabilities by enabling features like multisignature wallets.

- P2WPKH (Pay-to-Witness-Public-Key-Hash): A Segregated Witness (SegWit) transaction type, it offers reduced fees and improved scalability while maintaining compatibility.

- P2WSH (Pay-to-Witness-Script-Hash): Another SegWit transaction, it extends the benefits of SegWit to more complex script scenarios, reducing transaction size and fees.

- P2TR (Pay-to-Taproot): An upgrade aiming to improve privacy and flexibility, allowing users to choose between various scripts and enhance transaction efficiency.

- Legacy Transactions: Refers to older transaction types used before SegWit, with higher fees and less scalability.

- Multisignature (Multisig) Transactions: Involves multiple signatures to authorize a Bitcoin transaction, commonly used for security purposes in shared wallets.

- SegWit Transactions: A collective term for P2WPKH and P2WSH transactions, leveraging segregated witness data to reduce transaction size and fees.

- Time-Locked Transactions: These transactions have a predetermined time or block height before they can be spent, adding security and functionality to Bitcoin smart contracts.

- Coinbase Transactions: The first transaction in each block, generating new Bitcoins as a block reward for miners. It includes the miner's payout address.

### Create Transaction
Using this package, you can create a Bitcoin transaction in two ways: either through the `BtcTransaction` or the `BitcoinTransactionBuilder` class
- BtcTransaction: To use the `BtcTransaction` class, you should have a general understanding of how Bitcoin transactions work, including knowledge of UTXOs, scripts, various types of scripts, Bitcoin addresses, signatures, and more. We created examples and tests to enhance your understanding. An example of this transaction type is explained below, and you can also find numerous examples in the [`test`](https://github.com/mrtnetwork/bitcoin_base/tree/main/test) folder.

- BitcoinTransactionBuilder: Even with limited prior knowledge, you can utilize this class to send various types of transactions. Below, I've provided an example in which a transaction features 8 distinct input addresses with different types and private keys, as well as 10 different output addresses. Furthermore, additional examples have been prepared, which you can find in the [`example`](https://github.com/mrtnetwork/bitcoin_base/tree/main/example) folder.

### Addresses
- P2PKH A P2PKH (Pay-to-Public-Key-Hash) address in Bitcoin represents ownership of a cryptocurrency wallet by encoding a hashed public key
  
- P2WPKH: A P2WPKH (Pay-to-Witness-Public-Key-Hash) address in Bitcoin is a Segregated Witness (SegWit) address that enables more efficient and secure transactions by segregating witness data, enhancing network scalability and security.
  
- P2WSH: A P2WSH (Pay-to-Witness-Script-Hash) address in Bitcoin is a Segregated Witness (SegWit) address that allows users to spend bitcoins based on the conditions specified in a witness script, offering improved security and flexibility for complex transaction types.
  
- P2TR: A P2TR (Pay-to-Taproot) address in Bitcoin is a type of address that allows users to send and receive bitcoins using the Taproot smart contract, offering enhanced privacy and scalability features.
  
- P2SH: A P2SH (Pay-to-Script-Hash) address in Bitcoin is an address type that enables the use of more complex scripting, often associated with multi-signature transactions or other advanced smart contract functionality, enhancing flexibility and security.
  
- P2SH(SEGWIT): A P2SH (Pay-to-Script-Hash) Segregated Witness (SegWit) address in Bitcoin combines the benefits of P2SH and SegWit technologies, allowing for enhanced transaction security, reduced fees, and improved scalability.

### Sign
- Sign message: ECDSA Signature Algorithm
  
- Sign Segwit(v0) and legacy transaction: ECDSA Signature Algorithm
  
- Sign Taproot transaction
  
  - Script Path and TapTweak: Taproot allows for multiple script paths (smart contract conditions) to be included in a single transaction. The "taptweak" ensures that the correct 	 
    script path is used when spending. This enhances privacy by making it difficult to determine the spending conditions from the transaction.
    
  - Schnorr Signatures: While ECDSA is still used for Taproot, it also provides support for Schnorr signatures. Schnorr signatures offer benefits such as smaller signature sizes and 	 
    signature aggregation, contributing to improved scalability and privacy.
    
  - Schnorr-Musig: Taproot can leverage Schnorr-Musig, a technique for securely aggregating multiple signatures into a single signature. This feature enables collaborative spending and 
    enhances privacy.

### Node Provider
We have added two APIs (Mempool and BlockCypher) to the plugin for network access. You can easily use these two APIs to obtain information such as unspent transactions (UTXO), network fees, sending transactions, receiving transaction information, and retrieving account transactions.

## EXAMPLES

### Key and addresses
  - Private key
    ```
    // Create an EC private key instance from a WIF (Wallet Import Format) encoded string.
    final privateKey =
      ECPrivate.fromWif("cT33CWKwcV8afBs5NYzeSzeSoGETtAB8izjDjMEuGqyqPoF7fbQR", netVersion: BitcoinNetwork.mainnet.wifNetVer);

    // Retrieve the corresponding public key from the private key.
    final publicKey = privateKey.getPublic();

    // Sign an input using the private key.
    final signSegwitV0OrLagacy = privateKey.signInput();

    // Sign a Taproot transaction using the private key.
    final signSegwitV1TapprotTransaction = privateKey.signTapRoot();

    // Convert the private key to a WIF (Wallet Import Format) encoded string.
    // The boolean argument specifies whether to use the compressed format.
    final toWif = privateKey.toWif();

    // Convert the private key to its hexadecimal representation.
    final toHex = privateKey.toHex();
    ```
- Public key
  ```
  // Create an instance of an EC public key from a hexadecimal representation.
  final publicKey = ECPublic.fromHex('.....');

  // Generate a Pay-to-Public-Key-Hash (P2PKH) address from the public key.
  final p2pkh = publicKey.toAddress();

  // Generate a Pay-to-Witness-Public-Key-Hash (P2WPKH) Segregated Witness (SegWit) address from the public key.
  final p2wpkh = publicKey.toSegwitAddress();

  // Generate a Pay-to-Witness-Script-Hash (P2WSH) Segregated Witness (SegWit) address from the public key.
  final p2wsh = publicKey.toP2wshAddress();

  // Generate a Taproot address from the public key.
  final p2tr = publicKey.toTaprootAddress();

  // Generate a Pay-to-Public-Key-Hash (P2PKH) inside Pay-to-Script-Hash (P2SH) address from the public key.
  final p2pkhInP2sh = publicKey.toP2pkhInP2sh();

  // Generate a Pay-to-Witness-Public-Key-Hash (P2WPKH) inside Pay-to-Script-Hash (P2SH) address from the public key.
  final p2wpkhInP2sh = publicKey.toP2wpkhInP2sh();

  // Generate a Pay-to-Witness-Script-Hash (P2WSH) inside Pay-to-Script-Hash (P2SH) address from the public key.
  final p2wshInP2sh = publicKey.toP2wshInP2sh();

  // Generate a Pay-to-Public-Key (P2PK) inside Pay-to-Script-Hash (P2SH) address from the public key.
  final p2pkInP2sh = publicKey.toP2pkInP2sh();

  // Get the compressed bytes representation of the public key.
  final compressedBytes = publicKey.toCompressedBytes();

  // Get the uncompressed bytes representation of the public key.
  final unCompressedBytes = publicKey.toBytes();

  // Extract and return the x-coordinate (first 32 bytes) of the ECPublic key as a hexadecimal string.
  final onlyX = publicKey.toXOnlyHex();

  // Compute and return the Taproot commitment point's x-coordinate
  // derived from the ECPublic key and an optional script, represented as a hexadecimal string.
  final taproot = publicKey.toTapRotHex();

  // Verify verifies a signature against a message
  final verify = publicKey.verify();
  ```
- Addresses
  ```
  // If you also want to verify that the address belongs to a specific network,
  // please select the desired network using the parameters.
  // Generate a Pay-to-Public-Key-Hash (P2PKH) address from the public key.
  final p2pkh = P2pkhAddress(
      address: "1Q5odQtVCc4PDmP5ncrp7DSuVbh2ML4Gnb",
      network: BitcoinNetwork.mainnet);

  // Generate a Pay-to-Witness-Public-Key-Hash (P2WPKH) Segregated Witness (SegWit) address from the public key.
  final p2wpkh =
      P2wpkhAddress(address: "bc1ql5eh45als8sgdkt2drsl344q55g03sj2u9enzz");

  // Generate a Pay-to-Witness-Script-Hash (P2WSH) Segregated Witness (SegWit) address from the public key.
  final p2wsh = P2wshAddress(
      address:
          "bc1qf90kcg2ktg0wm983cyvhy0jsrj2fmqz26ugf5jz3uw68mtnr8ljsnf8pqe");

  // Generate a Taproot address from the public key.
  final p2tr = P2trAddress(
      address:
          "bc1pmelvn3xz2n3dmcsvk2k99na7kc55ry77zmhg4z39upry05myjthq37f6jk");

  // Generate a Pay-to-Public-Key-Hash (P2PKH) inside Pay-to-Script-Hash (P2SH) address from the public key.
  final p2pkhInP2sh =
      P2shAddress(address: "3HDtvvRMu3yKGFXYFSubTspbhbLagpdKJ7");

  // Generate a Pay-to-Witness-Public-Key-Hash (P2WPKH) inside Pay-to-Script-Hash (P2SH) address from the public key.
  final p2wpkhInP2sh =
      P2shAddress(address: "36Dq32LRMW8EJyD3T2usHaxeMBmUpsXhq2");

  // Generate a Pay-to-Witness-Script-Hash (P2WSH) inside Pay-to-Script-Hash (P2SH) address from the public key.
  final p2wshInP2sh =
      P2shAddress(address: "3PPL49fMytbEKJsjjPnkfWh3iWzrZxQZAg");

  // Generate a Pay-to-Public-Key (P2PK) inside Pay-to-Script-Hash (P2SH) address from the public key.
  final p2pkInP2sh = P2shAddress(address: "3NCe6AGzjz2jSyRKCc8o3Bg5MG6pUM92bg");

  // You can create any type of Bitcoin address with scripts.
  // Create an address with scripts for P2WSH multisig 3-of-5.
  final newScript = Script(script: [
    "OP_3",
    public1,
    public2,
    public3,
    public4,
    public5,
    "OP_5",
    "OP_CHECKMULTISIG"
  ]);

  // Generate a P2WSH 3-of-5 address.
  final p2wsh3of5Address = P2wshAddress(script: newScript);

  // Generate a P2SH 3-of-5 address from the P2WSH address.
  final p2sh3Of5 =
      P2shAddress.fromScript(script: p2wsh3of5Address.toScriptPubKey());

  // The method calculates the address checksum and returns the Base58-encoded
  // Bitcoin legacy address or the Bech32 format for SegWit addresses.
  p2sh3Of5.toAddress(BitcoinNetwork.mainnet);

  // Return the scriptPubKey that corresponds to this address.
  p2sh3Of5.toScriptPubKey();

  // Access the legacy or SegWit program of the address.
  p2sh3Of5.getH160;
  ```
  
### Transaction
- With TransactionBuilder
  ```
  // select network
  const BitcoinNetwork network = BitcoinNetwork.testnet;
  final service = BitcoinApiService();
  // select api for read accounts UTXOs and send transaction
  // Mempool or BlockCypher
  final api = ApiProvider.fromMempool(network, service);

  final mnemonic = Bip39SeedGenerator(Mnemonic.fromString(
          "spy often critic spawn produce volcano depart fire theory fog turn retire"))
      .generate();

  final bip32 = Bip32Slip10Secp256k1.fromSeed(mnemonic);

  // i generate 4 HD wallet for this test and now i have access to private and pulic key of each wallet
  final sp1 = bip32.derivePath("m/44'/0'/0'/0/0/1");
  final sp2 = bip32.derivePath("m/44'/0'/0'/0/0/2");
  final sp3 = bip32.derivePath("m/44'/0'/0'/0/0/3");
  final sp4 = bip32.derivePath("m/44'/0'/0'/0/0/4");

  // access to private key `ECPrivate`
  final private1 = ECPrivate.fromBytes(sp1.privateKey.raw);
  final private2 = ECPrivate.fromBytes(sp2.privateKey.raw);
  final private3 = ECPrivate.fromBytes(sp3.privateKey.raw);
  final private4 = ECPrivate.fromBytes(sp4.privateKey.raw);

  // access to public key `ECPublic`
  final public1 = private1.getPublic();
  final public2 = private2.getPublic();
  final public3 = private3.getPublic();
  final public4 = private4.getPublic();

  // P2PKH ADDRESS
  final exampleAddr1 = public1.toAddress();
  // P2TR
  final exampleAddr2 = public2.toTaprootAddress();
  // P2PKHINP2SH
  final exampleAddr3 = public2.toP2pkhInP2sh();
  // P2KH
  final exampleAddr4 = public3.toAddress();
  // P2PKHINP2SH
  final exampleAddr5 = public3.toP2pkhInP2sh();
  // P2WSHINP2SH 1-1 multisig
  final exampleAddr6 = public3.toP2wshInP2sh();
  // P2WPKHINP2SH
  final exampleAddr7 = public3.toP2wpkhInP2sh();
  // P2PKINP2SH
  final exampleAddr8 = public4.toP2pkInP2sh();
  // P2WPKH
  final exampleAddr9 = public3.toSegwitAddress();
  // P2WSH 1-1 multisig
  final exampleAddr10 = public3.toP2wshAddress();

  // Spending List
  // i use some different address type for this
  // now i want to spending from 8 address in one transaction
  // we need publicKeys and address
  final spenders = [
    UtxoAddressDetails(publicKey: public1.toHex(), address: exampleAddr1),
    UtxoAddressDetails(publicKey: public2.toHex(), address: exampleAddr2),
    UtxoAddressDetails(publicKey: public3.toHex(), address: exampleAddr7),
    UtxoAddressDetails(publicKey: public3.toHex(), address: exampleAddr9),
    UtxoAddressDetails(publicKey: public3.toHex(), address: exampleAddr10),
    UtxoAddressDetails(publicKey: public2.toHex(), address: exampleAddr3),
    UtxoAddressDetails(publicKey: public4.toHex(), address: exampleAddr8),
    UtxoAddressDetails(publicKey: public3.toHex(), address: exampleAddr4),
  ];

  // i need now to read spenders account UTXOS
  final List<UtxoWithOwner> utxos = [];

  // i add some method for provider to read utxos from mempool or blockCypher
  // looping address to read Utxos
  for (final spender in spenders) {
    try {
      // read each address utxo from mempool
      final spenderUtxos = await api.getAccountUtxo(spender);
      // check if account have any utxo for spending (balance)
      if (!spenderUtxos.canSpend()) {
        // address does not have any satoshi for spending:
        continue;
      }

      utxos.addAll(spenderUtxos);
    } on Exception {
      // something bad happen when reading Utxos:
      return;
    }
  }
  // Well, now we calculate how much we can spend
  final sumOfUtxo = utxos.sumOfUtxosValue();
  // 1,224,143 sum of all utxos

  final hasSatoshi = sumOfUtxo != BigInt.zero;

  if (!hasSatoshi) {
    // Are you kidding? We don't have btc to spend
    return;
  }

  // In the 'p2wsh_multi_sig_test' example, I have provided a comprehensive
  // explanation of how to determine the transaction fee
  // before creating the original transaction.

  // We consider 50,003 satoshi for the cost
  final fee = BigInt.from(50003);

  // now we have 1,174,140 satoshi for spending let do it
  // we create 10 different output with  different address type like (pt2r, p2sh(p2wpkh), p2sh(p2wsh), p2pkh, etc.)
  // We consider the spendable amount for 10 outputs and divide by 10, each output 117,414
  final output1 =
      BitcoinOutput(address: exampleAddr4, value: BigInt.from(117414));
  final output2 =
      BitcoinOutput(address: exampleAddr9, value: BigInt.from(117414));
  final output3 =
      BitcoinOutput(address: exampleAddr10, value: BigInt.from(117414));
  final output4 =
      BitcoinOutput(address: exampleAddr1, value: BigInt.from(117414));
  final output5 =
      BitcoinOutput(address: exampleAddr3, value: BigInt.from(117414));
  final output6 =
      BitcoinOutput(address: exampleAddr2, value: BigInt.from(117414));
  final output7 =
      BitcoinOutput(address: exampleAddr7, value: BigInt.from(117414));
  final output8 =
      BitcoinOutput(address: exampleAddr8, value: BigInt.from(117414));
  final output9 =
      BitcoinOutput(address: exampleAddr5, value: BigInt.from(117414));
  final output10 =
      BitcoinOutput(address: exampleAddr6, value: BigInt.from(117414));

  // Well, now it is clear to whom we are going to pay the amount
  // Now let's create the transaction
  final transactionBuilder = BitcoinTransactionBuilder(
    // Now, we provide the UTXOs we want to spend.
    utxos: utxos,
    // We select transaction outputs
    outPuts: [
      output1,
      output2,
      output3,
      output4,
      output5,
      output6,
      output7,
      output8,
      output9,
      output10
    ],
    /*
			Transaction fee
			Ensure that you have accurately calculated the amounts.
			If the sum of the outputs, including the transaction fee,
			does not match the total amount of UTXOs,
			it will result in an error. Please double-check your calculations.
		*/
    fee: fee,
    // network, testnet, mainnet
    network: network,
    // If you like the note write something else and leave it blank
    // I will put my GitHub address here
    memo: "https://github.com/mrtnetwork",
    /*
			RBF, or Replace-By-Fee, is a feature in Bitcoin that allows you to increase the fee of an unconfirmed
			transaction that you've broadcasted to the network.
			This feature is useful when you want to speed up a
			transaction that is taking longer than expected to get confirmed due to low transaction fees.
		*/
    enableRBF: true,
  );

  // now we use BuildTransaction to complete them
  // I considered a method parameter for this, to sign the transaction

  // parameters
  // utxo  infos with owner details
  // trDigest transaction digest of current UTXO (must be sign with correct privateKey)
  final transaction =
      transactionBuilder.buildTransaction((trDigest, utxo, publicKey) {
    late ECPrivate key;

    // ok we have the public key of the current UTXO and we use some conditions to find private  key and sign transaction
    String currentPublicKey = publicKey;

    // if is multi-sig and we dont have access to some private key of address we return empty string
    // Note that you must have access to keys with the required signature(threshhold) ; otherwise,
    // you will receive an error.
    if (utxo.isMultiSig()) {
      // check we have private keys of this sigerns or not
      // return ""
    }

    if (currentPublicKey == public3.toHex()) {
      key = private3;
    } else if (currentPublicKey == public2.toHex()) {
      key = private2;
    } else if (currentPublicKey == public1.toHex()) {
      key = private1;
    } else if (currentPublicKey == public4.toHex()) {
      key = private4;
    } else {
      throw Exception("Cannot find private key");
    }

    // Ok, now we have the private key, we need to check which method to use for signing
    // We check whether the UTX corresponds to the P2TR address or not.
    if (utxo.utxo.isP2tr()) {
      // yes is p2tr utxo and now we use SignTaprootTransaction(Schnorr sign)
      // for now this transaction builder support only tweak transaction
      // If you want to spend a Taproot tapleaf script-path spending, you must create your own transaction builder.
      return key.signTapRoot(trDigest);
    } else {
      // is seqwit(v0) or lagacy address we use  SingInput (ECDSA)
      return key.signInput(trDigest);
    }
  });

  // ok everything is fine and we need a transaction output for broadcasting
  // We use the Serialize method to receive the transaction output
  final digest = transaction.serialize();

  // we check if transaction is segwit or not
  // When one of the input UTXO addresses is SegWit, the transaction is considered SegWit.
  final isSegwitTr = transactionBuilder.hasSegwit();

  // transaction id
  final transactionId = transaction.txId();

  // transaction size
  int transactionSize;

  if (isSegwitTr) {
    transactionSize = transaction.getVSize();
  } else {
    transactionSize = transaction.getSize();
  }

  try {
    // now we send transaction to network
    // ignore: unused_local_variable
    final txId = await api.sendRawTransaction(digest);
    // Yes, we did :)  2625cd75f6576c38445deb2a9573c12ccc3438c3a6dd16fd431162d3f2fbb6c8
    // Now we check mempool for what happened https://mempool.space/testnet/tx/2625cd75f6576c38445deb2a9573c12ccc3438c3a6dd16fd431162d3f2fbb6c8
  } on Exception {
    // Something went wrong when sending the transaction
  }

  ```
- With BtcTransaction
  - Spend P2TR UTXO
    ```
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

    // For P2TR, P2WPKH, P2WSH, and P2SH(Segwit) transactions, we need to set 'hasSegwit' to true.
    final tx = BtcTransaction(inputs: txin, outputs: txOut, hasSegwit: true);

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

        // The tapleaf version script path when (extFlags=1)
        script: const Script(script: []),
        sighash: TAPROOT_SIGHASH_ALL,
        // default is 0; 1 is for tweak transacation
        extFlags: 0,
      );

      // sign transaction using `signTapRoot` method of thransaction
      final signedTx = sign(txDigit, utxo[i].public().toHex(), SIGHASH_ALL);

      // add witness for current index
      witnesses.add(TxWitnessInput(stack: [signedTx]));
    }
    // add all witness to transaction
    tx.witnesses.addAll(witnesses);
    // Transaction ID
    tx.TxId()

    // In this case, the transaction is segwit, and we must use GetVSize for transaction size
    tx.GetVSize()

    // Transaction digest ready for broadcast
    tx.Serialize()
    
    ```
  - Spend P2PKH UTXO
    ```
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
    // in this case P2pKH is not segwit and  we need to set 'hasSegwit' to false
    final tx = BtcTransaction(inputs: txin, outputs: txOut, hasSegwit: false);
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
      final signedTx = sign(txDigit, utxo[i].public().toHex(), SIGHASH_ALL);

      // set unlocking script for current index
      txin[i].scriptSig = Script(script: [signedTx, utxo[i].public().toHex()]);
    }
    ```
  
### Node provider
```

// Define the blockchain network you want to work with, in this case, it's Bitcoin.
  const network = BitcoinNetwork.mainnet;
// see the example_service.dart for how to create a http service.
final service = BitcoinApiService();

// Create an API provider instance for interacting with the BlockCypher API for the specified network.
  final api = ApiProvider.fromBlocCypher(network, service);

// Get the current network fee rate, which is essential for estimating transaction fees.
  final fee = await api.getNetworkFeeRate();

// Send a raw transaction represented by its transaction digest to the blockchain network.
  final transactionId = await api.sendRawTransaction("txDigest");

// Retrieve the Unspent Transaction Outputs (UTXOs) associated with a specific address.
  final utxo = await api.getAccountUtxo(address);

// Fetch information about a specific transaction using its transaction ID.
// For the Mempool API, use MempoolTransaction in the function template to receive the correct type.
  final transaction =
      await api.getTransaction<BlockCypherTransaction>(transactionId);

// Get a list of account transactions related to a specific address.
// For the Mempool API, use MempoolTransaction in the function template to receive the correct type.
  final accountTransactions =
      await api.getAccountTransactions<MempoolTransaction>('address');
```

## Contributing

Contributions are welcome! Please follow these guidelines:
 - Fork the repository and create a new branch.
 - Make your changes and ensure tests pass.
 - Submit a pull request with a detailed description of your changes.

## Feature requests and bugs #

Please file feature requests and bugs in the issue tracker.

## Support

If you find this repository useful, show us some love, and give us a star!
Small Bitcoin donations to the following address are also welcome:

bc1qz4pzpfpk82nn0e5wxl8k87a6psgamrjgpurhu42469vlhaa7z6yqn0fang

1wzyhtcLYgKA4ZjRX1Yn9UkKhCMnuVNsj

