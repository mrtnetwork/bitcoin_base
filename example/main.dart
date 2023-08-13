import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:flutter_test/flutter_test.dart';
import './transactions/spend_p2kh_to_p2k.dart';
import './transactions/spend_p2kh_to_p2kh.dart';
import './transactions/spend_p2pk_to_p2pkh.dart';
import './transactions/spend_p2pkh_to_p2sh.dart';
import './transactions/spend_p2pkh_to_p2wpkh.dart';
import './transactions/spend_p2sh_to_p2k.dart';
import './transactions/spend_p2sh_to_p2pkh.dart';
import './transactions/spend_p2sh_to_p2sh.dart';
import './transactions/spend_p2sh_to_p2wkh.dart';
import './transactions/spend_p2wkh_to_p2k.dart';
import './transactions/spend_p2wkh_to_p2wkh.dart';
import './transactions/spend_p2wkh_to_p2kh.dart';
import './transactions/spend_p2wkh_to_p2sh.dart';
import 'helper.dart';

void main() {}

final BTCRpcHelper testRpc = BTCRpcHelper();

/// spend p2wkh utxo
Future<void> testSpendP2wkhToP2wkh(ECPrivate sWallet, ECPrivate rWallet) async {
  final addr = sWallet.getPublic();
  final sender = addr.toSegwitAddress();
  final utxo = await testRpc.getUtxo(sender.toAddress(NetworkInfo.TESTNET));
  if (utxo.isEmpty) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }

  final BigInt estimateFee = await testRpc
      .getSmartEstimate()
      .catchError((e) => priceToBtcUnit(0.00001));
  final prive = sWallet;
  final recPub = rWallet.getPublic();
  final receiver = recPub.toSegwitAddress();
  final changeAddress =
      recPub.toSegwitAddress(); // change address is p2pk instead of p2wpkh

  // return;
  final digit = spendp2wkh(
      networkType: NetworkInfo.TESTNET,
      receiver: receiver,
      senderPub: addr,
      sign: prive.signInput,
      utxo: utxo,
      estimateFee: estimateFee,
      value: BigInt.one,
      changeAddress: changeAddress);
  // return;
  await testRpc.sendRawTransaction(digit.$1);
}

/// spend p2wkh utxo
Future<void> testSpendP2wkhToP2kh(ECPrivate sWallet, ECPrivate rWallet) async {
  final addr = sWallet.getPublic();
  final sender = addr.toSegwitAddress();
  final utxo = await testRpc.getUtxo(sender.toAddress(NetworkInfo.TESTNET));
  if (utxo.isEmpty) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }

  final BigInt estimateFee = await testRpc.getSmartEstimate();
  final prive = sWallet;
  final recPub = rWallet.getPublic();
  final receiver = recPub.toAddress();
  final digit = spendP2wkhToP2kh(
      networkType: NetworkInfo.TESTNET,
      receiver: receiver,
      senderPub: addr,
      sign: prive.signInput,
      utxo: utxo,
      estimateFee: estimateFee,
      value: BigInt.one);
  // return;
  await testRpc.sendRawTransaction(digit.$1);
}

/// spend p2kh utxo
Future<void> testSpendp2khToP2kh(ECPrivate sWallet, ECPrivate rWallet) async {
  final addr = sWallet.getPublic();
  final sender = addr.toAddress();
  final utxo = (await testRpc.getUtxo(sender.toAddress(NetworkInfo.TESTNET)))
    ..sort((a, b) => b.value.compareTo(a.value));
  if (utxo.isEmpty) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }

  final BigInt estimateFee = await testRpc.getSmartEstimate();
  final prive = sWallet;
  final recPub = rWallet.getPublic();
  final receiver = recPub.toAddress();
  final digit = spendP2pkhToP2pkh(
      networkType: NetworkInfo.TESTNET,
      receiver: receiver,
      senderPub: addr,
      sign: prive.signInput,
      utxo: [utxo.first],
      estimateFee: estimateFee,
      value: null);

  await testRpc.sendRawTransaction(digit.$1);
}

/// spend p2kh utxo
Future<void> testSpendp2kToP2kh(ECPrivate sWallet, ECPrivate rWallet) async {
  final addr = sWallet.getPublic();
  final sender = addr.toAddress();
  final utxo = (await testRpc.getUtxo(sender.toAddress(NetworkInfo.TESTNET)))
    ..sort((a, b) => b.value.compareTo(a.value));
  if (utxo.isEmpty) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }
  final BigInt estimateFee = await testRpc.getSmartEstimate();
  final prive = sWallet;
  final recPub = rWallet.getPublic();
  final receiver = recPub.toAddress();
  final digit = spendP2pkToP2pkh(
      networkType: NetworkInfo.TESTNET,
      receiver: receiver,
      senderPub: addr,
      sign: prive.signInput,
      utxo: utxo,
      estimateFee: estimateFee,
      value: BigInt.zero);
  await testRpc.sendRawTransaction(digit.$1);
}

/// spend p2kh utxo
Future<void> testSpendp2khToP2wkh(ECPrivate sWallet, ECPrivate rWallet) async {
  final addr = sWallet.getPublic();
  final sender = addr.toAddress();
  final utxo = (await testRpc.getUtxo(sender.toAddress(NetworkInfo.TESTNET)))
    ..sort((a, b) => b.value.compareTo(a.value));
  if (utxo.isEmpty) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }
  final BigInt estimateFee = await testRpc.getSmartEstimate();
  final prive = sWallet;
  final recPub = rWallet.getPublic();
  final receiver = recPub.toSegwitAddress();
  final digit = spendP2khToP2wkh(
      networkType: NetworkInfo.TESTNET,
      receiver: receiver,
      senderPub: addr,
      sign: prive.signInput,
      utxo: utxo,
      estimateFee: estimateFee,
      value: null);
  await testRpc.sendRawTransaction(digit.$1);
}

/// spend p2kh utxo
Future<void> testSpendp2khToP2sh(ECPrivate sWallet, ECPrivate rWallet) async {
  final addr = sWallet.getPublic();
  final sender = addr.toAddress();
  final utxo = (await testRpc.getUtxo(sender.toAddress(NetworkInfo.TESTNET)))
    ..sort((a, b) => b.value.compareTo(a.value));
  if (utxo.isEmpty) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }
  final BigInt estimateFee = await testRpc.getSmartEstimate();
  final prive = sWallet;
  final recPub = rWallet.getPublic();
  final digit = spendP2khToP2sh(
      networkType: NetworkInfo.TESTNET,
      receiver: recPub,
      senderPub: addr,
      sign: prive.signInput,
      utxo: utxo,
      estimateFee: estimateFee,
      value: null);
  await testRpc.sendRawTransaction(digit.$1);
}

/// spend p2wpkh utxo
Future<void> testSpendp2wpkhToP2sh(ECPrivate sWallet, ECPrivate rWallet) async {
  final addr = sWallet.getPublic();
  final sender = addr.toSegwitAddress();
  final utxo = (await testRpc.getUtxo(sender.toAddress(NetworkInfo.TESTNET)))
    ..sort((a, b) => b.value.compareTo(a.value));
  if (utxo.isEmpty) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }
  // return;
  final BigInt estimateFee = await testRpc.getSmartEstimate();
  final prive = sWallet;
  final recPub = rWallet.getPublic();

  final digit = spendP2wkhToP2sh(
      networkType: NetworkInfo.TESTNET,
      receiver: recPub,
      senderPub: addr,
      sign: prive.signInput,
      utxo: utxo,
      estimateFee: estimateFee,
      value: BigInt.from(1056000));

  await testRpc.sendRawTransaction(digit.$1);
}

/// spend p2sh utxo
Future<void> testSpendp2shToP2sh(ECPrivate sWallet, ECPrivate rWallet) async {
  final addr = sWallet.getPublic();
  final sender = P2shAddress(script: addr.toRedeemScript());
  final utxo = (await testRpc.getUtxo(sender.toAddress(NetworkInfo.TESTNET)))
    ..sort((a, b) => b.value.compareTo(a.value));
  if (utxo.isEmpty) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }

  final BigInt estimateFee = await testRpc.getSmartEstimate();
  final prive = sWallet;
  final recPub = rWallet.getPublic();

  final digit = spendP2shToP2sh(
      networkType: NetworkInfo.TESTNET,
      receiver: recPub,
      senderPub: addr,
      sign: prive.signInput,
      utxo: utxo,
      estimateFee: estimateFee,
      value: BigInt.one);

  await testRpc.sendRawTransaction(digit.$1);
}

/// spend p2sh utxo
Future<void> testSpendp2shToP2kh(ECPrivate sWallet, ECPrivate rWallet) async {
  final addr = sWallet.getPublic();
  final sender = P2shAddress(script: addr.toRedeemScript());
  final utxo = (await testRpc.getUtxo(sender.toAddress(NetworkInfo.TESTNET)))
    ..sort((a, b) => b.value.compareTo(a.value));
  if (utxo.isEmpty) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }
  // return;
  final BigInt estimateFee = await testRpc.getSmartEstimate();
  final prive = sWallet;
  final recPub = rWallet.getPublic();
  final receiver = recPub.toAddress();

  final digit = spendP2shToP2pkh(
      networkType: NetworkInfo.TESTNET,
      receiver: receiver,
      senderPub: addr,
      sign: prive.signInput,
      utxo: utxo,
      estimateFee: estimateFee,
      value: BigInt.zero);

  await testRpc.sendRawTransaction(digit.$1);
}

/// spend p2sh utxo
Future<void> testSpendp2shToP2wpkh(ECPrivate sWallet, ECPrivate rWallet) async {
  final addr = sWallet.getPublic();
  final sender = P2shAddress(script: addr.toRedeemScript());
  final utxo = (await testRpc.getUtxo(sender.toAddress(NetworkInfo.TESTNET)))
    ..sort((a, b) => b.value.compareTo(a.value));
  if (utxo.isEmpty) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }
  // return;
  final BigInt estimateFee = await testRpc.getSmartEstimate();
  final prive = sWallet;
  final recPub = rWallet.getPublic();
  final receiver = recPub.toSegwitAddress();

  final digit = spendP2shToP2wpkh(
      networkType: NetworkInfo.TESTNET,
      receiver: receiver,
      senderPub: addr,
      sign: prive.signInput,
      utxo: utxo,
      estimateFee: estimateFee,
      value: BigInt.zero);

  await testRpc.sendRawTransaction(digit.$1);
}

/// spend p2pkh utxo
Future<void> testSpendp2pkhToP2pk(ECPrivate sWallet, ECPrivate rWallet) async {
  final addr = sWallet.getPublic();
  final sender = addr.toAddress();
  final utxo = (await testRpc.getUtxo(sender.toAddress(NetworkInfo.TESTNET)))
    ..sort((a, b) => b.value.compareTo(a.value));
  if (utxo.isEmpty) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }

  final BigInt estimateFee = await testRpc.getSmartEstimate();
  final prive = sWallet;
  final recPub = rWallet.getPublic();
  final receiver = recPub.toP2pkAddress();

  final digit = spendP2pkhToP2pk(
      networkType: NetworkInfo.TESTNET,
      receiver: receiver,
      senderPub: addr,
      sign: prive.signInput,
      utxo: utxo,
      estimateFee: estimateFee,
      value: null);

  await testRpc.sendRawTransaction(digit.$1);
}

/// spend p2wpkh utxo
Future<void> testSpendp2wpkhToP2k(ECPrivate sWallet, ECPrivate rWallet) async {
  final addr = sWallet.getPublic();
  final sender = addr.toSegwitAddress();
  final utxo = (await testRpc.getUtxo(sender.toAddress(NetworkInfo.TESTNET)))
    ..sort((a, b) => b.value.compareTo(a.value));
  if (utxo.isEmpty) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }
  // return;
  final BigInt estimateFee = await testRpc.getSmartEstimate();
  final prive = sWallet;
  final recPub = rWallet.getPublic();
  final receiver = recPub.toP2pkAddress();

  final digit = spendP2wkhToP2pk(
      networkType: NetworkInfo.TESTNET,
      receiver: receiver,
      senderPub: addr,
      sign: prive.signInput,
      utxo: utxo,
      estimateFee: estimateFee,
      value: BigInt.one);

  await testRpc.sendRawTransaction(digit.$1);
}

/// spend p2sh utxo
Future<void> testSpendp2shToP2k(ECPrivate sWallet, ECPrivate rWallet) async {
  final addr = sWallet.getPublic();
  final sender = P2shAddress(script: addr.toRedeemScript());
  final utxo = (await testRpc.getUtxo(sender.toAddress(NetworkInfo.TESTNET)))
    ..sort((a, b) => b.value.compareTo(a.value));
  if (utxo.isEmpty) {
    throw Exception(
        "account does not have any unspent transaction or mybe no confirmed");
  }
  final BigInt estimateFee = await testRpc.getSmartEstimate();
  final prive = sWallet;
  final recPub = rWallet.getPublic();
  final receiver = recPub.toP2pkAddress();

  final digit = spendP2shToP2pk(
      networkType: NetworkInfo.TESTNET,
      receiver: receiver,
      senderPub: addr,
      sign: prive.signInput,
      utxo: utxo,
      estimateFee: estimateFee,
      value: BigInt.from(105999));

  await testRpc.sendRawTransaction(digit.$1);
}
