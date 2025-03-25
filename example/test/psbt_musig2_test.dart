import 'package:bitcoin_base/bitcoin_base.dart';
import 'testmusig_test.dart';
import 'methods.dart';

ECPrivate getAccoutPrivateKey({String path = "m/86'/1'/0'/0/1"}) {
  final key = getKey(path: path);
  return ECPrivate.fromBytes(key.privateKey.raw);
}

void main() async {
  final key = getAccoutPrivateKey();
  final key2 = getAccoutPrivateKey(path: "m/86'/1'/0'/0/2");
  final key3 = getAccoutPrivateKey(path: "m/86'/1'/0'/0/3");

  /// 73609a5081514d4cb92190636db8a40ead4b12d6000d2e839b92f2cc3cfb3b92cda58dfd722201c41329322d94457938a15207660f8701322631583769803165
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
  final tx = psbt.finalizeAll();
  await testMempool(tx.serialize());
}
