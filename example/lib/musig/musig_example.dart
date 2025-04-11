// ignore_for_file: unused_element

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

void main() async {
  final key = _getPubKey();
  final key2 = _getPubKey(path: "m/86'/1'/0'/0/2");
  final key3 = _getPubKey(path: "m/86'/1'/0'/0/3");
  final signer = Musig2Signer.generate([key, key2, key3]);

  final treeScript = _generateScriptTree();
  final address = _generateAddress();
  final input = TxInput(
      txId: '9bb72872594cb9b7a029f3daf0fe277dfbe5de3d52d4b55ba283cfa97b9310cc',
      txIndex: 1);
  final amount = BtcUtils.toSatoshi("0.00500000");
  final rAmount = BtcUtils.toSatoshi("0.00010000");
  final fee = BtcUtils.toSatoshi("0.00001");
  final change = amount - (rAmount + fee);
  final output = TxOutput(
      amount: rAmount, scriptPubKey: signer.toAddress().toScriptPubKey());
  final changeOutput =
      TxOutput(amount: change, scriptPubKey: address.toScriptPubKey());
  BtcTransaction transaction =
      BtcTransaction(inputs: [input], outputs: [output, changeOutput]);
  transaction = _spendWithKeyPath(
      transaction: transaction,
      existsUtxosScriptPubKeys: [address],
      existsUtxosAmounts: [amount],
      treeScript: treeScript);
}

BtcTransaction _spendWithKeyPath(
    {required BtcTransaction transaction,
    required List<P2trAddress> existsUtxosScriptPubKeys,
    required List<BigInt> existsUtxosAmounts,
    required TaprootTree treeScript}) {
  final key1 = _getPrivateKey(path: "m/86'/1'/0'/0/2");
  final key2 = _getPrivateKey(path: "m/86'/1'/0'/0/3");
  final key3 = _getPrivateKey(path: "m/86'/1'/0'/0/4");
  final pk1 = key1.getPublic();
  final pk2 = key2.getPublic();
  final pk3 = key3.getPublic();
  final signer =
      Musig2Signer.generate([pk1, pk2, pk3], privateKeys: [key1, key2, key3]);
  final digest = transaction
      .getTransactionTaprootDigset(
          txIndex: 0,
          scriptPubKeys:
              existsUtxosScriptPubKeys.map((e) => e.toScriptPubKey()).toList(),
          amounts: existsUtxosAmounts)
      .asImmutableBytes;

  final signature = signer.fullSign(digest, treeScript: treeScript);
  return transaction.copyWith(witnesses: [
    TxWitnessInput(stack: [BytesUtils.toHexString(signature)])
  ]);
}

BtcTransaction _spendWithLeafA(
    {required BtcTransaction transaction,
    required List<P2trAddress> existsUtxosScriptPubKeys,
    required List<BigInt> existsUtxosAmounts,
    required TaprootTree treeScript}) {
  final internalKey = _getInternalPubKey();
  final key1 = _getPrivateKey(path: "m/86'/1'/0'/0/2");
  final key3 = _getPrivateKey(path: "m/86'/1'/0'/0/4");
  final pk1 = key1.getPublic();
  final pk3 = key3.getPublic();
  final musigSigner = MuSig2.aggPublicKeys(
      keys: [pk1.publicKey.compressed, pk3.publicKey.compressed]);
  final tapleafScript1 = TaprootLeaf(
      script: Script(script: [
    BytesUtils.toHexString(musigSigner.publicKey.toXonly()),
    BitcoinOpcode.opCheckSig
  ]));
  final digest = transaction
      .getTransactionTaprootDigset(
          txIndex: 0,
          tapleafScript: tapleafScript1,
          scriptPubKeys:
              existsUtxosScriptPubKeys.map((e) => e.toScriptPubKey()).toList(),
          amounts: existsUtxosAmounts)
      .asImmutableBytes;
  final nonce1 = MuSig2.nonceGenerate(
      publicKey: pk1.toBytes(mode: PubKeyModes.compressed), msg: digest);
  final nonce3 = MuSig2.nonceGenerate(
      publicKey: pk3.toBytes(mode: PubKeyModes.compressed), msg: digest);
  final aggNonce = MuSig2.nonceAgg([nonce1.pubnonce, nonce3.pubnonce]);
  final session = MuSig2Session(
      aggnonce: aggNonce,
      publicKeys: [
        pk1.toBytes(mode: PubKeyModes.compressed),
        pk3.toBytes(mode: PubKeyModes.compressed)
      ],
      tweaks: [],
      msg: digest);
  final sig1 = MuSig2.sign(
      secnonce: nonce1.secnonce, sk: key1.toBytes(), session: session);
  final sig3 = MuSig2.sign(
      secnonce: nonce3.secnonce, sk: key3.toBytes(), session: session);
  final signature =
      MuSig2.partialSigAgg(signatures: [sig1, sig3], session: session);
  final controlBlock = TaprootControlBlock.generate(
      xOnlyOrInternalPubKey: internalKey.toXOnly(),
      leafScript: tapleafScript1,
      scriptTree: treeScript);

  return transaction.copyWith(witnesses: [
    TxWitnessInput(stack: [
      BytesUtils.toHexString(signature),
      tapleafScript1.script.toHex(),
      controlBlock.toHex()
    ])
  ]);
}

BtcTransaction _spendWithLeafC(
    {required BtcTransaction transaction,
    required List<P2trAddress> existsUtxosScriptPubKeys,
    required List<BigInt> existsUtxosAmounts,
    required TaprootTree treeScript}) {
  final internalKey = _getInternalPubKey();
  final key2 = _getPrivateKey(path: "m/86'/1'/0'/0/3");
  final key1 = _getPrivateKey(path: "m/86'/1'/0'/0/2");
  final pk1 = key1.getPublic();
  final pk2 = key2.getPublic();
  final leafC = TaprootLeaf(
      script: Script(script: [
    pk1.toXOnlyHex(),
    BitcoinOpcode.opCheckSig,
    pk2.toXOnlyHex(),
    BitcoinOpcode.opCheckSigAdd,
    2,
    BitcoinOpcode.opNumEqual
  ]));
  final digest = transaction
      .getTransactionTaprootDigset(
          txIndex: 0,
          tapleafScript: leafC,
          scriptPubKeys:
              existsUtxosScriptPubKeys.map((e) => e.toScriptPubKey()).toList(),
          amounts: existsUtxosAmounts)
      .asImmutableBytes;
  final sig1 = key1.signBip340(digest, tweak: false);
  final sig2 = key2.signBip340(digest, tweak: false);
  final controlBlock = TaprootControlBlock.generate(
      xOnlyOrInternalPubKey: internalKey.toXOnly(),
      leafScript: leafC,
      scriptTree: treeScript);

  return transaction.copyWith(witnesses: [
    TxWitnessInput(
        stack: [sig2, sig1, leafC.script.toHex(), controlBlock.toHex()])
  ]);
}

Bip32Slip10Secp256k1 _deriveKey(
    {String key =
        "tprv8ZgxMBicQKsPdgBQV2Y9EVPSjAGhyZXArhwSzHwnV3FytzPRr8KCR8EKEpLeHbANAncgbc31a6QoXjBTARQiZ2h1Z2NgSCjFYeTqKpAN5Gc",
    String path = "m/86'/1'/0'/0/1"}) {
  Bip32Slip10Secp256k1 secp = Bip32Slip10Secp256k1.fromExtendedKey(
      key, Bip44Coins.bitcoinTestnet.conf.keyNetVer);
  return secp.derivePath(path) as Bip32Slip10Secp256k1;
}

ECPublic _getPubKey({String path = "m/86'/1'/0'/0/1"}) {
  return ECPublic.fromBytes(_deriveKey(path: path).publicKey.compressed);
}

ECPrivate _getPrivateKey({String path = "m/86'/1'/0'/0/1"}) {
  return ECPrivate.fromBytes(_deriveKey(path: path).privateKey.raw);
}

TaprootBranch _generateScriptTree() {
  final pk1 = _getPubKey(path: "m/86'/1'/0'/0/2");
  final pk2 = _getPubKey(path: "m/86'/1'/0'/0/3");
  final pk3 = _getPubKey(path: "m/86'/1'/0'/0/4");
  final musigSigner = Musig2Signer.generate([pk1, pk3]);
  final leaf1 = TaprootLeaf(
      script: Script(script: [
    BytesUtils.toHexString(musigSigner.aggPublicKey.toXOnly()),
    BitcoinOpcode.opCheckSig
  ]));
  final leaf2 = TaprootLeaf(
      script: Script(script: [pk3.toXOnlyHex(), BitcoinOpcode.opCheckSig]));

  final leaf3 = TaprootLeaf(
      script: Script(script: [
    pk1.toXOnlyHex(),
    BitcoinOpcode.opCheckSig,
    pk2.toXOnlyHex(),
    BitcoinOpcode.opCheckSigAdd,
    2,
    BitcoinOpcode.opNumEqual
  ]));
  return TaprootBranch(a: leaf3, b: TaprootBranch(a: leaf1, b: leaf2));
}

ECPublic _getInternalPubKey() {
  final pk1 = _getPubKey(path: "m/86'/1'/0'/0/2");
  final pk2 = _getPubKey(path: "m/86'/1'/0'/0/3");
  final pk3 = _getPubKey(path: "m/86'/1'/0'/0/4");
  final internalKey = Musig2Signer.generate([pk1, pk2, pk3]);

  return internalKey.aggPublicKey;
}

P2trAddress _generateAddress() {
  final internalKey = _getInternalPubKey();
  return P2trAddress.fromInternalKey(
      internalKey: internalKey.toXOnly(), treeScript: _generateScriptTree());
}
