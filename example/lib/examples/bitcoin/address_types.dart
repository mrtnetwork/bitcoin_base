// Bitcoin regtest: every supported address type (fund each, sweep each back).

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:example/examples/local/local_node.dart';

Future<void> main() async {
  const network = BitcoinNetwork.regtest;
  final node = RegtestNode.bitcoin;
  final mining = Mining(network);

  final service = await node.connectElectrum();
  final provider = BitcoinProvider(service);
  final wallet = LocalWallet(index: 0, network: network);
  final receiver = LocalWallet(index: 1, network: network);

  /// Fan-out change goes here so the funded types start from a clean slate.
  final change = LocalWallet(index: 90, network: network).p2pkh;

  print('Bitcoin regtest address types');
  print('  electrum: ${service.url}');
  print('  tip:      ${await waitForTip(provider, node)}');
  print('  key:      ${wallet.publicKey.toHex()}');
  print('');

  final types = network.supportedAddress;
  for (final type in types) {
    final address = wallet.addressFor(type);
    print('  ${type.name.padRight(14)} ${address.address}');
  }
  print('');

  /// Fund the P2PKH address with a single mature coinbase.
  final fund = wallet.p2pkh;
  final spendable = await node.fundFresh(
    provider,
    wallet,
    fund,
    throwaway: mining.throwaway,
  );

  /// Spend only the largest UTXO: the address has change from previous runs and
  /// sweeping all of it would make the transaction need a much larger fee.
  final fundUtxos = [largestUtxo(spendable)];
  print('funding ${fund.address}');
  print('  balance: ${formatCoins(fundUtxos.sumOfUtxosValue())} BTC');
  print('');

  /// One transaction paying a dust output to every address type.
  final dust = BigInt.from(10000);
  final fanOut = BitcoinTransactionBuilder(
    outPuts: [
      for (final type in types)
        BitcoinOutput(
            address: wallet.addressFor(type).baseAddress, value: dust),
      BitcoinOutput(
        address: change.baseAddress,
        value: fundUtxos.sumOfUtxosValue() -
            dust * BigInt.from(types.length) -
            exampleFee,
      ),
    ],
    fee: exampleFee,
    network: network,
    utxos: fundUtxos,
  ).buildTransaction((digest, utxo, publicKey, sighash) {
    return wallet.privateKey.signECDSA(digest, sighash: sighash);
  });
  final fanOutId = await broadcastAndConfirm(
    provider,
    node,
    fanOut,
    mining.confirm,
  );
  print('fan-out $fanOutId');
  print('');

  /// Spend each address type back to the receiver.
  print('spending from each type (received is the delta):');
  for (final type in types) {
    final address = wallet.addressFor(type);

    /// The fan-out output is not a coinbase, so one confirmation is enough.
    final spendable = await waitForSpendableUtxos(
      provider,
      wallet,
      address,
      node: node,
      requiredConfirmations: 1,
    );

    /// Spend only the dust this run created, so the example stays small and
    /// repeatable even when the address already holds older change.
    final utxos = [
      spendable.firstWhere((utxo) => utxo.utxo.txHash == fanOutId),
    ];
    final value = utxos.sumOfUtxosValue();
    final spend = BitcoinTransactionBuilder(
      outPuts: [
        BitcoinOutput(
          address: receiver.addressFor(type).baseAddress,
          value: value - exampleFee,
        ),
      ],
      fee: exampleFee,
      network: network,
      utxos: utxos,
    ).buildTransaction((digest, utxo, publicKey, sighash) {
      /// P2TR is signed with Schnorr, everything else with ECDSA.
      if (utxo.utxo.isP2tr) return wallet.privateKey.signBip340(digest);
      return wallet.privateKey.signECDSA(digest, sighash: sighash);
    });
    final receiverAddress = receiver.addressFor(type);
    final before = await balanceOf(provider, receiverAddress);
    final txId = await broadcastAndConfirm(
      provider,
      node,
      spend,
      mining.confirm,
    );
    final delta = await balanceOf(provider, receiverAddress) - before;
    print(
      '  ${type.name.padRight(14)} $txId  received ${formatCoins(delta)}',
    );
  }

  await service.close();
  print('');
  print('done.');
}
