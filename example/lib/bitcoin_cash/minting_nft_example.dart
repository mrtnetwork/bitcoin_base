import 'dart:convert';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/services_examples/electrum/electrum_websocket_service.dart';

/// https://github.com/cashtokens/cashtokens
void main() async {
  /// connect to electrum service with websocket
  /// please see `services_examples` folder for how to create electrum websocket service
  final service =
      await ElectrumWebSocketService.connect("wss://tbch4.loping.net:62004");

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
      .toList();
  // return;

  /// som of utxos in satoshi
  final sumOfUtxo = utxos.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    return;
  }
  const String nftCategoryId =
      "3f0d87791e5996aaddbce16c12651dd8b5b881cf7338340504bb7b2c6c08bfc4";

  final bchTransaction = ForkedTransactionBuilder(
    outPuts: [
      BitcoinOutput(
        address: p2pkhAddress.baseAddress,
        value: sumOfUtxo -
            (BtcUtils.toSatoshi("0.00004") + BtcUtils.toSatoshi("0.00003")),
      ),
      BitcoinTokenOutput(
          utxoHash: utxos.first.utxo.txHash,
          address: p2pkhAddress.baseAddress,

          /// for a token-bearing output (600-700) satoshi
          /// hard-coded value which is expected to be enough to allow
          /// all conceivable token-bearing UTXOs (1000 satoshi)
          value: BtcUtils.toSatoshi("0.00001"),
          token: CashToken(
              category: nftCategoryId,

              /// The commitment contents of the NFT held in this output (0 to 40 bytes). T
              /// his field is omitted if no NFT is present
              commitment: utf8.encode("github.com/mrtnetwork"),

              /// The number of fungible tokens held in this output (an integer between 1 and 9223372036854775807).
              /// This field is omitted if no fungible tokens are present.
              amount: BigInt.from(160000000) ~/ BigInt.from(4),
              bitfield: CashTokenUtils.buildBitfield(
                  hasAmount: true,
                  capability: CashTokenCapability.minting,
                  hasCommitmentLength: true,
                  hasNFT: true))),
      BitcoinTokenOutput(
          utxoHash: utxos.first.utxo.txHash,
          address: p2pkhAddress.baseAddress,

          /// for a token-bearing output (600-700) satoshi
          /// hard-coded value which is expected to be enough to allow
          /// all conceivable token-bearing UTXOs (1000 satoshi)
          value: BtcUtils.toSatoshi("0.00001"),
          token: CashToken(
              category: nftCategoryId,

              /// The commitment contents of the NFT held in this output (0 to 40 bytes). T
              /// his field is omitted if no NFT is present
              commitment: utf8.encode("github.com/mrtnetwork"),

              /// The number of fungible tokens held in this output (an integer between 1 and 9223372036854775807).
              /// This field is omitted if no fungible tokens are present.
              amount: BigInt.from(160000000) ~/ BigInt.from(4),
              bitfield: CashTokenUtils.buildBitfield(
                  hasAmount: true,
                  capability: CashTokenCapability.mutable,
                  hasCommitmentLength: true,
                  hasNFT: true))),
      BitcoinTokenOutput(
          utxoHash: utxos.first.utxo.txHash,
          address: p2pkhAddress.baseAddress,

          /// for a token-bearing output (600-700) satoshi
          /// hard-coded value which is expected to be enough to allow
          /// all conceivable token-bearing UTXOs (1000 satoshi)
          value: BtcUtils.toSatoshi("0.00001"),
          token: CashToken(
              category: nftCategoryId,

              /// The commitment contents of the NFT held in this output (0 to 40 bytes). T
              /// his field is omitted if no NFT is present
              commitment: utf8.encode("github.com/mrtnetwork"),

              /// The number of fungible tokens held in this output (an integer between 1 and 9223372036854775807).
              /// This field is omitted if no fungible tokens are present.
              amount: BigInt.from(160000000) ~/ BigInt.from(4),
              bitfield: CashTokenUtils.buildBitfield(
                  hasAmount: true,
                  capability: CashTokenCapability.mutable,
                  hasCommitmentLength: true,
                  hasNFT: true))),
      BitcoinTokenOutput(
          utxoHash: utxos.first.utxo.txHash,
          address: p2pkhAddress.baseAddress,

          /// for a token-bearing output (600-700) satoshi
          /// hard-coded value which is expected to be enough to allow
          /// all conceivable token-bearing UTXOs (1000 satoshi)
          value: BtcUtils.toSatoshi("0.00001"),
          token: CashToken(
              category: nftCategoryId,

              /// The commitment contents of the NFT held in this output (0 to 40 bytes). T
              /// his field is omitted if no NFT is present
              commitment: utf8.encode("github.com/mrtnetwork"),

              /// The number of fungible tokens held in this output (an integer between 1 and 9223372036854775807).
              /// This field is omitted if no fungible tokens are present.
              amount: BigInt.from(160000000) ~/ BigInt.from(4),
              bitfield: CashTokenUtils.buildBitfield(
                  hasAmount: true,
                  capability: CashTokenCapability.mutable,
                  hasCommitmentLength: true,
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
  ///  https://tbch4.loping.net/tx/caa91b0fea2843a99c3cd7375ac4d3102b6b74a25e52cd866ad7ecc486204f0d
}
