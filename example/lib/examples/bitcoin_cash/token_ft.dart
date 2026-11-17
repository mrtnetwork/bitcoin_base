// Bitcoin Cash regtest: CashToken fungible tokens (category, mint 1000 TDT, transfer).

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:example/examples/local/local_node.dart';

/// Value of a token-carrying output: enough to cover its own size, as required
/// by the CashToken spec.
final BigInt tokenDust = BtcUtils.toSatoshi('0.000015');

/// Total amount of [category] held across [utxos].
BigInt _tokenBalance(List<UtxoWithAddress> utxos, String category) {
  return utxos.fold<BigInt>(BigInt.zero, (sum, utxo) {
    final token = utxo.utxo.token;
    if (token == null || token.category != category) return sum;
    return sum + token.amount;
  });
}

Future<void> main() async {
  const network = BitcoinCashNetwork.regtest;
  final node = RegtestNode.bitcoinCash;
  final mining = Mining(network);

  final service = await node.connectElectrum();
  final provider = BitcoinProvider(service);
  final wallet = LocalWallet(index: 20, network: network);
  final receiver = LocalWallet(index: 21, network: network);

  final fund = wallet.addressFor(P2pkhAddressType.p2pkh);
  final receiverTokenAddress = receiver.addressFor(P2pkhAddressType.p2pkhwt);

  print('Bitcoin Cash regtest: CashToken FT');
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
  final remaining = utxos.sumOfUtxosValue() - tokenDust - exampleFee;
  final makeVout0 = ForkedTransactionBuilder(
    outPuts: [
      /// Output 0 is the genesis input of the category.
      BitcoinOutput(address: fund.baseAddress, value: tokenDust),
      BitcoinOutput(address: fund.baseAddress, value: remaining),
    ],
    fee: exampleFee,
    network: network,
    utxos: utxos,

    /// Keep the genesis output at index 0.
    outputOrdering: BitcoinOrdering.none,
  ).buildTransaction((digest, utxo, publicKey, sighash) {
    return wallet.privateKey.signECDSA(digest, sighash: sighash);
  });
  final makeVout0Id = await broadcastAndConfirm(
    provider,
    node,
    makeVout0,
    mining.confirm,
  );
  print('category setup tx: $makeVout0Id');

  /// The category id is the txid of the transaction whose output 0 is spent by
  /// the minting transaction.
  final category = makeVout0Id;
  print('token category:    $category');
  print('');

  /// ---- 3. mint -----------------------------------------------------------
  /// The genesis input (output 0 of the setup transaction) must be spent by the
  /// minting transaction itself; that is what makes the category valid.
  final genesisUtxo = (await readUtxos(provider, wallet, fund))
      .firstWhere((utxo) => utxo.utxo.txHash == makeVout0Id);
  final feeUtxos = (await readUtxos(provider, wallet, fund))
      .where((utxo) => utxo.utxo.vout != 0)
      .toList();
  final mintUtxos = [genesisUtxo, largestUtxo(feeUtxos)];
  final minted = BigInt.from(1000);
  final mintToken = CashToken(
    category: category,
    amount: minted,
    bitfield: CashTokenUtils.buildBitfield(hasAmount: true),
  );
  final mint = ForkedTransactionBuilder(
    outPuts: [
      BitcoinTokenOutput(
        /// Any token output must name the genesis outpoint it derives from.
        utxoHash: category,
        address: fund.baseAddress,
        value: tokenDust,
        token: mintToken,
      ),
      BitcoinOutput(
        address: fund.baseAddress,
        value: mintUtxos.sumOfUtxosValue() - tokenDust - exampleFee,
      ),
    ],
    fee: exampleFee,
    network: network,
    utxos: mintUtxos,
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

  final tokenUtxo = (await readUtxos(provider, wallet, fund, true)).firstWhere(
    (utxo) => utxo.utxo.token != null && utxo.utxo.token!.category == category,
  );

  /// Sum the sender's balance of the new category; older categories are ignored.
  final mintedTotal = _tokenBalance(
    await readUtxos(provider, wallet, fund, true),
    category,
  );
  print('wallet TDT:        $mintedTotal');
  print('');

  /// ---- 4. transfer -------------------------------------------------------
  /// The token input plus a plain BCH input for the fee.
  final bchUtxos = (await readUtxos(provider, wallet, fund))
      .where((utxo) => utxo.utxo.token == null)
      .toList();
  final allUtxos = [...bchUtxos, tokenUtxo];
  final sendAmount = BigInt.from(100);
  final token = tokenUtxo.utxo.token!;

  final transfer = ForkedTransactionBuilder(
    outPuts: [
      /// 100 TDT to the receiver.
      BitcoinTokenOutput(
        utxoHash: tokenUtxo.utxo.txHash,
        address: receiverTokenAddress.baseAddress,
        value: tokenDust,
        token: token.copyWith(amount: sendAmount),
      ),

      /// The remaining 900 TDT back to the sender.
      BitcoinTokenOutput(
        utxoHash: tokenUtxo.utxo.txHash,
        address: fund.baseAddress,
        value: tokenDust,
        token: token.copyWith(amount: token.amount - sendAmount),
      ),
      BitcoinOutput(
        address: fund.baseAddress,
        value: allUtxos.sumOfUtxosValue() - tokenDust * BigInt.two - exampleFee,
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

  final receivedTotal = _tokenBalance(
    await readUtxos(provider, receiver, receiverTokenAddress, true),
    category,
  );
  print('receiver TDT:      $receivedTotal (category $category)');

  await service.close();
  print('');
  print('done.');
}
