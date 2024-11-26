import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/services_examples/electrum/electrum_websocket_service.dart';

/// please make sure read this before create transaction on mainnet
//// https://github.com/cashtokens/cashtokens
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
  final p2pkhAddress = BitcoinCashAddress.fromBaseAddress(
      publicKey.toP2pkInP2sh(useBCHP2sh32: true));

  /// p2pkh with token address ()
  final receiver1 = P2pkhAddress.fromHash160(
      addrHash: publicKey.toAddress().addressProgram,
      type: P2pkhAddressType.p2pkhwt);

  /// Reads all UTXOs (Unspent Transaction Outputs) associated with the account.
  /// We does not need tokens utxo and we set to false.
  final elctrumUtxos = await provider.request(ElectrumScriptHashListUnspent(
    scriptHash: p2pkhAddress.baseAddress.pubKeyHash(),
    includeTokens: true,
  ));
  // return;

  /// Converts all UTXOs to a list of UtxoWithAddress, containing UTXO information along with address details.
  final List<UtxoWithAddress> utxos = elctrumUtxos
      .map((e) => UtxoWithAddress(
          utxo: e.toUtxo(p2pkhAddress.type),
          ownerDetails: UtxoAddressDetails(
              publicKey: publicKey.toHex(), address: p2pkhAddress.baseAddress)))
      .toList()

      /// we only filter the utxos for this token or none token utxos
      .where((element) =>
          element.utxo.token?.category ==
              "4e7873d4529edfd2c6459139257042950230baa9297f111b8675829443f70430" ||
          element.utxo.token == null)
      .toList();

  /// som of utxos in satoshi
  final sumOfUtxo = utxos.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    return;
  }

  /// CashToken{bitfield: 16, commitment: null, amount: 2000, category: 4e7873d4529edfd2c6459139257042950230baa9297f111b8675829443f70430}
  final CashToken token = elctrumUtxos
      .firstWhere((e) =>
          e.token?.category ==
          "4e7873d4529edfd2c6459139257042950230baa9297f111b8675829443f70430")
      .token!;

  /// sum of ft token amounts with category "4e7873d4529edfd2c6459139257042950230baa9297f111b8675829443f70430"
  final sumofTokenUtxos = utxos
      .where((element) =>
          element.utxo.token?.category ==
          "4e7873d4529edfd2c6459139257042950230baa9297f111b8675829443f70430")
      .fold(
          BigInt.zero,
          (previousValue, element) =>
              previousValue + element.utxo.token!.amount);

  final bchTransaction = ForkedTransactionBuilder(
    outPuts: [
      /// change address for bch values (sum of bch amout - (outputs amount + fee))
      BitcoinOutput(
        address: p2pkhAddress.baseAddress,
        value: sumOfUtxo -
            (BtcUtils.toSatoshi("0.00002") + BtcUtils.toSatoshi("0.00003")),
      ),
      BitcoinTokenOutput(
          utxoHash: utxos.first.utxo.txHash,
          address: receiver1,

          /// for a token-bearing output (600-700) satoshi
          /// hard-coded value which is expected to be enough to allow
          /// all conceivable token-bearing UTXOs (1000 satoshi)
          value: BtcUtils.toSatoshi("0.00001"),

          /// clone the token with new token amount for output1 (15 amount of category)
          token: token.copyWith(amount: BigInt.from(15))),

      /// another change token value to change account like bch
      BitcoinTokenOutput(
          utxoHash: utxos.first.utxo.txHash,
          address: p2pkhAddress.baseAddress,

          /// for a token-bearing output (600-700) satoshi
          /// hard-coded value which is expected to be enough to allow
          /// all conceivable token-bearing UTXOs (1000 satoshi)
          value: BtcUtils.toSatoshi("0.00001"),

          /// clone the token with new token amount for output1 (15 amount of category)
          token: token.copyWith(amount: sumofTokenUtxos - BigInt.from(15))),
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
  transaaction.txId();

  /// for calculation fee
  transaaction.getSize();

  /// raw of encoded transaction in hex
  final transactionRaw = transaaction.toHex();

  /// send transaction to network
  await provider
      .request(ElectrumBroadCastTransaction(transactionRaw: transactionRaw));

  /// done! check the transaction in block explorer
  ///  https://chipnet.imaginary.cash/tx/97030c1236a024de7cad7ceadf8571833029c508e016bcc8173146317e367ae6
}
