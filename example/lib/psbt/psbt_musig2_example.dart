import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/musig/methods.dart';

Bip32Slip10Secp256k1 _deriveKey(
    {String key =
        "tprv8ZgxMBicQKsPdgBQV2Y9EVPSjAGhyZXArhwSzHwnV3FytzPRr8KCR8EKEpLeHbANAncgbc31a6QoXjBTARQiZ2h1Z2NgSCjFYeTqKpAN5Gc",
    String path = "m/86'/1'/0'/0/1"}) {
  Bip32Slip10Secp256k1 secp = Bip32Slip10Secp256k1.fromExtendedKey(
      key, Bip44Coins.bitcoinTestnet.conf.keyNetVer);
  return secp.derivePath(path) as Bip32Slip10Secp256k1;
}

ECPrivate _getPrivateKey({String path = "m/86'/1'/0'/0/1"}) {
  final key = _deriveKey(path: path);
  return ECPrivate.fromBytes(key.privateKey.raw);
}

void main() async {
  final key = _getPrivateKey();
  final key2 = _getPrivateKey(path: "m/86'/1'/0'/0/2");
  final key3 = _getPrivateKey(path: "m/86'/1'/0'/0/3");

  final aggpk = Musig2Signer.generate(
      [key.getPublic(), key2.getPublic(), key3.getPublic()]);
  final address =
      P2trAddress.fromInternalKey(internalKey: aggpk.aggPublicKey.toXOnly());
  final utxo = await getPsbtUtxo(addresses: [
    PsbtUtxoRequest(
        address: address,
        xOnlyOrInternalPubKey: aggpk.aggPublicKey.toXOnly(),
        muSig2ParticipantPublicKeys: [
          PsbtInputMuSig2ParticipantPublicKeys(
              aggregatePubKey: aggpk.aggPublicKey, pubKeys: aggpk.publicKeys)
        ])
  ]);
  final psbt = PsbtBuilderV0.create();
  psbt.addUtxos(utxo);
  psbt.addOutput(PsbtTransactionOutput(
      amount: BtcUtils.toSatoshi('0.00001'), address: address));
  for (int i = 0; i < utxo.length; i++) {
    final noncePub1 = aggpk.generateNonce(key.getPublic());
    final noncePub2 = aggpk.generateNonce(key2.getPublic());
    final noncePub3 = aggpk.generateNonce(key3.getPublic());
    psbt.musig2AddPubKeyNonce(
        i,
        PsbtInputMuSig2PublicNonce(
            publicKey: key.getPublic(),
            plainPublicKey: aggpk.aggPublicKey,
            publicNonce: noncePub1.pubnonce));
    psbt.musig2AddPubKeyNonce(
        i,
        PsbtInputMuSig2PublicNonce(
            publicKey: key2.getPublic(),
            plainPublicKey: aggpk.aggPublicKey,
            publicNonce: noncePub2.pubnonce));
    psbt.musig2AddPubKeyNonce(
        i,
        PsbtInputMuSig2PublicNonce(
            publicKey: key3.getPublic(),
            plainPublicKey: aggpk.aggPublicKey,
            publicNonce: noncePub3.pubnonce));
    psbt.signInput(
        signer: (p0) => PsbtSignerResponse(signers: [
              PsbtMusig2DefaultSigner(
                  privateKey: key,
                  aggPublicKey: aggpk.aggPublicKey,
                  publicKeys: aggpk.publicKeys,
                  nonce: noncePub1),
              PsbtMusig2DefaultSigner(
                  privateKey: key2,
                  aggPublicKey: aggpk.aggPublicKey,
                  publicKeys: aggpk.publicKeys,
                  nonce: noncePub2),
              PsbtMusig2DefaultSigner(
                  privateKey: key3,
                  aggPublicKey: aggpk.aggPublicKey,
                  publicKeys: aggpk.publicKeys,
                  nonce: noncePub3),
            ]),
        index: i);
  }
  // ignore: unused_local_variable
  final finalTx = psbt.finalizeAll();
}
