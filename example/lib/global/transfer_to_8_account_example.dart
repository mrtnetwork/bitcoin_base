import 'package:bitcoin_base/bitcoin_base.dart';

import 'package:example/services_examples/electrum/electrum_ssl_service.dart';

void main() async {
  /// connect to electrum service with websocket
  /// please see `services_examples` folder for how to create electrum websocket service
  final service =
      await ElectrumSSLService.connect("testnet.aranguren.org:51002");

  /// create provider with service
  final provider = ElectrumProvider(service);

  /// spender details
  /// Define another private key from wif
  final ECPrivate examplePrivateKey2 = ECPrivate.fromWif(
      'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
      netVersion: BitcoinNetwork.testnet.wifNetVer);
  final examplePublicKey2 = examplePrivateKey2.getPublic();
  final p2pkhAddress = examplePublicKey2.toAddress();

  /// receiver addresses i use public key for generate address
  final examplePublicKey = ECPublic.fromHex(
      "032a4f8be9ebffb46e2c6a1c240702553b9c9c8ad9638650833d07d5d22f618621");

  const network = BitcoinNetwork.testnet;

  /// Reads all UTXOs (Unspent Transaction Outputs) associated with the account
  final elctrumUtxos = await provider.request(
      ElectrumRequestScriptHashListUnspent(
          scriptHash: examplePublicKey2.toAddress().pubKeyHash()));

  /// Converts all UTXOs to a list of UtxoWithAddress, containing UTXO information along with address details.
  /// read spender utxos
  final List<UtxoWithAddress> utxos = elctrumUtxos
      .map((e) => UtxoWithAddress(
          utxo: e.toUtxo(p2pkhAddress.type),
          ownerDetails: UtxoAddressDetails(
              publicKey: examplePublicKey2.toHex(), address: p2pkhAddress)))
      .toList();

  /// get sum of values
  final sumOfUtxo = utxos.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    return;
  }

  /// When creating outputs with an address, I utilize the public key. Alternatively, an address class, such as
  /// P2pkhAddress.fromAddress(address: ".....", network: network);
  /// P2trAddress.fromAddress(address: "....", network: network)
  /// ....
  final List<BitcoinOutput> outPuts = [
    BitcoinOutput(
        address: examplePublicKey.toAddress(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey.toSegwitAddress(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey.toTaprootAddress(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey.toP2pkhInP2sh(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey.toP2pkInP2sh(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey.toP2wshAddress(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey.toP2wpkhInP2sh(),
        value: BtcUtils.toSatoshi("0.00001")),
  ];

  /// OP_RETURN
  const String memo = "https://github.com/mrtnetwork";

  /// SUM OF OUTOUT AMOUNTS
  final sumOfOutputs = outPuts.fold(
      BigInt.zero, (previousValue, element) => previousValue + element.value);

  /// ESTIMATE TRANSACTION SIZE
  int estimateSize = BitcoinTransactionBuilder.estimateTransactionSize(
      utxos: utxos,
      outputs: [
        ...outPuts,

        /// I add more output for change value to get correct transaction size
        BitcoinOutput(
            address: examplePublicKey2.toAddress(), value: BigInt.zero)
      ],

      /// network
      network: network,

      /// memp
      memo: memo,

      /// rbf
      enableRBF: true);

  /// get network fee esmtimate (kb/s)
  final networkEstimate = await provider.request(ElectrumRequestEstimateFee());

  /// the daemon does not have enough information to make an estimate
  if (networkEstimate == null) {
    return;
  }

  /// kb to bytes and mul with transaction size and now we have fee
  final fee =
      BigInt.from(estimateSize) * (networkEstimate ~/ BigInt.from(1000));

  /// change value
  final changeValue = sumOfUtxo - (sumOfOutputs + fee);

  if (changeValue.isNegative) return;
  //// if we have change value we back amount to account
  if (changeValue > BigInt.zero) {
    final changeOutput = BitcoinOutput(
        address: examplePublicKey2.toAddress(), value: changeValue);
    outPuts.add(changeOutput);
  }

  /// create transaction builder
  final builder = BitcoinTransactionBuilder(
      outPuts: outPuts,
      fee: fee,
      network: network,
      utxos: utxos,
      memo: memo,
      inputOrdering: BitcoinOrdering.bip69,
      outputOrdering: BitcoinOrdering.bip69,
      enableRBF: true);

  /// create transaction and sign it
  final transaction =
      builder.buildTransaction((trDigest, utxo, publicKey, sighash) {
    if (utxo.utxo.isP2tr) {
      return examplePrivateKey2.signBip340(trDigest, sighash: sighash);
    }
    return examplePrivateKey2.signECDSA(trDigest, sighash: sighash);
  });

  /// get tx id
  transaction.txId();

  /// get transaction encoded data
  final raw = transaction.serialize();

  /// send to network
  await provider
      .request(ElectrumRequestBroadCastTransaction(transactionRaw: raw));

  /// Once completed, we verify the status by checking the mempool or using another explorer to review the transaction details.
  /// https://mempool.space/testnet/tx/abab018f3d2b92bf30c63b4aca419cf6d6571692b3620f06311c7e5a21a88b56
}
