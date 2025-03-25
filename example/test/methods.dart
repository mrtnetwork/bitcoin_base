// ignore_for_file: avoid_print

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:example/services_examples/electrum/electrum_ssl_service.dart';
import 'testmusig_test.dart';
import 'package:http/http.dart' as http;

Future<ElectrumProvider> getProvider(
    {String url = "testnet4-electrumx.wakiyamap.dev:51002"}) async {
  final service = await ElectrumSSLService.connect(
      "testnet4-electrumx.wakiyamap.dev:51002");
  return ElectrumProvider(service);
}

Future<void> callBitcoinRpc(String method, [List<dynamic>? params]) async {
  const rpcUser = 'n';
  const rpcPassword = 'n';
  const rpcUrl = 'http://127.0.0.1:48332/';

  final body = StringUtils.fromJson({
    "jsonrpc": "1.0",
    "id": "dart-client",
    "method": method,
    "params": params ?? []
  });

  final headers = {
    'Content-Type': 'application/json',
    'Authorization':
        'Basic ${StringUtils.decode(StringUtils.encode('$rpcUser:$rpcPassword'), type: StringEncoding.base64)}'
  };

  try {
    final response =
        await http.post(Uri.parse(rpcUrl), headers: headers, body: body);

    if (response.statusCode == 200) {
      print(response.body);
    } else {
      print('RPC Error: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> listdescriptors() async {
  await callBitcoinRpc("listdescriptors", [true]);
}

Future<void> testMempool(String digest) async {
  await callBitcoinRpc("testmempoolaccept", [
    [digest]
  ]);
}

Future<void> sendTx(String digest) async {
  await callBitcoinRpc("sendrawtransaction", [digest]);
}

class ElectrumUtxoWithTx {
  final ElectrumUtxo utxo;
  final BtcTransaction transaction;
  final BitcoinBaseAddress address;
  const ElectrumUtxoWithTx(
      {required this.utxo, required this.transaction, required this.address});
  factory ElectrumUtxoWithTx.fromJson(Map<String, dynamic> json) {
    return ElectrumUtxoWithTx(
        utxo: ElectrumUtxo.fromJson(json["utxo"]),
        transaction: BtcTransaction.deserialize(
            BytesUtils.fromHexString(json["transaction"])),
        address:
            BitcoinAddress(json["address"], network: BitcoinNetwork.testnet)
                .baseAddress);
  }

  Map<String, dynamic> toJson() {
    return {
      "utxo": utxo.toJson(),
      "transaction": transaction.toHex(),
      "address": address.toAddress(BitcoinNetwork.testnet)
    };
  }
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
        final r = PsbtUtxo(
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
            privateKeys: request.privateKeys,
            xOnlyOrInternalPubKey: request.xOnlyOrInternalPubKey,
            muSig2ParticipantPublicKeys: request.muSig2ParticipantPublicKeys,
            hash160: request.hash160,
            hash256: request.hash256,
            ripemd160: request.ripemd160,
            sha256: request.sha256);
        // final toJs = r.toJson();
        // toJs["address"] = request.address.toAddress(BitcoinNetwork.testnet);
        // toJs["select_leaf"] = request.leafScript?.toHex();
        // toJs.removeWhere((k, v) => v == null);
        // return toJs;
        return r;
      },
    );
  });
  final e = await Future.wait(utxoss);
  // print(StringUtils.fromJson(utxoss));
  // // return [];
  return e.expand((e) => e).toList();
}

BitcoinBaseAddress getP2pkOutput() {
  final acc = getKey(path: "m/86'/1'/0'/0/1022");
  final pk = ECPublic.fromBytes(acc.publicKey.compressed);
  return pk.toP2pkAddress();
}
