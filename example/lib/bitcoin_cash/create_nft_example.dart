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

  /// Reads all UTXOs (Unspent Transaction Outputs) associated with the account.
  /// We does not need tokens utxo and we set to false.
  final elctrumUtxos =
      await provider.request(ElectrumRequestScriptHashListUnspent(
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

  /// Every token category ID is a transaction ID:
  /// the ID must be selected from the inputs of its genesis transaction,
  /// and only token genesis inputs – inputs which spend output 0 of their
  /// parent transaction – are eligible
  /// (i.e. outpoint transaction hashes of inputs with an outpoint index of 0).
  /// As such, implementations can locate the genesis transaction of any category
  /// by identifying the transaction that spent the 0th output of the transaction referenced by the category ID.
  String? vout0Hash;
  try {
    vout0Hash =
        utxos.firstWhere((element) => element.utxo.vout == 0).utxo.txHash;
  } on StateError {
    /// if we dont have utxos with index 0 we must create them with some estimate transaction before create transaction
    return;
  }
  final bchTransaction = ForkedTransactionBuilder(
    outPuts: [
      BitcoinOutput(
        address: p2pkhAddress.baseAddress,
        value: sumOfUtxo -
            (BtcUtils.toSatoshi("0.00001") + BtcUtils.toSatoshi("0.00003")),
      ),
      BitcoinTokenOutput(
          address: p2pkhAddress.baseAddress,

          /// for a token-bearing output (600-700) satoshi
          /// hard-coded value which is expected to be enough to allow
          /// all conceivable token-bearing UTXOs (1000 satoshi)
          value: BtcUtils.toSatoshi("0.00001"),
          token: CashToken(
              category: vout0Hash,

              /// The commitment contents of the NFT held in this output (0 to 40 bytes). T
              /// his field is omitted if no NFT is present
              commitment: null,

              /// The number of fungible tokens held in this output (an integer between 1 and 9223372036854775807).
              /// This field is omitted if no fungible tokens are present.
              amount: null,
              bitfield: CashTokenUtils.buildBitfield(
                  hasAmount: false,

                  /// nfts field
                  /// mintable nft
                  capability: CashTokenCapability.minting,
                  hasCommitmentLength: false,
                  hasNFT: true))),
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
  /// https://chipnet.imaginary.cash/tx/4e153029c75963f39920184233756f8f55d5a8f86e01cbdaf0340320c814e25e
}
