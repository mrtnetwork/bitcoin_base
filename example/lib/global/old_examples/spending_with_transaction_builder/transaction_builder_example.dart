import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/services_examples/explorer_service/explorer_service.dart';

// spend from 8 different address type to 10 different output
void main() async {
  final service = BitcoinApiService();
  // select network
  const BitcoinNetwork network = BitcoinNetwork.testnet;

  // select api for read accounts UTXOs and send transaction
  // Mempool or BlockCypher
  final api = ApiProvider.fromBlocCypher(network, service);

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
  final List<UtxoWithAddress> utxos = [];

  // i add some method for provider to read utxos from mempol or blockCypher
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
      transactionBuilder.buildTransaction((trDigest, utxo, publicKey, sighash) {
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
    if (utxo.utxo.isP2tr) {
      // yes is p2tr utxo and now we use SignTaprootTransaction(Schnorr sign)
      // for now this transaction builder support only tweak transaction
      // If you want to spend a Taproot script-path spending, you must create your own transaction builder.
      return key.signBip340(trDigest, sighash: sighash);
    } else {
      // is seqwit(v0) or lagacy address we use  SingInput (ECDSA)
      return key.signECDSA(trDigest, sighash: sighash);
    }
  });

  // ok everything is fine and we need a transaction output for broadcasting
  // We use the Serialize method to receive the transaction output
  final digest = transaction.serialize();

  // we check if transaction is segwit or not
  // When one of the input UTXO addresses is SegWit, the transaction is considered SegWit.
  final isSegwitTr = transaction.hasWitness;

  // transaction id
  // ignore: unused_local_variable
  final transactionId = transaction.txId();

  // transaction size
  // ignore: unused_local_variable
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
    // Now we check Mempol for what happened https://mempool.space/testnet/tx/2625cd75f6576c38445deb2a9573c12ccc3438c3a6dd16fd431162d3f2fbb6c8
  } on Exception {
    // Something went wrong when sending the transaction
  }
}
