// Bitcoin regtest: receive, then send (fund, read back, sweep).

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:example/examples/local/local_node.dart';

Future<void> main() async {
  const network = BitcoinNetwork.regtest;
  final node = RegtestNode.bitcoin;
  final mining = Mining(network);

  final service = await node.connectElectrum();
  final provider = BitcoinProvider(service);

  /// The receiver only needs to know its address; nothing is signed here.
  final receiver = LocalWallet(index: 2, network: network)
      .addressFor(SegwitAddressType.p2wpkh);
  final sender = LocalWallet(index: 0, network: network);
  final senderAddress = sender.addressFor(P2pkhAddressType.p2pkh);

  print('Bitcoin regtest: send + receive');
  print('  electrum:  ${service.url}');
  print('  sender:    ${senderAddress.address}');
  print('  receiver:  ${receiver.address} (P2WPKH)');
  print('');

  /// ---- receive -----------------------------------------------------------
  /// The receiving side is entirely offline: derive, share, wait for the funds.
  print('receiver balance before: '
      '${formatCoins(await balanceOf(provider, receiver))} BTC');

  final spendable = await node.fundFresh(
    provider,
    sender,
    senderAddress,
    throwaway: mining.throwaway,
  );

  /// Spend only the largest UTXO so the transaction stays small.
  final utxos = [largestUtxo(spendable)];
  print('sender funded: ${formatCoins(utxos.sumOfUtxosValue())} BTC');
  print('');

  /// ---- send --------------------------------------------------------------
  /// The coinbase subsidy halves every 150 regtest blocks, so the send amount is
  /// derived from the UTXO rather than fixed: send half, keep the rest as change.
  final amount = utxos.sumOfUtxosValue() ~/ BigInt.two;
  final change = utxos.sumOfUtxosValue() - amount - exampleFee;
  final tx = BitcoinTransactionBuilder(
    outPuts: [
      BitcoinOutput(address: receiver.baseAddress, value: amount),
      BitcoinOutput(address: senderAddress.baseAddress, value: change),
    ],
    fee: exampleFee,
    network: network,
    utxos: utxos,
  ).buildTransaction((digest, utxo, publicKey, sighash) {
    return sender.privateKey.signECDSA(digest, sighash: sighash);
  });

  final txId = await broadcastAndConfirm(
    provider,
    node,
    tx,
    mining.confirm,
  );
  print('tx: $txId');

  final history = await provider.request(
    ElectrumRequestScriptHashGetHistory(scriptHash: receiver.pubKeyHash()),
  );
  print('receiver history: $history');
  print('');

  /// ---- spend what was received ------------------------------------------
  final received = await waitForSpendableUtxos(
    provider,
    LocalWallet(index: 2, network: network),
    receiver,
    node: node,
    requiredConfirmations: 1,
  );
  print('receiver can spend ${formatCoins(received.sumOfUtxosValue())} BTC');

  final sweep = BitcoinTransactionBuilder(
    outPuts: [
      BitcoinOutput(
        address: senderAddress.baseAddress,
        value: received.sumOfUtxosValue() - exampleFee,
      ),
    ],
    fee: exampleFee,
    network: network,
    utxos: received,
  ).buildTransaction((digest, utxo, publicKey, sighash) {
    final key = LocalWallet(index: 2, network: network);
    return key.privateKey.signECDSA(digest, sighash: sighash);
  });
  final sweepId = await broadcastAndConfirm(
    provider,
    node,
    sweep,
    mining.confirm,
  );
  print('sweep tx: $sweepId');
  print('receiver balance after: '
      '${formatCoins(await balanceOf(provider, receiver))} BTC');

  await service.close();
  print('');
  print('done.');
}
