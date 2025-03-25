# BITCOIN Dart Package

a comprehensive and versatile Dart library that provides robust support for various cryptocurrency transaction types. It is designed to meet your transaction needs for Bitcoin, Dogecoin, Litecoin, Dash, Bitcoin Cash and Bitcoin SV. The library offers features such as spending transactions, address management, Schnorr signatures for Bitcoin, BIP-39 mnemonic phrase generation, hierarchical deterministic (HD) wallet derivation, and Web3 Secret Storage Definition..

For BIP32 HD wallet, BIP39, and Secret storage definitions, please refer to the [blockchain_utils](https://github.com/mrtnetwork/blockchain_utils) package.

This package was inspired by the [python-bitcoin-utils](https://github.com/karask/python-bitcoin-utils) package and turned into Dart

## Features

### Supported Cryptocurrencies

- **Bitcoin**
  - P2PK, P2PKH, P2SH, P2WPKH, P2WSH, P2TR
- **Dogecoin**
  - P2PK, P2PKH, P2SH
- **Litecoin**
  - P2PK, P2PKH, P2SH, P2WPKH, P2WSH
- **Dash**
  - P2PK, P2PKH, P2SH
- **Bitcoin Cash**
  - P2PK, P2PKH, P2SH, P2SH32, Token-aware, CashTOKEN
- **Bitcoin SV**
  - P2PK, P2PKH

### Transaction Types

ss
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

### Tokens on Bitcoin Cash

CashTokens are digital assets that can be created and used on the global, decentralized Bitcoin Cash (BCH) network. These tokens can be issued by any person, organization, or decentralized application.

- Fungible tokens: Create, sign, spend, and burn.

- Non-fungible tokens: Create, sign, mint, send, and burn with multiple capabilities (none, mutable, minting).

- BCMR: Metadata Registries CHIP

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

### MuSig2 BIP-327: MuSig2 for BIP340-compatible Multi-Signatures
  You can find the examples here.

 - Sign/Verify: Supports signing and verifying multisignature transactions using MuSig2
 - NonceAgg: Aggregates nonces from multiple participants for secure signature generation.
 - KeyAgg: Combines multiple public keys into a single aggregated public key for efficient multisignature verification

### PSBT
  You can find the examples here.

- BIP-0174: Partially Signed Bitcoin Transaction Format
- BIP-0370: PSBT Version 2
- BIP-0371: Taproot Fields for PSBT
- BIP-0373: MuSig2 PSBT Fields

### Addresses specific to Bitcoin Cash

- P2SH32: Pay to Script Hash 32

- P2SH32WT: Pay to Script Hash 32 With Token

- P2PKHWT: Pay to Public Key Hash With Token

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

We have integrated three APIs—Mempool, BlockCypher, and Electrum—into the plugin to facilitate network access. These APIs enable seamless retrieval of information such as unspent transactions (UTXO), network fees, sending transactions, receiving transaction details, and fetching account transactions.

## EXAMPLES

### Key and addresses

- Private key

    ```dart
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

  ```dart
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

  ```dart
  final p2pkh = P2pkhAddress.fromAddress(
      address: "1Q5odQtVCc4PDmP5ncrp7DSuVbh2ML4Gnb",
      network: BitcoinNetwork.mainnet);

  /// Generate a Pay-to-Witness-Public-Key-Hash (P2WPKH) Segregated Witness (SegWit) address from the public key.
  final p2wpkh = P2wpkhAddress.fromAddress(
      address: "bc1ql5eh45als8sgdkt2drsl344q55g03sj2u9enzz",
      network: BitcoinNetwork.mainnet);

  /// Generate a Pay-to-Witness-Script-Hash (P2WSH) Segregated Witness (SegWit) address from the public key.
  final p2wsh = P2wshAddress.fromAddress(
      address: "bc1qf90kcg2ktg0wm983cyvhy0jsrj2fmqz26ugf5jz3uw68mtnr8ljsnf8pqe",
      network: BitcoinNetwork.mainnet);

  /// Generate a Taproot address from the public key.
  final p2tr = P2trAddress.fromAddress(
      address: "bc1pmelvn3xz2n3dmcsvk2k99na7kc55ry77zmhg4z39upry05myjthq37f6jk",
      network: BitcoinNetwork.mainnet);

  /// Generate a Pay-to-Public-Key-Hash (P2PKH) inside Pay-to-Script-Hash (P2SH) address from the public key.
  final p2sh = P2shAddress.fromAddress(
      address: "3HDtvvRMu3yKGFXYFSubTspbhbLagpdKJ7",
      network: BitcoinNetwork.mainnet);

  /// You can create any type of Bitcoin address with scripts.
  /// Create an address with scripts for P2WSH multisig 2-of-2.
  final newScript =
      Script(script: ["OP_2", public1, public2, "OP_2", "OP_CHECKMULTISIG"]);

  /// Generate a P2WSH 3-of-5 address.
  final p2wsh3of5Address = P2wshAddress.fromScript(script: newScript);

  /// Generate a P2SH 3-of-5 address from the P2WSH address.
  final p2sh3Of5 =
      P2shAddress.fromScript(script: p2wsh3of5Address.toScriptPubKey());

  /// Implemented classes for each network to better manage network-specific addresses.
  /// Integrated these classes to eliminate the necessity of using the main class and type for each address.
  final bitcoinAddress = BitcoinAddress(
      "tb1qg07pp4w4q6mzv2uh6n7f32tjq3g2uduwt70krjf0m75xgv9xtmwsp27wuw",
      network: BitcoinNetwork.testnet);

  /// access to `BitcoinBaseAddress`
  final baseAddress = bitcoinAddress.baseAddress;

  /// type of address
  final type = bitcoinAddress.type;

  final litecoin = LitecoinAddress("QQ2nmQTtA4eckgQNhmo7hGERpkBSzffWXK",
      network: LitecoinNetwork.testnet);

  /// BCH/P2PKH
  final bch = BitcoinCashAddress(
      "bchtest:qqddwd05aw9etm4pwcmgh5favujyy8uhuu5ypwyh6p",
      network: BitcoinCashNetwork.testnet);

  /// BCH/P2SH32
  final bchp2sh32 = BitcoinCashAddress(
      "bchtest:p04ycd9t3pr25jte9tl0vhlamnqqxdhkep6qenrj4fazg4qlxaxevfgeknvm9",
      network: BitcoinCashNetwork.testnet);

  /// BCH/P2SH32WT 
  final bchp2sh32wt = BitcoinCashAddress(
      "bchtest:r0nxrdjg297tup5gfe6307mh6u94rn3mnzcq6znepym2ju6ne7ae7kpu9hw64",
      network: BitcoinCashNetwork.testnet);

  final dash = DashAddress("Xqzs7FnTLc5PqEKWQXjvBLhjC7nMeofkUn",
      network: DashNetwork.mainnet);

  final doge = DogeAddress("DMovt5M6umoXzs95XNQWSHrHKP5RPwtsJA",
      network: DogecoinNetwork.mainnet);

  final bitcoinSV = BitcoinSVAddress("15ATt31qva5gkpa6e7ux3if5YSACiAx7s4",
      network: BitcoinSVNetwork.mainnet);
      
  ```
  
### Transaction

In the [example](https://github.com/mrtnetwork/bitcoin_base/tree/main/example/lib) folder, you'll find various examples tailored for each supported network, including Bitcoin, Dogecoin, Litecoin, Bitcoin Cash, and Dash.

- With TransactionBuilder
  BitcoinTransactionBuilder

  supports the Bitcoin, Dogecoin, Dash, and Litecoin networks, allowing for easy creation and signing of various address types.

  ```dart
  /// connect to electrum service with websocket
  /// please see `services_examples` folder for how to create electrum websocket service
   final service =
      await ElectrumWebSocketService.connect("184....");

  /// create provider with service
  final provider = ElectrumProvider(service);

  /// spender details
  final privateKey = ECPrivate.fromHex(
      "76257aafc9b954351c7f6445b2d07277f681a5e83d515a1f32ebf54989c2af4f");
  final examplePublicKey = privateKey.getPublic();
  final spender1 = examplePublicKey.toAddress();
  final spender2 = examplePublicKey.toSegwitAddress();
  final spender3 = examplePublicKey.toTaprootAddress();
  final spender4 = examplePublicKey.toP2pkhInP2sh();
  final spender5 = examplePublicKey.toP2pkInP2sh();
  final spender6 = examplePublicKey.toP2wshAddress();
  final spender7 = examplePublicKey.toP2wpkhInP2sh();
  final List<BitcoinBaseAddress> spenders = [
    spender1,
    spender2,
    spender3,
    spender4,
    spender5,
    spender6,
    spender7,
  ];

  const network = BitcoinNetwork.testnet;
  final List<UtxoWithAddress> accountsUtxos = [];

  /// loop each spenders address and get utxos and add to accountsUtxos
  for (final i in spenders) {
    /// Reads all UTXOs (Unspent Transaction Outputs) associated with the account
    final elctrumUtxos = await provider
        .request(ElectrumRequestScriptHashListUnspent(scriptHash: i.pubKeyHash()));

    /// Converts all UTXOs to a list of UtxoWithAddress, containing UTXO information along with address details.
    /// read spender utxos
    final List<UtxoWithAddress> utxos = elctrumUtxos
        .map((e) => UtxoWithAddress(
            utxo: e.toUtxo(i.type),
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey.toHex(), address: i)))
        .toList();
    accountsUtxos.addAll(utxos);
  }

  /// get sum of values
  final sumOfUtxo = accountsUtxos.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    return;
  }

  final examplePublicKey2 = ECPublic.fromHex(
      "02d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546");

  /// When creating outputs with an address, I utilize the public key. Alternatively, an address class, such as
  /// P2pkhAddress.fromAddress(address: ".....", network: network);
  /// P2trAddress.fromAddress(address: "....", network: network)
  /// ....
  final List<BitcoinOutput> outPuts = [
    BitcoinOutput(
        address: examplePublicKey2.toSegwitAddress(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey2.toTaprootAddress(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey2.toP2pkhInP2sh(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey2.toP2pkInP2sh(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey2.toP2wshAddress(),
        value: BtcUtils.toSatoshi("0.00001")),
  ];

  /// OP_RETURN
  const String memo = "https://github.com/mrtnetwork";

  /// SUM OF OUTOUT AMOUNTS
  final sumOfOutputs = outPuts.fold(
      BigInt.zero, (previousValue, element) => previousValue + element.value);

  /// Estimate transaction size
  int transactionSize = BitcoinTransactionBuilder.estimateTransactionSize(
      utxos: accountsUtxos,
      outputs: [
        ...outPuts,

        /// I add more output for change value to get correct transaction size
        BitcoinOutput(
            address: examplePublicKey2.toAddress(), value: BigInt.zero)
      ],

      /// network
      network: network,

      /// memp
      memo: memo,

      /// rbf
      enableRBF: true);

  /// get network fee esmtimate (fee per kilobyte)
  final networkEstimate = await provider.request(ElectrumEstimateFee());

  /// Convert kilobytes to bytes, multiply by the transaction size, and the result yields the transaction fees.
  final fee =
      BigInt.from(transactionSize) * (networkEstimate ~/ BigInt.from(1000));

  /// change value
  final changeValue = sumOfUtxo - (sumOfOutputs + fee);

  if (changeValue.isNegative) {
    return;
  }
  //// if we have change value we back amount to account
  if (changeValue > BigInt.zero) {
    outPuts.add(BitcoinOutput(
        address: examplePublicKey2.toAddress(), value: changeValue));
  }

  /// create transaction builder
  final builder = BitcoinTransactionBuilder(
      outPuts: outPuts,
      fee: fee,
      network: network,
      utxos: accountsUtxos,
      memo: memo,
      inputOrdering: BitcoinOrdering.bip69,
      outputOrdering: BitcoinOrdering.bip69,
      enableRBF: true);

  /// create transaction and sign it
  final transaction =
      builder.buildTransaction((trDigest, utxo, publicKey, sighash) {
    if (utxo.utxo.isP2tr()) {
      return privateKey.signTapRoot(trDigest, sighash: sighash);
    }
    return privateKey.signInput(trDigest, sigHash: sighash);
  });

  /// get tx id
  transaction.txId();

  /// get transaction encoded data
  final raw = transaction.serialize();

  /// send to network
  await provider.request(ElectrumRequestBroadCastTransaction(transactionRaw: raw));

  /// Once completed, we verify the status by checking the mempool or using another explorer to review the transaction details.
  /// https://mempool.space/testnet/tx/70cf664bba4b5ac9edc6133e9c6891ffaf8a55eaea9d2ac99aceead1c3db8899

  ```

- With ForkedTransactionBuilder

  ForkedTransactionBuilder supports the BitcoinCash and bitcoinSV for easy creation and signing of various address types.
  For spending network amounts, it functions similarly to TransactionBuilder. However, in this example, the focus is on spending CashToken (BCH Feature). For minting, burning, and creating FTs (Fungible Tokens) and NFTs (Non-Fungible Tokens), you can refer to the [example folders](https://github.com/mrtnetwork/bitcoin_base/tree/main/example/lib/bitcoin_cash)
  
  ```dart
  /// connect to electrum service with websocket
  /// please see `services_examples` folder for how to create electrum websocket service
  final service = await ElectrumWebSocketService.connect(
      "wss://chipnet.imaginary.cash:50004");

  /// create provider with service
  final provider = ElectrumProvider(service);

  /// initialize private key
  final privateKey = ECPrivate.fromBytes(BytesUtils.fromHexString(
      "f9061c5cb343c6b6a73900ee29509bb0bd2213319eea46d2f2a431068c9da06b"));

  /// public key
  final publicKey = privateKey.getPublic();

  /// network
  const network = BitcoinCashNetwork.testnet;

  /// Derives a P2PKH address from the given public key and converts it to a Bitcoin Cash address
  /// for enhanced accessibility within the network.
  final p2pkhAddress = BitcoinCashAddress.fromBaseAddress(
      publicKey.toP2pkInP2sh(useBCHP2sh32: true));

  /// p2pkh with token address ()
  final receiver1 = P2pkhAddress.fromHash160(
      addrHash: publicKey.toAddress().addressProgram,
      type: P2pkhAddressType.p2pkhwt);

  /// Reads all UTXOs (Unspent Transaction Outputs) associated with the account.
  /// We does not need tokens utxo and we set to false.
  final elctrumUtxos = await provider.request(ElectrumRequestScriptHashListUnspent(
    scriptHash: p2pkhAddress.baseAddress.pubKeyHash(),
    includeTokens: true,
  ));

  /// Converts all UTXOs to a list of UtxoWithAddress, containing UTXO information along with address details.
  final List<UtxoWithAddress> utxos = elctrumUtxos
      .map((e) => UtxoWithAddress(
          utxo: e.toUtxo(p2pkhAddress.type),
          ownerDetails: UtxoAddressDetails(
              publicKey: publicKey.toHex(), address: p2pkhAddress.baseAddress)))
      .toList()

      /// we only filter the utxos for this token or none token utxos
      .where((element) =>
          element.utxo.token?.category ==
              "4e7873d4529edfd2c6459139257042950230baa9297f111b8675829443f70430" ||
          element.utxo.token == null)
      .toList();

  /// som of utxos in satoshi
  final sumOfUtxo = utxos.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    return;
  }

  /// CashToken{bitfield: 16, commitment: null, amount: 2000, category: 4e7873d4529edfd2c6459139257042950230baa9297f111b8675829443f70430}
  final CashToken token = elctrumUtxos
      .firstWhere((e) =>
          e.token?.category ==
          "4e7873d4529edfd2c6459139257042950230baa9297f111b8675829443f70430")
      .token!;

  /// sum of ft token amounts with category "4e7873d4529edfd2c6459139257042950230baa9297f111b8675829443f70430"
  final sumofTokenUtxos = utxos
      .where((element) =>
          element.utxo.token?.category ==
          "4e7873d4529edfd2c6459139257042950230baa9297f111b8675829443f70430")
      .fold(
          BigInt.zero,
          (previousValue, element) =>
              previousValue + element.utxo.token!.amount);

  final bchTransaction = ForkedTransactionBuilder(
    outPuts: [
      /// change address for bch values (sum of bch amout - (outputs amount + fee))
      BitcoinOutput(
        address: p2pkhAddress.baseAddress,
        value: sumOfUtxo -
            (BtcUtils.toSatoshi("0.00002") + BtcUtils.toSatoshi("0.00003")),
      ),
      BitcoinTokenOutput(
          utxoHash: utxos.first.utxo.txHash,
          address: receiver1,

          /// for a token-bearing output (600-700) satoshi
          /// hard-coded value which is expected to be enough to allow
          /// all conceivable token-bearing UTXOs (1000 satoshi)
          value: BtcUtils.toSatoshi("0.00001"),

          /// clone the token with new token amount for output1 (15 amount of category)
          token: token.copyWith(amount: BigInt.from(15))),

      /// another change token value to change account like bch
      BitcoinTokenOutput(
          utxoHash: utxos.first.utxo.txHash,
          address: p2pkhAddress.baseAddress,

          /// for a token-bearing output (600-700) satoshi
          /// hard-coded value which is expected to be enough to allow
          /// all conceivable token-bearing UTXOs (1000 satoshi)
          value: BtcUtils.toSatoshi("0.00001"),

          /// clone the token with new token amount for change output
          token: token.copyWith(amount: sumofTokenUtxos - BigInt.from(15))),
    ],
    fee: BtcUtils.toSatoshi("0.00003"),
    network: network,
    utxos: utxos,
  );
  final transaaction =
      bchTransaction.buildTransaction((trDigest, utxo, publicKey, sighash) {
    return privateKey.signInput(trDigest, sigHash: sighash);
  });

  /// transaction ID
  transaaction.txId();

  /// for calculation fee
  transaaction.getSize();

  /// raw of encoded transaction in hex
  final transactionRaw = transaaction.toHex();

  /// send transaction to network
  await provider
      .request(ElectrumRequestBroadCastTransaction(transactionRaw: transactionRaw));

  /// done! check the transaction in block explorer
  ///  https://chipnet.imaginary.cash/tx/97030c1236a024de7cad7ceadf8571833029c508e016bcc8173146317e367ae6

  ```

- With BtcTransaction
  - Spend P2TR UTXO

    ```dart
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

    ```dart
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

I haven't implemented any specific HTTP service or socket service within this plugin. The reason is that different applications may use various plugins or methods to interact with network protocols. However, I have included numerous examples to demonstrate how Electrum and HTTP services can be utilized. You can leverage these examples as a reference to easily create services tailored to your application's specific needs. [examples](https://github.com/mrtnetwork/bitcoin_base/tree/main/example/lib/services_examples)

- Electrum API (Websocket, TCP, SSL)

```dart
  const network = BitcoinNetwork.mainnet;

  /// connect to electrum service with websocket
  /// please see `services_examples` folder for how to create electrum websocket service
  final service =
      await ElectrumSSLService.connect("testnet.aranguren.org:51002");

  /// create provider with service
  final provider = ElectrumProvider(service);

  final address = P2trAddress.fromAddress(address: ".....", network: network);

  /// Return the confirmed and unconfirmed balances of a script hash.
  final accountBalance = await provider
      .request(ElectrumGetScriptHashBalance(scriptHash: address.pubKeyHash()));

  /// Return an ordered list of UTXOs sent to a script hash.
  final accountUnspend = await provider
      .request(ElectrumRequestScriptHashListUnspent(scriptHash: address.pubKeyHash()));

  /// Return the confirmed and unconfirmed history of a script hash.
  final accountHistory = await provider
      .request(ElectrumScriptHashGetHistory(scriptHash: address.pubKeyHash()));

  /// Broadcast a transaction to the network.
  final broadcastTransaction = await provider
      .request(ElectrumRequestBroadCastTransaction(transactionRaw: "txDigest"));

  /// ....
```

- Explorer API (blockCypher, mempool)

```dart
  /// Define the blockchain network you want to work with, in this case, it's Bitcoin.
  const network = BitcoinNetwork.mainnet;

  /// see the example_service.dart for how to create a http service.
  final service = BitcoinApiService();

  /// Create an API provider instance for interacting with the BlockCypher API for the specified network.
  final api = ApiProvider.fromBlocCypher(network, service);

  /// Get the current network fee rate, which is essential for estimating transaction fees.
  final fee = await api.getNetworkFeeRate();

  /// Send a raw transaction represented by its transaction digest to the blockchain network.
  final transactionId = await api.sendRawTransaction("txDigest");

  /// Retrieve the Unspent Transaction Outputs (UTXOs) associated with a specific address.
  final utxo = await api.getAccountUtxo(address);

  /// Fetch information about a specific transaction using its transaction ID.
  /// For the Mempool API, use MempoolTransaction in the function template to receive the correct type.
  final transaction =
      await api.getTransaction<BlockCypherTransaction>(transactionId);

  /// Get a list of account transactions related to a specific address.
  /// For the Mempool API, use MempoolTransaction in the function template to receive the correct type.
  final accountTransactions =
      await api.getAccountTransactions<MempoolTransaction>('address');
```

## Contributing

Contributions are welcome! Please follow these guidelines:

- Fork the repository and create a new branch.
- Make your changes and ensure tests pass.
- Submit a pull request with a detailed description of your changes.

## Feature requests and bugs

Please file feature requests and bugs in the issue tracker.
