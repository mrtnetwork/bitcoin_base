// Bitcoin Cash regtest: every supported address type, token-aware variants built explicitly.

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:example/examples/local/local_node.dart';

/// One row of the address matrix: the type name plus its address for a key.
typedef AddressKind = ({BitcoinAddressType type, BitcoinBaseAddress address});

/// Every distinct address this key can be paid to.
///
/// [PubKeyAddressType.p2pk] is left out because it encodes to exactly the same
/// address as [P2pkhAddressType.p2pkh].
List<AddressKind> bchAddressKinds(ECPublic pub) {
  P2pkhAddress p2pkh(P2pkhAddressType type) {
    return P2pkhAddress.fromHash160(addrHash: pub.toHash160Hex(), type: type);
  }

  P2shAddress p2sh(P2shAddressType type, {required bool p2sh32}) {
    /// `P2SH32/P2PKH` also starts with `P2SH32/P2PK`, so match the full name.
    final isP2pk = type.name.endsWith('/P2PK');
    final redeem = isP2pk
        ? pub.toP2pkInP2sh(useBCHP2sh32: p2sh32)
        : pub.toP2pkhInP2sh(useBCHP2sh32: p2sh32);
    return P2shAddress.fromHash160(
      addrHash: redeem.addressProgram,
      type: type,
    );
  }

  return [
    (type: P2pkhAddressType.p2pkh, address: p2pkh(P2pkhAddressType.p2pkh)),
    (
      type: P2pkhAddressType.p2pkhwt,
      address: p2pkh(P2pkhAddressType.p2pkhwt),
    ),
    (
      type: P2shAddressType.p2pkhInP2sh,
      address: p2sh(P2shAddressType.p2pkhInP2sh, p2sh32: false),
    ),
    (
      type: P2shAddressType.p2pkhInP2shwt,
      address: p2sh(P2shAddressType.p2pkhInP2shwt, p2sh32: false),
    ),
    (
      type: P2shAddressType.p2pkhInP2sh32,
      address: p2sh(P2shAddressType.p2pkhInP2sh32, p2sh32: true),
    ),
    (
      type: P2shAddressType.p2pkhInP2sh32wt,
      address: p2sh(P2shAddressType.p2pkhInP2sh32wt, p2sh32: true),
    ),
    (
      type: P2shAddressType.p2pkInP2sh,
      address: p2sh(P2shAddressType.p2pkInP2sh, p2sh32: false),
    ),
    (
      type: P2shAddressType.p2pkInP2shwt,
      address: p2sh(P2shAddressType.p2pkInP2shwt, p2sh32: false),
    ),
    (
      type: P2shAddressType.p2pkInP2sh32,
      address: p2sh(P2shAddressType.p2pkInP2sh32, p2sh32: true),
    ),
    (
      type: P2shAddressType.p2pkInP2sh32wt,
      address: p2sh(P2shAddressType.p2pkInP2sh32wt, p2sh32: true),
    ),
  ];
}

Future<void> main() async {
  const network = BitcoinCashNetwork.regtest;
  final node = RegtestNode.bitcoinCash;
  final mining = Mining(network);

  final service = await node.connectElectrum();
  final provider = BitcoinProvider(service);
  final wallet = LocalWallet(index: 0, network: network);
  final receiver = LocalWallet(index: 1, network: network);

  /// Fan-out change goes here so the funded types start from a clean slate.
  final change = LocalWallet(index: 90, network: network).p2pkh;

  print('Bitcoin Cash regtest address types');
  print('  electrum: ${service.url}');
  print('  tip:      ${await waitForTip(provider, node)}');
  print('  key:      ${wallet.publicKey.toHex()}');
  print('');

  final senderKinds = bchAddressKinds(wallet.publicKey);
  final receiverKinds = bchAddressKinds(receiver.publicKey);

  for (final kind in senderKinds) {
    final address = BitcoinCashAddress.fromBaseAddress(
      kind.address,
      network: network,
    );
    final tag = kind.type.withToken ? ' (token-aware)' : '';
    print('  ${kind.type.name.padRight(18)} ${address.address}$tag');
  }
  print('');

  /// Fund the plain P2PKH address with a single mature coinbase.
  final fund = BitcoinCashAddress.fromBaseAddress(
    senderKinds.first.address,
    network: network,
  );
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
  print('  balance: ${formatCoins(fundUtxos.sumOfUtxosValue())} BCH');
  print('');

  /// One transaction paying a dust output to every distinct sender type.
  final dust = BigInt.from(10000);
  final fanOut = ForkedTransactionBuilder(
    outPuts: [
      for (final kind in senderKinds)
        BitcoinOutput(address: kind.address, value: dust),
      BitcoinOutput(
        address: change.baseAddress,
        value: fundUtxos.sumOfUtxosValue() -
            dust * BigInt.from(senderKinds.length) -
            exampleFee,
      ),
    ],
    fee: exampleFee,
    network: network,
    utxos: fundUtxos,

    /// Keep output order stable so the dust lands on predictable indexes.
    outputOrdering: BitcoinOrdering.none,
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

  print('spending from each type (received is the delta):');
  for (var i = 0; i < senderKinds.length; i++) {
    final senderAddress = BitcoinCashAddress.fromBaseAddress(
      senderKinds[i].address,
      network: network,
    );
    final receiverAddress = BitcoinCashAddress.fromBaseAddress(
      receiverKinds[i].address,
      network: network,
    );

    /// The fan-out change is not a coinbase, so one confirmation is enough.
    final spendableUtxos = await waitForSpendableUtxos(
      provider,
      wallet,
      senderAddress,
      node: node,
      requiredConfirmations: 1,
    );

    /// Spend only the dust this run created, so the example stays small and
    /// repeatable even when the address already holds older change.
    final utxos = [
      spendableUtxos.firstWhere(
        (utxo) => utxo.utxo.txHash == fanOutId,
      ),
    ];
    final before = await balanceOf(provider, receiverAddress);
    final spend = ForkedTransactionBuilder(
      outPuts: [
        BitcoinOutput(
          address: receiverAddress.baseAddress,
          value: utxos.sumOfUtxosValue() - exampleFee,
        ),
      ],
      fee: exampleFee,
      network: network,
      utxos: utxos,
      outputOrdering: BitcoinOrdering.none,
    ).buildTransaction((digest, utxo, publicKey, sighash) {
      return wallet.privateKey.signECDSA(digest, sighash: sighash);
    });
    final txId = await broadcastAndConfirm(
      provider,
      node,
      spend,
      mining.confirm,
    );
    final delta = await balanceOf(provider, receiverAddress) - before;
    print(
      '  ${senderKinds[i].type.name.padRight(18)} $txId  '
      'received ${formatCoins(delta)}',
    );
  }

  await service.close();
  print('');
  print('done.');
}
