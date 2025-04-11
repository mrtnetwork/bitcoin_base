import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:example/services_examples/electrum/electrum_ssl_service.dart';

/// If you are working with different networks,
/// you can apply this tutorial universally.
/// Simply replace the usage of BitcoinTransactionBuilder with
/// ForkedTransactionBuilder when sending
/// transactions on the Bitcoin Cash or Bitcoin SV network.

/// Another key distinction lies in the addressing formats.
/// For instance, the Litecoin network does not support P2TR,
/// while networks such as Dash, Dogecoin,
/// and Bitcoin Cash exclusively support legacy addresses (P2PKH and P2SH).
/// On the other hand, the Bitcoin SV network exclusively supports P2PKH addresses.
void main() async {
  /// connect to electrum service with websocket
  /// please see `services_examples` folder for how to create electrum websocket service
  final service =
      await ElectrumSSLService.connect("testnet.aranguren.org:51002");

  /// create provider with service
  final provider = ElectrumProvider(service);

  /// spender details
  final privateKey = ECPrivate.fromHex(
      "76257aafc9b954351c7f6445b2d07277f681a5e83d515a1f32ebf54989c2af4f");
  final examplePublicKey = privateKey.getPublic();
  final spender1 = examplePublicKey.toAddress();
  final spender2 = examplePublicKey.toSegwitAddress();
  final spender3 = examplePublicKey.toTaprootAddress();
  final spender4 = examplePublicKey.toP2pkhInP2sh();
  final spender5 = examplePublicKey.toP2pkInP2sh();
  final spender6 = examplePublicKey.toP2wshAddress();
  final spender7 = examplePublicKey.toP2wpkhInP2sh();
  final List<BitcoinBaseAddress> spenders = [
    spender1,
    spender2,
    spender3,
    spender4,
    spender5,
    spender6,
    spender7,
  ];

  const network = BitcoinNetwork.testnet;
  final List<UtxoWithAddress> accountsUtxos = [];

  /// loop each spenders address and get utxos and add to accountsUtxos
  for (final i in spenders) {
    /// Reads all UTXOs (Unspent Transaction Outputs) associated with the account
    final elctrumUtxos = await provider.request(
        ElectrumRequestScriptHashListUnspent(scriptHash: i.pubKeyHash()));

    /// Converts all UTXOs to a list of UtxoWithAddress, containing UTXO information along with address details.
    /// read spender utxos
    final List<UtxoWithAddress> utxos = elctrumUtxos
        .map((e) => UtxoWithAddress(
            utxo: e.toUtxo(i.type),
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey.toHex(), address: i)))
        .toList();
    accountsUtxos.addAll(utxos);
  }

  /// get sum of values
  final sumOfUtxo = accountsUtxos.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    return;
  }

  final examplePublicKey2 = ECPublic.fromHex(
      "02d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546");

  /// When creating outputs with an address, I utilize the public key. Alternatively, an address class, such as
  /// P2pkhAddress.fromAddress(address: ".....", network: network);
  /// P2trAddress.fromAddress(address: "....", network: network)
  /// ....
  final List<BitcoinOutput> outPuts = [
    BitcoinOutput(
        address: examplePublicKey2.toSegwitAddress(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey2.toTaprootAddress(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey2.toP2pkhInP2sh(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey2.toP2pkInP2sh(),
        value: BtcUtils.toSatoshi("0.00001")),
    BitcoinOutput(
        address: examplePublicKey2.toP2wshAddress(),
        value: BtcUtils.toSatoshi("0.00001")),
  ];

  /// OP_RETURN
  const String memo = "https://github.com/mrtnetwork";

  /// SUM OF OUTOUT AMOUNTS
  final sumOfOutputs = outPuts.fold(
      BigInt.zero, (previousValue, element) => previousValue + element.value);

  /// Estimate transaction size
  int transactionSize = BitcoinTransactionBuilder.estimateTransactionSize(
      utxos: accountsUtxos,
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

  /// get network fee esmtimate (fee per kilobyte)
  final networkEstimate = await provider.request(ElectrumRequestEstimateFee());

  /// the daemon does not have enough information to make an estimate
  if (networkEstimate == null) {
    return;
  }

  /// Convert kilobytes to bytes, multiply by the transaction size, and the result yields the transaction fees.
  final fee =
      BigInt.from(transactionSize) * (networkEstimate ~/ BigInt.from(1000));

  /// change value
  final changeValue = sumOfUtxo - (sumOfOutputs + fee);

  if (changeValue.isNegative) {
    return;
  }
  //// if we have change value we back amount to account
  if (changeValue > BigInt.zero) {
    outPuts.add(BitcoinOutput(
        address: examplePublicKey2.toAddress(), value: changeValue));
  }

  /// create transaction builder
  final builder = BitcoinTransactionBuilder(
      outPuts: outPuts,
      fee: fee,
      network: network,
      utxos: accountsUtxos,
      memo: memo,
      inputOrdering: BitcoinOrdering.bip69,
      outputOrdering: BitcoinOrdering.bip69,
      enableRBF: true);

  /// create transaction and sign it
  final transaction =
      builder.buildTransaction((trDigest, utxo, publicKey, sighash) {
    if (utxo.utxo.isP2tr) {
      return privateKey.signBip340(trDigest, sighash: sighash);
    }
    return privateKey.signECDSA(trDigest, sighash: sighash);
  });

  /// get tx id
  transaction.txId();

  /// get transaction encoded data
  final raw = transaction.serialize();

  /// send to network
  await provider
      .request(ElectrumRequestBroadCastTransaction(transactionRaw: raw));

  /// Once completed, we verify the status by checking the mempool or using another explorer to review the transaction details.
  /// https://mempool.space/testnet/tx/70cf664bba4b5ac9edc6133e9c6891ffaf8a55eaea9d2ac99aceead1c3db8899
}
