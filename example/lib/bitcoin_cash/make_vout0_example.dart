import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/services_examples/electrum/electrum_ssl_service.dart';

/// make vout 0 for account for create token hash
/// estimate transaction to your self with input 0

void main() async {
  /// connect to electrum service with ssl
  /// please see `services_examples` folder for how to create electrum ssl service
  final service =
      await ElectrumSSLService.connect("chipnet.imaginary.cash:50002");

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
  final p2pkhAddress = publicKey.toAddress();

  /// Reads all UTXOs (Unspent Transaction Outputs) associated with the account.
  /// We does not need tokens utxo and we set to false.
  final elctrumUtxos = await provider.request(ElectrumScriptHashListUnspent(
    scriptHash: p2pkhAddress.pubKeyHash(),
    includeTokens: false,
  ));

  /// Converts all UTXOs to a list of UtxoWithAddress, containing UTXO information along with address details.
  final List<UtxoWithAddress> utxos = elctrumUtxos
      .map((e) => UtxoWithAddress(
          utxo: e.toUtxo(p2pkhAddress.type),
          ownerDetails: UtxoAddressDetails(
              publicKey: publicKey.toHex(), address: p2pkhAddress)))
      .toList();

  /// som of utxos in satoshi
  final sumOfUtxo = utxos.sumOfUtxosValue();

  final bchTransaction = ForkedTransactionBuilder(
    outPuts: [
      BitcoinOutput(
        address: p2pkhAddress,
        value: sumOfUtxo - BtcUtils.toSatoshi("0.00003"),
      )
    ],
    fee: BtcUtils.toSatoshi("0.00003"),
    network: network,

    /// Bitcoin Cash Metadata Registries
    /// pleas see https://cashtokens.org/docs/bcmr/chip/ for how to create cash metadata
    /// we does not create metadata for this token
    memo: null,
    utxos: utxos,
  );
  final transaaction =
      bchTransaction.buildTransaction((trDigest, utxo, publicKey, sighash) {
    return privateKey.signInput(trDigest, sigHash: sighash);
  });

  /// transaction ID
  final _ = transaaction.txId();

  /// for calculation fee (serialized transaction bytes length)
  transaaction.getSize();

  /// raw of encoded transaction in hex
  final transactionRaw = transaaction.toHex();

  /// send transaction to network
  await provider
      .request(ElectrumBroadCastTransaction(transactionRaw: transactionRaw));

  /// done! check the transaction in block explorer
  ///  https://chipnet.imaginary.cash/tx/b20d4c13fe67adc2f73aee0161eb51c7e813643ddc8eb655c6bd9ae72b7562cb
}
