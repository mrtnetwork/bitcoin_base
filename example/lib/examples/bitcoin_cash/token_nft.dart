// Bitcoin Cash regtest: CashToken NFTs (category, mint mutable NFT, transfer).

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:example/examples/local/local_node.dart';

/// Value of a token-carrying output: enough to cover its own size, as required
/// by the CashToken spec.
final BigInt tokenDust = BtcUtils.toSatoshi('0.000015');

/// Total amount of [category] held across [utxos].
BigInt tokenBalance(List<UtxoWithAddress> utxos, String category) {
  return utxos.fold<BigInt>(BigInt.zero, (sum, utxo) {
    final token = utxo.utxo.token;
    if (token == null || token.category != category) return sum;
    return sum + token.amount;
  });
}

/// True when [utxo] is the genesis output (index 0) of [txId].
bool isGenesisOutput(UtxoWithAddress utxo, String txId) {
  return utxo.utxo.txHash == txId && utxo.utxo.vout == 0;
}

Future<void> main() async {
  const network = BitcoinCashNetwork.regtest;
  final node = RegtestNode.bitcoinCash;
  final mining = Mining(network);

  final service = await node.connectElectrum();
  final provider = BitcoinProvider(service);
  final wallet = LocalWallet(index: 30, network: network);
  final receiver = LocalWallet(index: 31, network: network);

  final fund = wallet.addressFor(P2pkhAddressType.p2pkh);
  final receiverTokenAddress = receiver.addressFor(P2pkhAddressType.p2pkhwt);

  print('Bitcoin Cash regtest: CashToken NFT');
  print('  electrum: ${service.url}');
  print('  tip:      ${await waitForTip(provider, node)}');
  print('  wallet:   ${fund.address}');
  print('  receiver: ${receiverTokenAddress.address} (token-aware)');
  print('');

  /// ---- 1. fund -----------------------------------------------------------
  final spendable = await node.fundFresh(
    provider,
    wallet,
    fund,
    throwaway: mining.throwaway,
  );
  final utxos = [largestUtxo(spendable)];
  print('funded: ${formatCoins(utxos.sumOfUtxosValue())} BCH');

  /// ---- 2. create the category (spend an output 0) ------------------------
  final makeVout0 = ForkedTransactionBuilder(
    outPuts: [
      /// Output 0 becomes the genesis output of the category.
      BitcoinOutput(address: fund.baseAddress, value: tokenDust),
      BitcoinOutput(
        address: fund.baseAddress,
        value: utxos.sumOfUtxosValue() - tokenDust - exampleFee,
      ),
    ],
    fee: exampleFee,
    network: network,
    utxos: utxos,

    /// Keep the genesis output at index 0.
    outputOrdering: BitcoinOrdering.none,
  ).buildTransaction((digest, utxo, publicKey, sighash) {
    return wallet.privateKey.signECDSA(digest, sighash: sighash);
  });

  /// The category id is the txid whose output 0 gets spent by the mint.
  final category = await broadcastAndConfirm(
    provider,
    node,
    makeVout0,
    mining.confirm,
  );
  print('category setup tx: $category');
  print('token category:    $category');
  print('');

  /// ---- 3. mint one mutable NFT ------------------------------------------
  final current = await readUtxos(provider, wallet, fund);
  final genesisUtxo = current.firstWhere(
    (utxo) => isGenesisOutput(utxo, category),
  );
  final feeUtxo = largestUtxo(
    current.where((utxo) => !isGenesisOutput(utxo, category)).toList(),
  );

  final commitment = 'regtest nft'.codeUnits;
  final nftToken = CashToken(
    category: category,

    /// An NFT carries no amount.
    commitment: commitment,
    bitfield: CashTokenUtils.buildBitfield(
      hasNFT: true,
      capability: CashTokenCapability.mutable,
      hasCommitmentLength: true,
    ),
  );

  /// The genesis output is spent, so the mint is a genesis mint for `category`.
  final mintUtxos = [genesisUtxo, feeUtxo];
  final mint = ForkedTransactionBuilder(
    outPuts: [
      BitcoinTokenOutput(
        utxoHash: category,
        address: fund.baseAddress,
        value: tokenDust,
        token: nftToken,
      ),
      BitcoinOutput(
        address: fund.baseAddress,
        value: mintUtxos.sumOfUtxosValue() - tokenDust - exampleFee,
      ),
    ],
    fee: exampleFee,
    network: network,
    utxos: mintUtxos,

    /// Keep the token output at index 0.
    outputOrdering: BitcoinOrdering.none,
  ).buildTransaction((digest, utxo, publicKey, sighash) {
    return wallet.privateKey.signECDSA(digest, sighash: sighash);
  });
  final mintId = await broadcastAndConfirm(
    provider,
    node,
    mint,
    mining.confirm,
  );
  print('mint tx:           $mintId');

  final minted = (await readUtxos(provider, wallet, fund, true))
      .where(
        (utxo) =>
            utxo.utxo.token != null &&
            utxo.utxo.token!.category == category &&
            utxo.utxo.token!.hasNFT,
      )
      .toList();
  final nftUtxo = minted.first;
  final nft = nftUtxo.utxo.token!;
  print('minted NFT:        capability=${nft.capability!.name} '
      'commitment="${String.fromCharCodes(nft.commitment)}"');
  print('');

  /// ---- 4. transfer the NFT ----------------------------------------------
  /// An NFT output must keep the value it came in with.
  final bchUtxos = (await readUtxos(provider, wallet, fund))
      .where((utxo) => utxo.utxo.token == null)
      .toList();
  final allUtxos = [...bchUtxos, nftUtxo];

  final transfer = ForkedTransactionBuilder(
    outPuts: [
      BitcoinTokenOutput(
        utxoHash: nftUtxo.utxo.txHash,
        address: receiverTokenAddress.baseAddress,
        value: nftUtxo.utxo.value,
        token: nft,
      ),
      BitcoinOutput(
        address: fund.baseAddress,
        value: allUtxos.sumOfUtxosValue() - nftUtxo.utxo.value - exampleFee,
      ),
    ],
    fee: exampleFee,
    network: network,
    utxos: allUtxos,
    outputOrdering: BitcoinOrdering.none,
  ).buildTransaction((digest, utxo, publicKey, sighash) {
    return wallet.privateKey.signECDSA(digest, sighash: sighash);
  });
  final transferId = await broadcastAndConfirm(
    provider,
    node,
    transfer,
    mining.confirm,
  );
  print('transfer tx:       $transferId');
  print('');

  final received = (await readUtxos(
    provider,
    receiver,
    receiverTokenAddress,
    true,
  ))
      .where(
    (utxo) =>
        utxo.utxo.token != null &&
        utxo.utxo.token!.category == category &&
        utxo.utxo.token!.hasNFT,
  );
  for (final utxo in received) {
    final token = utxo.utxo.token!;
    print('receiver NFT:      capability=${token.capability!.name} '
        'commitment="${String.fromCharCodes(token.commitment)}" '
        'value=${formatCoins(utxo.utxo.value)} BCH');
  }

  await service.close();
  print('');
  print('done.');
}
