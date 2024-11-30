void main() async {
  // final one = ECPrivate.fromBytes(List<int>.filled(32, 12));
  // final two = ECPrivate.fromBytes(List<int>.filled(32, 13));
  // final three = ECPrivate.fromBytes(List<int>.filled(32, 14));
  // final four = ECPrivate.fromBytes(List<int>.filled(32, 15));
  // final five = ECPrivate.fromBytes(List<int>.filled(32, 16));
  // final six = ECPrivate.fromBytes(List<int>.filled(32, 17));
  // final seven = ECPrivate.fromBytes(List<int>.filled(32, 18));
  // final eight = ECPrivate.fromBytes(List<int>.filled(32, 19));
  // final Map<String, ECPrivate> keys = {
  //   for (final i in [one, two, three, four, five, six, seven, eight])
  //     i.getPublic().toHex(): i
  // };
  // final account = MultiSignatureAddress(threshold: 8, signers: [
  //   MultiSignatureSigner(publicKey: one.getPublic().toHex(), weight: 1),
  //   MultiSignatureSigner(publicKey: two.getPublic().toHex(), weight: 1),
  //   MultiSignatureSigner(publicKey: three.getPublic().toHex(), weight: 1),
  //   MultiSignatureSigner(publicKey: four.getPublic().toHex(), weight: 1),
  //   MultiSignatureSigner(publicKey: five.getPublic().toHex(), weight: 1),
  //   MultiSignatureSigner(publicKey: six.getPublic().toHex(), weight: 1),
  //   MultiSignatureSigner(publicKey: seven.getPublic().toHex(), weight: 1),
  //   MultiSignatureSigner(publicKey: eight.getPublic().toHex(), weight: 1),
  // ]);
  // final addr = account.toP2shAddress();
  // // return;

  // /// connect to electrum service with websocket
  // /// please see `services_examples` folder for how to create electrum websocket service
  // final service = await ElectrumSSLService.connect(
  //     "testnet4-electrumx.wakiyamap.dev:51002");

  // /// create provider with service
  // final provider = ElectrumApiProvider(service);

  // final elctrumUtxos = await provider.request(ElectrumScriptHashListUnspent(
  //   scriptHash: addr.pubKeyHash(),
  //   includeTokens: false,
  // ));
  // final List<UtxoWithAddress> utxos = elctrumUtxos
  //     .map((e) => UtxoWithAddress(
  //         utxo: e.toUtxo(addr.type),
  //         ownerDetails: UtxoAddressDetails.multiSigAddress(
  //             multiSigAddress: account, address: addr)))
  //     .toList();

  // final sumOfUtxo = utxos.sumOfUtxosValue();
  // if (sumOfUtxo == BigInt.zero) {
  //   return;
  // }
  // final addrOne = one.getPublic().toP2pkAddress(compressed: false);
  // final addrTwo = two.getPublic().toAddress(compressed: false);
  // final addrThree = three.getPublic().toP2pkInP2sh(compressed: false);
  // final addrFour = four.getPublic().toP2pkhInP2sh(compressed: false);
  // final addrFive = four.getPublic().toSegwitAddress();
  // final addrSix = four.getPublic().toP2wshInP2sh();
  // // print(sumOfUtxo);
  // // return;
  // final bchTransaction = BitcoinTransactionBuilder(
  //   outPuts: [
  //     /// change input (sumofutxos - spend)
  //     BitcoinOutput(
  //       address: addr,
  //       value: sumOfUtxo -
  //           (BigInt.from(1000) * BigInt.from(7) + BigInt.from(2200)),
  //     ),
  //     BitcoinOutput(
  //       address: addrOne,
  //       value: BigInt.from(1000),
  //     ),
  //     BitcoinOutput(
  //       address: addrTwo,
  //       value: BigInt.from(1000),
  //     ),
  //     BitcoinOutput(
  //       address: addrThree,
  //       value: BigInt.from(1000),
  //     ),
  //     BitcoinOutput(
  //       address: addrFour,
  //       value: BigInt.from(1000),
  //     ),
  //     BitcoinOutput(
  //       address: addrFour,
  //       value: BigInt.from(1000),
  //     ),
  //     BitcoinOutput(
  //       address: addrFive,
  //       value: BigInt.from(1000),
  //     ),
  //     BitcoinOutput(
  //       address: addrSix,
  //       value: BigInt.from(1000),
  //     ),
  //   ],
  //   fee: BigInt.from(2200),
  //   network: BitcoinNetwork.testnet,
  //   utxos: utxos,
  // );
  // final transaaction =
  //     bchTransaction.buildTransaction((trDigest, utxo, publicKey, sighash) {
  //   return keys[publicKey]!.signInput(trDigest, sigHash: sighash);
  // });

  // /// transaction ID
  // transaaction.txId();

  // /// for calculation fee
  // print(transaaction.getSize());
  // // return;

  // /// raw of encoded transaction in hex
  // final transactionRaw = transaaction.toHex();
  // print(transactionRaw);
  // // print(elctrumUtxos.length);
  // final d = await provider
  //     .request(ElectrumBroadCastTransaction(transactionRaw: transactionRaw));
  // print(d);
}
