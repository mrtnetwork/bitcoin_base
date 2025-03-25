import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import 'methods.dart';

/// "m/86'/1'/0'/0/1034"
Bip32Slip10Secp256k1 getKey(
    {String key =
        "tprv8ZgxMBicQKsPdgBQV2Y9EVPSjAGhyZXArhwSzHwnV3FytzPRr8KCR8EKEpLeHbANAncgbc31a6QoXjBTARQiZ2h1Z2NgSCjFYeTqKpAN5Gc",
    String path = "m/86'/1'/0'/0/1"}) {
  Bip32Slip10Secp256k1 secp = Bip32Slip10Secp256k1.fromExtendedKey(
      key, Bip44Coins.bitcoinTestnet.conf.keyNetVer);
  return secp.derivePath(path) as Bip32Slip10Secp256k1;
}

void main() async {
  final key = getKey();
  final key2 = getKey(path: "m/86'/1'/0'/0/2");
  final key3 = getKey(path: "m/86'/1'/0'/0/3");

  final aggpk = MuSig2.aggPublicKeys(keys: [
    key.publicKey.compressed,
    key2.publicKey.compressed,
    key3.publicKey.compressed
  ]);

  final pk = ECPublic.fromBytes(aggpk.toBytes());
  final tweakPubKey = TaprootUtils.calculateTweek(aggpk.publicKey.toXonly());
  final address =
      P2trAddress.fromInternalKey(internalKey: aggpk.publicKey.toBytes());
  // print(address.toAddress(BitcoinNetwork.testnet));
  // return;
  final input = TxInput(
      txId: '7af6690448027f9a6ba99eb1b2c9f56a604d5d497e4135f65387a9a5aae39cb6',
      txIndex: 1);
  final amount = BtcUtils.toSatoshi("0.00500000");
  final rAmount = BtcUtils.toSatoshi("0.00010000");
  final fee =
      (BigRational.from(500) * BigRational.parseDecimal("1.1")).toBigInt();
  final change = amount - (rAmount + fee);
  assert(!change.isNegative);
  final output =
      TxOutput(amount: rAmount, scriptPubKey: pk.toAddress().toScriptPubKey());
  final changeOutput =
      TxOutput(amount: change, scriptPubKey: address.toScriptPubKey());
  BtcTransaction tx =
      BtcTransaction(inputs: [input], outputs: [output, changeOutput]);
  final digest = tx.getTransactionTaprootDigset(
    txIndex: 0,
    scriptPubKeys: [address.toScriptPubKey()],
    amounts: [amount],
  ).asImmutableBytes;
  final nonce1 =
      MuSig2.nonceGenerate(publicKey: key.publicKey.compressed, msg: digest);
  final nonce2 =
      MuSig2.nonceGenerate(publicKey: key2.publicKey.compressed, msg: digest);
  final nonce3 =
      MuSig2.nonceGenerate(publicKey: key3.publicKey.compressed, msg: digest);
  final aggNonce =
      MuSig2.nonceAgg([nonce1.pubnonce, nonce2.pubnonce, nonce3.pubnonce]);
  final session = MuSig2Session(
      aggnonce: aggNonce,
      publicKeys: [
        key.publicKey.compressed,
        key2.publicKey.compressed,
        key3.publicKey.compressed
      ],
      tweaks: [MuSig2Tweak(tweak: tweakPubKey)],
      msg: digest);
  final sig1 = MuSig2.sign(
      secnonce: nonce1.secnonce, sk: key.privateKey.raw, session: session);
  final sig2 = MuSig2.sign(
      secnonce: nonce2.secnonce, sk: key2.privateKey.raw, session: session);
  final sig3 = MuSig2.sign(
      secnonce: nonce3.secnonce, sk: key3.privateKey.raw, session: session);
  final signature =
      MuSig2.partialSigAgg(signatures: [sig1, sig2, sig3], session: session);
  tx = tx.copyWith(witnesses: [
    TxWitnessInput(stack: [BytesUtils.toHexString(signature)])
  ]);
  await testMempool(tx.serialize());
}
