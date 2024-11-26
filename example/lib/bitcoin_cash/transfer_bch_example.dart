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
  final provider = ElectrumApiProvider(service);

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
  final p2sh32Example1 = BitcoinCashAddress(
      "bchtest:pw054wtjjc70rrvx4ftl4p63gluedyt0qmpgz705f8x3gxygrzarzls7vp2sj",
      network: network);
  final p2sh32Example2 = BitcoinCashAddress(
      "bchtest:pvw39llgap0a4vm8jn9sjsvfsthah4wgemjlh6epdtzr3pl2fqtmsn3s4vcm7",
      network: network);

  /// Reads all UTXOs (Unspent Transaction Outputs) associated with the account.
  /// We does not need tokens utxo and we set to false.
  final elctrumUtxos = await provider.request(ElectrumScriptHashListUnspent(
    scriptHash: p2pkhAddress.baseAddress.pubKeyHash(),
    includeTokens: false,
  ));

  /// Converts all UTXOs to a list of UtxoWithAddress, containing UTXO information along with address details.
  final List<UtxoWithAddress> utxos = elctrumUtxos
      .map((e) => UtxoWithAddress(
          utxo: e.toUtxo(p2pkhAddress.type),
          ownerDetails: UtxoAddressDetails(
              publicKey: publicKey.toHex(), address: p2pkhAddress.baseAddress)))
      .toList();

  /// som of utxos in satoshi
  final sumOfUtxo = utxos.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    return;
  }

  final bchTransaction = ForkedTransactionBuilder(
    outPuts: [
      /// change input (sumofutxos - spend)
      BitcoinOutput(
        address: p2pkhAddress.baseAddress,
        value: sumOfUtxo -
            (BtcUtils.toSatoshi("0.0001") +
                BtcUtils.toSatoshi("0.0001") +
                BtcUtils.toSatoshi("0.00003")),
      ),
      BitcoinOutput(
        address: p2sh32Example1.baseAddress,
        value: BtcUtils.toSatoshi("0.0001"),
      ),
      BitcoinOutput(
        address: p2sh32Example2.baseAddress,
        value: BtcUtils.toSatoshi("0.0001"),
      ),
    ],
    fee: BtcUtils.toSatoshi("0.00003"),
    network: network,
    utxos: utxos,
  );
  final transaaction =
      bchTransaction.buildTransaction((trDigest, utxo, publicKey, sighash) {
    return privateKey.signInput(trDigest, sigHash: sighash);
  });

  /// transaction ID
  transaaction.txId();

  /// for calculation fee
  transaaction.getSize();

  /// raw of encoded transaction in hex
  final transactionRaw = transaaction.toHex();

  /// send transaction to network
  await provider
      .request(ElectrumBroadCastTransaction(transactionRaw: transactionRaw));

  /// done! check the transaction in block explorer
  ///  https://chipnet.imaginary.cash/tx/9e534f8a64f76b1af5ccf2522392697f2242fd215206a458cfe286bca4a3ec0a
}
