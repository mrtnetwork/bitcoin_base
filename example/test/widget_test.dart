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
  // // print(account.multiSigScript.script);
  // // return;

  // /// connect to electrum service with websocket
  // /// please see `services_examples` folder for how to create electrum websocket service
  // final service = await ElectrumWebSocketService.connect(
  //     "wss://chipnet.imaginary.cash:50004");

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
  // final bchTransaction = ForkedTransactionBuilder(
  //   outPuts: [
  //     /// change input (sumofutxos - spend)
  //     BitcoinOutput(
  //       address: addr,
  //       value: sumOfUtxo -
  //           (BtcUtils.toSatoshi("0.0001") + BtcUtils.toSatoshi("0.00003")),
  //     ),
  //     BitcoinOutput(
  //       address: BitcoinCashAddress(
  //               "bchtest:pw054wtjjc70rrvx4ftl4p63gluedyt0qmpgz705f8x3gxygrzarzls7vp2sj",
  //               network: BitcoinCashNetwork.testnet)
  //           .baseAddress,
  //       value: BtcUtils.toSatoshi("0.0001"),
  //     ),
  //   ],
  //   fee: BtcUtils.toSatoshi("0.00003"),
  //   network: BitcoinCashNetwork.testnet,
  //   utxos: utxos,
  // );
  // final transaaction =
  //     bchTransaction.buildTransaction((trDigest, utxo, publicKey, sighash) {
  //   final sing = keys[publicKey]!.signInput(trDigest, sigHash: sighash);
  //   print("=====================");
  //   print("key ${keys[publicKey]?.prive.toHex()}");
  //   print("diget ${BytesUtils.toHexString(trDigest)}");
  //   print("sign ${sing}");
  //   print("Sighash $sighash");

  //   return keys[publicKey]!.signInput(trDigest, sigHash: sighash);
  // });

  // /// transaction ID
  // transaaction.txId();

  // /// for calculation fee
  // transaaction.getSize();

  // /// raw of encoded transaction in hex
  // final transactionRaw = transaaction.toHex();
  // print(transactionRaw);
  // return;
  // // print(elctrumUtxos.length);
  // final d = await provider
  //     .request(ElectrumBroadCastTransaction(transactionRaw: transactionRaw));
  // print(d);
}
