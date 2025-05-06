import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:example/services_examples/electrum/electrum_ssl_service.dart';

Future<ElectrumProvider> getProvider(
    {String url = "testnet4-electrumx.wakiyamap.dev:51002"}) async {
  // final service = await ElectrumSSLService.connect(
  //     "testnet4-electrumx.wakiyamap.dev:51002");

  final service =
      await ElectrumSSLService.connect("testnet.aranguren.org:51002");
  return ElectrumProvider(service);
}

class PsbtUtxoRequest {
  final BitcoinBaseAddress address;
  final Script? p2shRedeemScript;
  final Script? witnessScript;
  final TapLeafMerkleProof? merkleProof;
  final TaprootTree? treeScript;
  final TaprootLeaf? leafScript;
  final List<int>? xOnlyOrInternalPubKey;
  final List<int>? merkleRoot;
  final List<TapLeafMerkleProof>? leafScripts;
  final List<ECPrivate> privateKeys;
  final List<PsbtInputMuSig2ParticipantPublicKeys>? muSig2ParticipantPublicKeys;
  final List<PsbtInputRipemd160>? ripemd160;
  final List<PsbtInputSha256>? sha256;
  final List<PsbtInputHash160>? hash160;
  final List<PsbtInputHash256>? hash256;
  const PsbtUtxoRequest(
      {required this.address,
      this.p2shRedeemScript,
      this.witnessScript,
      this.leafScript,
      this.merkleProof,
      this.treeScript,
      this.xOnlyOrInternalPubKey,
      this.merkleRoot,
      this.leafScripts,
      this.privateKeys = const [],
      this.muSig2ParticipantPublicKeys,
      this.ripemd160,
      this.hash160,
      this.hash256,
      this.sha256});
}

Future<List<PsbtUtxo>> getPsbtUtxo(
    {required List<PsbtUtxoRequest> addresses,
    bool local = true,
    List<Map<String, dynamic>>? data}) async {
  final provider = await getProvider();

  final utxos = await Future.wait(addresses.map((e) async {
    return await provider.request(ElectrumRequestScriptHashListUnspent(
        scriptHash: e.address.pubKeyHash()));
  }));

  final utxoss = List.generate(utxos.length, (i) async {
    final request = addresses[i];
    final accountUtxos = utxos[i];
    final er = await Future.wait(accountUtxos
        .map((e) => provider.request(ElectrumRequestGetRawTransaction(e.txId)))
        .toList());
    return List.generate(
      accountUtxos.length,
      (index) {
        return PsbtUtxo(
            utxo: accountUtxos[index].toUtxo(request.address.type),
            p2shRedeemScript: request.p2shRedeemScript,
            p2wshWitnessScript: request.witnessScript,
            tx: er[index],
            scriptPubKey: request.address.toScriptPubKey(),
            leafScript: request.leafScript,
            leafScripts: request.leafScripts,
            merkleProof: request.merkleProof,
            treeScript: request.treeScript,
            merkleRoot: request.merkleRoot,
            xOnlyOrInternalPubKey: request.xOnlyOrInternalPubKey,
            muSig2ParticipantPublicKeys: request.muSig2ParticipantPublicKeys,
            hash160: request.hash160,
            hash256: request.hash256,
            ripemd160: request.ripemd160,
            sha256: request.sha256);
      },
    );
  });
  final e = await Future.wait(utxoss);
  return e.expand((e) => e).toList();
}
