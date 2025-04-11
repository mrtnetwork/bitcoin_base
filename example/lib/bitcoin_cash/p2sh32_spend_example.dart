import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/services_examples/electrum/electrum_websocket_service.dart';

/// CHIP-2022-05 Pay-to-Script-Hash-32 (P2SH32) for Bitcoin Cash
/// https://bitcoincashresearch.org/t/chip-2022-05-pay-to-script-hash-32-p2sh32-for-bitcoin-cash/806
/// Send funds to a BCH P2SH32 address.
void main() async {
  /// connect to electrum service with websocket
  /// please see `services_examples` folder for how to create electrum websocket service
  final service = await ElectrumWebSocketService.connect(
      "wss://chipnet.imaginary.cash:50004");

  /// create provider with service
  final provider = ElectrumProvider(service);

  /// initialize private key
  final privateKey = ECPrivate.fromBytes(BytesUtils.fromHexString(
      "f9061c5cb343c6b6a73900ee29509bb0bd2213319eea46d2f2a431068c9da06b"));

  /// public key
  final publicKey = privateKey.getPublic();

  /// network
  const network = BitcoinCashNetwork.testnet;

  /// Derives a P2PKH address from the given public key and converts it to a Bitcoin Cash address
  /// for enhanced accessibility within the network.
  final p2pkhAddress =
      BitcoinCashAddress.fromBaseAddress(publicKey.toAddress());

  /// Initialize two P2SH32 addresses for receiving funds.
  /// bchtest:pvw39llgap0a4vm8jn9sjsvfsthah4wgemjlh6epdtzr3pl2fqtmsn3s4vcm7
  /// Avoid using `BitcoinCashAddress('address')` when obtaining the address type for `UtxoWithAddress`.
  /// This is crucial for spending, as the current P2SH type is needed for unlocking the script.
  final p2sh32Example1 = BitcoinCashAddress.fromBaseAddress(
      publicKey.toP2pkhInP2sh(useBCHP2sh32: true));

  /// bchtest:pw054wtjjc70rrvx4ftl4p63gluedyt0qmpgz705f8x3gxygrzarzls7vp2sj
  /// Avoid using `BitcoinCashAddress('address')` when obtaining the address type for `UtxoWithAddress`.
  /// This is crucial for spending, as the current P2SH type is needed for unlocking the script.
  final p2sh32Example2 = BitcoinCashAddress.fromBaseAddress(
      publicKey.toP2pkInP2sh(useBCHP2sh32: true));

  /// Reads all UTXOs (Unspent Transaction Outputs) associated with the account.
  /// We does not need tokens utxo and we set to false.
  final example1ElectrumUtxos =
      await provider.request(ElectrumRequestScriptHashListUnspent(
    scriptHash: p2sh32Example1.baseAddress.pubKeyHash(),
    includeTokens: false,
  ));
  final example2ElectrumUtxos =
      await provider.request(ElectrumRequestScriptHashListUnspent(
    scriptHash: p2sh32Example2.baseAddress.pubKeyHash(),
    includeTokens: false,
  ));

  /// Converts all UTXOs to a list of UtxoWithAddress, containing UTXO information along with address details.
  final List<UtxoWithAddress> utxos = [
    ...example2ElectrumUtxos
        .map((e) => UtxoWithAddress(
            utxo: e.toUtxo(p2sh32Example2.type),
            ownerDetails: UtxoAddressDetails(
                publicKey: publicKey.toHex(),
                address: p2pkhAddress.baseAddress)))
        .toList(),
    ...example1ElectrumUtxos
        .map((e) => UtxoWithAddress(
            utxo: e.toUtxo(p2sh32Example1.type),
            ownerDetails: UtxoAddressDetails(
                publicKey: publicKey.toHex(),
                address: p2pkhAddress.baseAddress)))
        .toList()
  ];

  /// som of utxos in satoshi
  final sumOfUtxo = utxos.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    return;
  }
  final bchTransaction = ForkedTransactionBuilder(
    outPuts: [
      BitcoinOutput(
        address: p2pkhAddress.baseAddress,
        value: BtcUtils.toSatoshi("0.00001"),
      ),

      /// change input (sumofutxos - spend)
      BitcoinOutput(
        address: p2sh32Example1.baseAddress,
        value: sumOfUtxo -
            (BtcUtils.toSatoshi("0.00001") + BtcUtils.toSatoshi("0.00003")),
      ),
    ],
    fee: BtcUtils.toSatoshi("0.00003"),
    network: network,
    utxos: utxos,
  );
  final transaaction =
      bchTransaction.buildTransaction((trDigest, utxo, publicKey, sighash) {
    return privateKey.signECDSA(trDigest, sighash: sighash);
  });

  /// transaction ID
  transaaction.txId();

  /// for calculation fee
  transaaction.getSize();

  /// raw of encoded transaction in hex
  final transactionRaw = transaaction.toHex();

  /// send transaction to network
  await provider.request(
      ElectrumRequestBroadCastTransaction(transactionRaw: transactionRaw));

  /// done! check the transaction in block explorer
  ///  https://chipnet.imaginary.cash/tx/b76b851ce0374504591db414d7469aadb68649079defb26e44c62e970afda729
}
