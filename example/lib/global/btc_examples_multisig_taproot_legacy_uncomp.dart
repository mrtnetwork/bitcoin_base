import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:example/services_examples/electrum/electrum_ssl_service.dart';

void main() async {
  final one = ECPrivate.fromBytes(List<int>.filled(32, 12));
  final two = ECPrivate.fromBytes(List<int>.filled(32, 13));
  final three = ECPrivate.fromBytes(List<int>.filled(32, 14));
  final four = ECPrivate.fromBytes(List<int>.filled(32, 15));
  final five = ECPrivate.fromBytes(List<int>.filled(32, 16));
  final six = ECPrivate.fromBytes(List<int>.filled(32, 17));
  final seven = ECPrivate.fromBytes(List<int>.filled(32, 18));
  final eight = ECPrivate.fromBytes(List<int>.filled(32, 19));
  final Map<String, ECPrivate> keys = {
    for (final i in [one, two, three, four, five, six, seven, eight])
      i.getPublic().toHex(): i
  };
  final account = MultiSignatureAddress(threshold: 8, signers: [
    MultiSignatureSigner(
        publicKey: one.getPublic().toHex(mode: PublicKeyType.uncompressed),
        weight: 1),
    MultiSignatureSigner(publicKey: two.getPublic().toHex(), weight: 1),
    MultiSignatureSigner(publicKey: three.getPublic().toHex(), weight: 1),
    MultiSignatureSigner(
        publicKey: four.getPublic().toHex(mode: PublicKeyType.uncompressed),
        weight: 1),
    MultiSignatureSigner(publicKey: five.getPublic().toHex(), weight: 1),
    MultiSignatureSigner(publicKey: six.getPublic().toHex(), weight: 1),
    MultiSignatureSigner(
        publicKey: seven.getPublic().toHex(mode: PublicKeyType.uncompressed),
        weight: 1),
    MultiSignatureSigner(publicKey: eight.getPublic().toHex(), weight: 1),
  ]);

  /// connect to electrum service with websocket
  /// please see `services_examples` folder for how to create electrum websocket service
  final service = await ElectrumSSLService.connect(
      "testnet4-electrumx.wakiyamap.dev:51002");

  /// create provider with service
  final provider = ElectrumProvider(service);

  final addrOne =
      one.getPublic().toP2pkAddress(mode: PublicKeyType.uncompressed);

  final addrTwo = two.getPublic().toAddress(mode: PublicKeyType.uncompressed);

  final addrThree =
      three.getPublic().toP2pkInP2sh(mode: PublicKeyType.uncompressed);
  final addrFour =
      four.getPublic().toP2pkhInP2sh(mode: PublicKeyType.uncompressed);
  final addrFive = four.getPublic().toSegwitAddress();
  final addrSix = account.toP2shAddress();
  final addr7 = eight.getPublic().toTaprootAddress();
  final addr8 = eight.getPublic().toP2wshAddress();
  final addr9 = eight.getPublic().toP2wshInP2sh();
  final List<String> pubkys = [
    one.getPublic().toHex(mode: PublicKeyType.uncompressed),
    two.getPublic().toHex(mode: PublicKeyType.uncompressed),
    three.getPublic().toHex(mode: PublicKeyType.uncompressed),
    four.getPublic().toHex(mode: PublicKeyType.uncompressed),
    four.getPublic().toHex(),
    four.getPublic().toHex(),
    eight.getPublic().toHex(),
    eight.getPublic().toHex(),
    eight.getPublic().toHex(),
    eight.getPublic().toHex(),
  ];
  final addresses = [
    one.getPublic().toP2pkAddress(mode: PublicKeyType.uncompressed),
    two.getPublic().toAddress(mode: PublicKeyType.uncompressed),
    three.getPublic().toP2pkInP2sh(mode: PublicKeyType.uncompressed),
    four.getPublic().toP2pkhInP2sh(mode: PublicKeyType.uncompressed),
    four.getPublic().toSegwitAddress(),
    four.getPublic().toP2wshInP2sh(),
    addrSix,
    addr7,
    addr8,
    addr9
  ];
  List<UtxoWithAddress> utxos = [];
  for (int i = 0; i < addresses.length; i++) {
    final address = addresses[i];
    final elctrumUtxos = await provider.request(
        ElectrumRequestScriptHashListUnspent(
            scriptHash: address.pubKeyHash(), includeTokens: false));
    if (elctrumUtxos.isEmpty) continue;
    if (i == 6) {
      utxos.addAll(elctrumUtxos.map((e) => UtxoWithAddress(
          utxo: e.toUtxo(address.type),
          ownerDetails: UtxoAddressDetails.multiSigAddress(
              multiSigAddress: account, address: address))));
      continue;
    }
    utxos.addAll(elctrumUtxos
        .map((e) => UtxoWithAddress(
            utxo: e.toUtxo(address.type),
            ownerDetails:
                UtxoAddressDetails(publicKey: pubkys[i], address: address)))
        .toList());
  }

  final sumOfUtxo = utxos.sumOfUtxosValue();

  if (sumOfUtxo == BigInt.zero) {
    return;
  }
  final change =
      sumOfUtxo - (BigInt.from(1000) * BigInt.from(11) + BigInt.from(4295));
  final bchTransaction = BitcoinTransactionBuilder(outPuts: [
    /// change input (sumofutxos - spend)
    BitcoinOutput(address: addrOne, value: change),
    BitcoinOutput(address: addrOne, value: BigInt.from(1000)),
    BitcoinOutput(address: addrTwo, value: BigInt.from(1000)),
    BitcoinOutput(address: addrThree, value: BigInt.from(1000)),
    BitcoinOutput(address: addrFour, value: BigInt.from(1000)),
    BitcoinOutput(address: addrFour, value: BigInt.from(1000)),
    BitcoinOutput(address: addrFive, value: BigInt.from(1000)),
    BitcoinOutput(address: addrSix, value: BigInt.from(1000)),
    BitcoinOutput(address: addrSix, value: BigInt.from(1000)),
    BitcoinOutput(address: addr7, value: BigInt.from(1000)),
    BitcoinOutput(address: addr8, value: BigInt.from(1000)),
    BitcoinOutput(address: addr9, value: BigInt.from(1000)),
  ], fee: BigInt.from(4295), network: BitcoinNetwork.testnet, utxos: utxos);
  final transaaction =
      bchTransaction.buildTransaction((trDigest, utxo, publicKey, sighash) {
    final pk = ECPublic.fromHex(publicKey);
    if (utxo.utxo.isP2tr) {
      return keys[pk.toHex()]!.signBip340(trDigest, sighash: sighash);
    }
    return keys[pk.toHex()]!.signECDSA(trDigest, sighash: sighash);
  });

  final transactionRaw = transaaction.toHex();
  await provider.request(
      ElectrumRequestBroadCastTransaction(transactionRaw: transactionRaw));
}

/// https://mempool.space/testnet4/tx/a7f08f07739de45a6a4f8871f8e6ad79e0aefbc940086df76571354ba22263fa
