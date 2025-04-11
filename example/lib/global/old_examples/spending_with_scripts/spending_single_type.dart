// ignore_for_file: unused_local_variable

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:example/services_examples/explorer_service/explorer_service.dart';

import 'spending_builders.dart';

// Define the network as the Testnet (used for testing and development purposes).
const network = BitcoinNetwork.testnet;
final service = BitcoinApiService();

// Initialize an API provider for interacting with the Testnet's blockchain data.
final api = ApiProvider.fromMempool(network, service);

// In these tutorials, you will learn how to spend various types of UTXOs.
// Each method is specific to a type of UTXO.

// The number of inputs is not important, but ensure that all entries are of the type associated with the method.
// If you want to use several different types for spending in a single transaction, please refer to `transaction_builder_test.dart`.

// The number of outputs and their types are not important, and you can choose from hundreds of addresses with different types for the outputs

// Spend P2WPKH: Please note that all input addresses must be of P2WPKH type; otherwise, the transaction will fail.
Future<void> spendingP2WPKH(ECPrivate sWallet, ECPrivate rWallet) async {
  // The public keys and P2PWPH addresses we want to spend.
  // In this section, you can add any number of addresses with type P2PWPH to this transaction.
  final publicKey = sWallet.getPublic();
  // P2WPKH
  final sender = publicKey.toSegwitAddress();
  // Read UTXOs of accounts from the BlockCypher API.
  final utxo = await api.getAccountUtxo(
      UtxoAddressDetails(address: sender, publicKey: publicKey.toHex()));
  // The total amount of UTXOs that we can spend.
  final sumOfUtxo = utxo.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }
  // Receive network fees
  final feeRate = await api.getNetworkFeeRate();
  // feeRate.medium, feeRate.high ,feeRate.low P/KB

  // In this section, we select the transaction outputs; the number and type of addresses are not important
  final prive = sWallet;
  final recPub = rWallet.getPublic();
  // P2WPKH
  final receiver = recPub.toSegwitAddress();
  // P2TR
  final changeAddress = recPub.toTaprootAddress();

  // Well, now that we have received the UTXOs and determined the outputs,
  final List<BitcoinOutput> outputsAdress = [
    BitcoinOutput(address: receiver, value: BigInt.zero),
    BitcoinOutput(address: changeAddress, value: BigInt.zero)
  ];

  // we need the transaction fee at this point to calculate the output amounts, including the transaction fee.

  // To achieve this, we create a dummy transaction with specified inputs and outputs
  // to obtain the actual transaction size in bytes.
  // The `estimateTransactionSize` method of the `BitcoinTransactionBuilder` class does this for us
  final transactionSize = BitcoinTransactionBuilder.estimateTransactionSize(
      utxos: utxo, outputs: outputsAdress, network: network);

  // Now that we've determined the transaction size, let's calculate the transaction fee
  // based on the transaction size and the desired fee rate.
  final estimateFee = feeRate.getEstimate(transactionSize,
      feeRateType: BitcoinFeeRateType.medium);

  // We subtract the fee from the total amount of UTXOs to calculate
  // the actual amount we can spend in this transaction.
  final canSpend = sumOfUtxo - estimateFee;

  // We specify the desired amount for each address. Here, I have divided the desired total
  // amount by the number of outputs to ensure an equal amount for each.
  final outPutWithValue = outputsAdress
      .map((e) => BitcoinOutput(
          address: e.address,
          value: canSpend ~/ BigInt.from(outputsAdress.length)))
      .toList();

  // I use the 'buildP2wpkTransaction' method to create a transaction.
  // You can refer to this method to learn how to create a transaction.
  final transaction = buildP2wpkTransaction(
    receiver: outPutWithValue,
    sign: (p0, publicKey, sighash) {
      // Here, we find the corresponding private key based on the public key and proceed to sign the transaction."
      // Note that to sign Taproot transactions, you must use the 'signBip340' method for signing.
      // Below is a method for spending Taproot transactions that you can review.
      return prive.signECDSA(p0, sighash: sighash);
    },
    utxo: utxo,
  );
  // Now that the transaction is ready,
  // we can obtain the output and send it to the network using the 'serialize' method of the transaction.
  final ser = transaction.serialize();

  // transaction id
  final id = transaction.txId();

  // send transaction to the network
  final result = await api.sendRawTransaction(ser);
}

// Spend P2WSH: Please note that all input addresses must be of P2WSH type; otherwise, the transaction will fail.
// This method is for standard 1-1 Multisig P2WSH.
// For standard n-of-m multi-signature scripts, please refer to the 'multi_sig_transactions.dart' tutorial.
Future<void> spendingP2WSH(ECPrivate sWallet, ECPrivate rWallet) async {
  // All the steps are the same as in the first tutorial;
  // the only difference is the transaction input type,
  // and we use method `buildP2WSHTransaction` to create the transaction.
  final addr = sWallet.getPublic();
  // P2WSH ADDRESS
  final sender = addr.toP2wshAddress();
  final utxo = await api.getAccountUtxo(
      UtxoAddressDetails(address: sender, publicKey: addr.toHex()));
  final sumOfUtxo = utxo.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }

  final feeRate = await api.getNetworkFeeRate();
  final prive = sWallet;

  final recPub = rWallet.getPublic();
  final receiver = recPub.toSegwitAddress();

  final changeAddress = recPub.toSegwitAddress();
  final List<BitcoinOutput> outputsAdress = [
    BitcoinOutput(address: receiver, value: BigInt.zero),
    BitcoinOutput(address: changeAddress, value: BigInt.zero)
  ];
  final transactionSize = BitcoinTransactionBuilder.estimateTransactionSize(
      utxos: utxo, outputs: outputsAdress, network: network);
  final estimateFee = feeRate.getEstimate(transactionSize,
      feeRateType: BitcoinFeeRateType.medium);
  final canSpend = sumOfUtxo - estimateFee;
  final outPutWithValue = outputsAdress
      .map((e) => BitcoinOutput(
          address: e.address,
          value: canSpend ~/ BigInt.from(outputsAdress.length)))
      .toList();
  final transaction = buildP2WSHTransaction(
    receiver: outPutWithValue,
    sign: (p0, publicKey, sighash) {
      return prive.signECDSA(p0, sighash: sighash);
    },
    utxo: utxo,
  );
  final ser = transaction.serialize();
  final id = transaction.txId();
  await api.sendRawTransaction(ser);
}

// Spend P2PKH: Please note that all input addresses must be of P2PKH type; otherwise, the transaction will fail.
Future<void> spendingP2PKH(ECPrivate sWallet, ECPrivate rWallet) async {
  // All the steps are the same as in the first tutorial;
  // the only difference is the transaction input type,
  // and we use method `buildP2pkhTransaction` to create the transaction.
  final addr = sWallet.getPublic();
  // P2PKH
  final sender = addr.toAddress();
  final utxo = await api.getAccountUtxo(
      UtxoAddressDetails(address: sender, publicKey: addr.toHex()));
  final sumOfUtxo = utxo.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }

  final feeRate = await api.getNetworkFeeRate();
  final prive = sWallet;

  final recPub = rWallet.getPublic();
  final receiver = recPub.toSegwitAddress();
  final changeAddress = recPub.toSegwitAddress();
  final List<BitcoinOutput> outputsAdress = [
    BitcoinOutput(address: receiver, value: BigInt.zero),
    BitcoinOutput(address: changeAddress, value: BigInt.zero)
  ];
  final transactionSize = BitcoinTransactionBuilder.estimateTransactionSize(
      utxos: utxo, outputs: outputsAdress, network: network);
  final estimateFee = feeRate.getEstimate(transactionSize,
      feeRateType: BitcoinFeeRateType.medium);
  final canSpend = sumOfUtxo - estimateFee;
  final outPutWithValue = outputsAdress
      .map((e) => BitcoinOutput(
          address: e.address,
          value: canSpend ~/ BigInt.from(outputsAdress.length)))
      .toList();

  final transaction = buildP2pkhTransaction(
    receiver: outPutWithValue,
    sign: (p0, publicKey, sighash) {
      return prive.signECDSA(p0, sighash: sighash);
    },
    utxo: utxo,
  );
  final ser = transaction.serialize();
  final id = transaction.txId();
  await api.sendRawTransaction(ser);
}

// Spend P2SH(P2PKH) or P2SH(P2PK): Please note that all input addresses must be of P2SH(P2PKH) or P2SH(P2PK) type; otherwise, the transaction will fail.
// This method is for standard 1-1 Multisig P2SH.
// For standard n-of-m multi-signature scripts, please refer to the 'multi_sig_transactions.dart' tutorial.
Future<void> spendingP2SHNoneSegwit(
    ECPrivate sWallet, ECPrivate rWallet) async {
  // All the steps are the same as in the first tutorial;
  // the only difference is the transaction input type,
  // and we use method `buildP2shNoneSegwitTransaction` to create the transaction.
  final addr = sWallet.getPublic();
  // P2SH(P2PK)
  final sender = addr.toP2pkInP2sh();
  final utxo = await api.getAccountUtxo(
      UtxoAddressDetails(address: sender, publicKey: addr.toHex()));
  final sumOfUtxo = utxo.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }

  final feeRate = await api.getNetworkFeeRate();
  final prive = sWallet;

  final recPub = rWallet.getPublic();
  final receiver = recPub.toSegwitAddress();
  final changeAddress = recPub.toSegwitAddress();
  final List<BitcoinOutput> outputsAdress = [
    BitcoinOutput(address: receiver, value: BigInt.zero),
    BitcoinOutput(address: changeAddress, value: BigInt.zero)
  ];
  final transactionSize = BitcoinTransactionBuilder.estimateTransactionSize(
      utxos: utxo, outputs: outputsAdress, network: network);
  final estimateFee = feeRate.getEstimate(transactionSize,
      feeRateType: BitcoinFeeRateType.medium);
  final canSpend = sumOfUtxo - estimateFee;
  final outPutWithValue = outputsAdress
      .map((e) => BitcoinOutput(
          address: e.address,
          value: canSpend ~/ BigInt.from(outputsAdress.length)))
      .toList();
  final transaction = buildP2shNoneSegwitTransaction(
    receiver: outPutWithValue,
    sign: (p0, publicKey, sighash) {
      return prive.signECDSA(p0, sighash: sighash);
    },
    utxo: utxo,
  );
  final ser = transaction.serialize();
  final id = transaction.txId();
  await api.sendRawTransaction(ser);
}

// Spend P2SH(P2WPKH) or P2SH(P2WSH): Please note that all input addresses must be of P2SH(P2WPKH) or P2SH(P2WSH) type; otherwise, the transaction will fail.
// This method is for standard 1-1 Multisig P2SH.
// For standard n-of-m multi-signature scripts, please refer to the 'multi_sig_transactions.dart' tutorial.
Future<void> spendingP2shSegwit(ECPrivate sWallet, ECPrivate rWallet) async {
  // All the steps are the same as in the first tutorial;
  // the only difference is the transaction input type,
  // and we use method `buildP2SHSegwitTransaction` to create the transaction.
  final addr = sWallet.getPublic();
  // P2SH(P2PWKH)
  final sender = addr.toP2wpkhInP2sh();
  final utxo = await api.getAccountUtxo(
      UtxoAddressDetails(address: sender, publicKey: addr.toHex()));
  final sumOfUtxo = utxo.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }

  final feeRate = await api.getNetworkFeeRate();
  final prive = sWallet;

  final recPub = rWallet.getPublic();
  final receiver = recPub.toSegwitAddress();

  final changeAddress = recPub.toSegwitAddress();
  final List<BitcoinOutput> outputsAdress = [
    BitcoinOutput(address: receiver, value: BigInt.zero),
    BitcoinOutput(address: changeAddress, value: BigInt.zero)
  ];
  final transactionSize = BitcoinTransactionBuilder.estimateTransactionSize(
      utxos: utxo, outputs: outputsAdress, network: network);
  final estimateFee = feeRate.getEstimate(transactionSize,
      feeRateType: BitcoinFeeRateType.medium);
  final canSpend = sumOfUtxo - estimateFee;
  final outPutWithValue = outputsAdress
      .map((e) => BitcoinOutput(
          address: e.address,
          value: canSpend ~/ BigInt.from(outputsAdress.length)))
      .toList();

  // return;
  final transaction = buildP2SHSegwitTransaction(
    receiver: outPutWithValue,
    sign: (p0, publicKey, sighash) {
      return prive.signECDSA(p0, sighash: sighash);
    },
    utxo: utxo,
  );
  final ser = transaction.serialize();
  final id = transaction.txId();
  await api.sendRawTransaction(ser);
}

// Spend P2TR: Please note that all input addresses must be of P2TR type; otherwise, the transaction will fail.
Future<void> spendingP2TR(ECPrivate sWallet, ECPrivate rWallet) async {
  // All the steps are the same as in the first tutorial;
  // the only difference is the transaction input type,
  // and we use method `buildP2trTransaction` to create the transaction.
  // we use `signBip340` of ECPrivate for signing taproot transaction
  final addr = sWallet.getPublic();
  // P2TR address
  final sender = addr.toTaprootAddress();
  final utxo = await api.getAccountUtxo(
      UtxoAddressDetails(address: sender, publicKey: addr.toHex()));
  final sumOfUtxo = utxo.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }

  final feeRate = await api.getNetworkFeeRate();
  final prive = sWallet;

  final recPub = rWallet.getPublic();
  final receiver = recPub.toSegwitAddress();
  final changeAddress = recPub.toSegwitAddress();
  final List<BitcoinOutput> outputsAdress = [
    BitcoinOutput(address: receiver, value: BigInt.zero),
    BitcoinOutput(address: changeAddress, value: BigInt.zero)
  ];
  final transactionSize = BitcoinTransactionBuilder.estimateTransactionSize(
      utxos: utxo, outputs: outputsAdress, network: network);
  final estimateFee = feeRate.getEstimate(transactionSize,
      feeRateType: BitcoinFeeRateType.medium);
  final canSpend = sumOfUtxo - estimateFee;
  final outPutWithValue = outputsAdress
      .map((e) => BitcoinOutput(
          address: e.address,
          value: canSpend ~/ BigInt.from(outputsAdress.length)))
      .toList();

  final transaction = buildP2trTransaction(
    receiver: outPutWithValue,
    sign: (p0, publicKey, sighash) {
      // Use signBip340 instead of signECDSA for the taproot transaction input.
      return prive.signBip340(p0, sighash: sighash, tweak: true);
    },
    utxo: utxo,
  );
  final ser = transaction.serialize();
  final id = transaction.txId();
  await api.sendRawTransaction(ser);
}
