// Bitcoin regtest: MuSig2 (BIP-327) key aggregation and spending (2-of-2, 3-of-3, 2-of-3 script path).

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/examples/local/local_node.dart';

/// Spends every UTXO of [utxos] to [destination].
///
/// [sign] returns the witness stack for one input, given its BIP-341 digest.
Future<String> spendTaproot({
  required BitcoinProvider provider,
  required RegtestNode node,
  required LocalWallet funder,
  required P2trAddress taprootAddress,
  required List<UtxoWithAddress> utxos,
  required String miningAddress,
  required List<String> Function(List<int> digest, int index) sign,
  required BitcoinNetworkAddress destination,
  TaprootLeaf? tapleafScript,
}) async {
  final total = utxos.fold(BigInt.zero, (sum, utxo) => sum + utxo.utxo.value);
  final tx = BtcTransaction(
    inputs: utxos.map((utxo) => utxo.utxo.toInput()).toList(),
    outputs: [
      TxOutput(
        amount: total - exampleFee,
        scriptPubKey: destination.baseAddress.toScriptPubKey(),
      ),
    ],
  );

  /// BIP-341 signs over the amounts and scriptPubKeys of *all* inputs, so the
  /// same lists are passed for every input index.
  final scriptPubKeys = List.generate(
    utxos.length,
    (_) => taprootAddress.toScriptPubKey(),
  );
  final amounts = utxos.map((utxo) => utxo.utxo.value).toList();

  final witnesses = <TxWitnessInput>[];
  for (var index = 0; index < utxos.length; index++) {
    final digest = tx
        .getTransactionTaprootDigset(
          txIndex: index,
          scriptPubKeys: scriptPubKeys,
          amounts: amounts,
          tapleafScript: tapleafScript,
        )
        .asImmutableBytes;
    witnesses.add(TxWitnessInput(stack: sign(digest, index)));
  }

  return broadcastAndConfirm(
    provider,
    node,
    tx.copyWith(witnesses: witnesses),
    miningAddress,
  );
}

Future<void> main() async {
  const network = BitcoinNetwork.regtest;
  final node = RegtestNode.bitcoin;
  final mining = Mining(network);

  final service = await node.connectElectrum();
  final provider = BitcoinProvider(service);
  final destination = LocalWallet(index: 5, network: network);

  final alice = LocalWallet(index: 10, network: network);
  final bob = LocalWallet(index: 11, network: network);
  final carol = LocalWallet(index: 12, network: network);

  print('Bitcoin regtest: MuSig2');
  print('  electrum: ${service.url}');
  print('  tip:      ${await waitForTip(provider, node)}');
  print('');

  /// ---- 1. 2-of-2 key path ------------------------------------------------
  {
    final signer = Musig2Signer.generate(
      [alice.publicKey, bob.publicKey],
      privateKeys: [alice.privateKey, bob.privateKey],
      sortKeys: true,
    );
    final taproot = signer.toAddress();
    final address = taproot.toAddress(network);

    print('2-of-2 aggregate key: ${signer.aggPublicKey.toHex()}');
    print('2-of-2 address:       $address');

    final parsed = BitcoinNetworkAddress.parse(
      address: address,
      network: network,
    );
    final spendable = await node.fundFresh(
      provider,
      alice,
      parsed,
      throwaway: mining.throwaway,
    );

    /// Spend only the largest UTXO so the transaction stays small.
    final utxos = [largestUtxo(spendable)];
    print('2-of-2 funded:        '
        '${formatCoins(utxos.sumOfUtxosValue())} BTC');

    /// `fullSign` runs both MuSig2 rounds in-process.
    final txId = await spendTaproot(
      provider: provider,
      node: node,
      funder: alice,
      taprootAddress: taproot,
      utxos: utxos,
      miningAddress: mining.confirm,
      sign: (digest, _) => [
        BytesUtils.toHexString(signer.fullSign(digest)),
      ],
      destination: destination.p2pkh,
    );
    print('2-of-2 spend:         $txId');
    print('');
  }

  /// ---- 2. 3-of-3 key path ------------------------------------------------
  {
    final signer = Musig2Signer.generate(
      [alice.publicKey, bob.publicKey, carol.publicKey],
      privateKeys: [alice.privateKey, bob.privateKey, carol.privateKey],
      sortKeys: true,
    );
    final taproot = signer.toAddress();
    final address = taproot.toAddress(network);

    print('3-of-3 aggregate key: ${signer.aggPublicKey.toHex()}');
    print('3-of-3 address:       $address');

    final parsed = BitcoinNetworkAddress.parse(
      address: address,
      network: network,
    );
    final spendable = await node.fundFresh(
      provider,
      alice,
      parsed,
      throwaway: mining.throwaway,
    );

    /// Spend only the largest UTXO so the transaction stays small.
    final utxos = [largestUtxo(spendable)];
    print('3-of-3 funded:        '
        '${formatCoins(utxos.sumOfUtxosValue())} BTC');

    final txId = await spendTaproot(
      provider: provider,
      node: node,
      funder: alice,
      taprootAddress: taproot,
      utxos: utxos,
      miningAddress: mining.confirm,
      sign: (digest, _) => [
        BytesUtils.toHexString(signer.fullSign(digest)),
      ],
      destination: destination.p2pkh,
    );
    print('3-of-3 spend:         $txId');
    print('');
  }

  /// ---- 3. 2-of-3 script path --------------------------------------------
  {
    /// One aggregated key per allowed pair. Each leaf is `<aggKey> OP_CHECKSIG`.
    final pairs = <String, List<LocalWallet>>{
      'alice+bob': [alice, bob],
      'alice+carol': [alice, carol],
      'bob+carol': [bob, carol],
    };
    final signers = <String, Musig2Signer>{};
    final leaves = <String, TaprootLeaf>{};
    pairs.forEach((name, keys) {
      final signer = Musig2Signer.generate(
        keys.map((key) => key.publicKey).toList(),
        privateKeys: keys.map((key) => key.privateKey).toList(),
        sortKeys: true,
      );
      signers[name] = signer;
      leaves[name] = TaprootLeaf(
        script: Script(script: [
          signer.aggPublicKey.toXOnlyHex(),
          BitcoinOpcode.opCheckSig,
        ]),
      );
    });

    /// Internal key is a plain key so the tree is the only spend condition.
    final internalKey = LocalWallet(index: 13, network: network).publicKey;
    TaprootTree tree = leaves.values.first;
    for (final leaf in leaves.values.skip(1)) {
      tree = TaprootBranch(a: tree, b: leaf);
    }
    final taproot = P2trAddress.fromInternalKey(
      internalKey: internalKey.toXOnly(),
      treeScript: tree,
    );
    final address = taproot.toAddress(network);

    print('2-of-3 script tree address: $address');
    for (final entry in leaves.entries) {
      print('  leaf ${entry.key.padRight(12)} '
          '${signers[entry.key]!.aggPublicKey.toHex()}');
    }

    final parsed = BitcoinNetworkAddress.parse(
      address: address,
      network: network,
    );
    final spendable = await node.fundFresh(
      provider,
      alice,
      parsed,
      throwaway: mining.throwaway,
    );

    /// Spend only the largest UTXO so the transaction stays small.
    final utxos = [largestUtxo(spendable)];
    print('2-of-3 funded:        '
        '${formatCoins(utxos.sumOfUtxosValue())} BTC');

    /// Spend with the alice+bob leaf. Only those two keys take part, and the
    /// witness reveals just that leaf and its Merkle proof.
    const used = 'alice+bob';
    final leaf = leaves[used]!;
    final signer = signers[used]!;
    final control = TaprootControlBlock.generate(
      xOnlyOrInternalPubKey: internalKey.toXOnly(),
      leafScript: leaf,
      scriptTree: tree,
    );

    final txId = await spendTaproot(
      provider: provider,
      node: node,
      funder: alice,
      taprootAddress: taproot,
      utxos: utxos,
      miningAddress: mining.confirm,
      sign: (digest, _) {
        /// Script-path signatures are not key-tweaked.
        final signature = signer.fullSign(
          digest,
          treeScript: leaf,
          tweak: false,
        );
        return [
          BytesUtils.toHexString(signature),
          leaf.script.toHex(),
          control.toHex(),
        ];
      },
      destination: destination.p2pkh,
      tapleafScript: leaf,
    );
    print('2-of-3 ($used) spend: $txId');
    print('');
  }

  print('destination balance: '
      '${formatCoins(await balanceOf(provider, destination.p2pkh))} BTC');

  await service.close();
  print('');
  print('done.');
}
