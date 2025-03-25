import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import '../musig/methods.dart';

void main() async {
  final psbt = PsbtBuilderV0.create();
  final btcAddress1 = _getBtcAddress1();
  final btcAddress2 = _getBtcAddress2();
  final btcAddress3 = _getBtcAddress3();
  final btcAddress4 = _getBtcAddress4();
  final btcAddress5 = _getBtcAddress5();
  final btcAddress6 = _getBtcAddress6();
  final btcAddress7 = _getBtcAddress7();
  final btcAddress8 = _getBtcAddress8();
  final btcAddress9 = _getBtcAddress9();
  final btcAddress10 = _getBtcAddress10();
  final btcAddress11 = _getBtcAddress11();
  final btcAddress12 = _getBtcAddress12();
  final btcAddress13 = _getBtcAddress13();
  final btcAddress14 = _getBtcAddress14();
  final internalKey12 = _getSigner().signerPublicKey.toXOnly();
  final treeScript12 = _getScript12();
  final leafScript12 = _getScript12();
  final treeScript13 = _getScript13();
  final leafScript13 = _getLeafScript13();

  final internalKey13 = _getInternalKey8();
  final internalKey14 = _getTapScriptSigner6();
  final treeScript14 = _treeScript25();
  final btcAddress15 =
      P2shAddress.fromScript(script: Script(script: [BitcoinOpcode.opTrue]));
  final btcAddress16 =
      P2wshAddress.fromScript(script: Script(script: [BitcoinOpcode.opTrue]));
  final btcAddress17 = P2shAddress.fromScript(
      script: btcAddress16.toScriptPubKey(), type: P2shAddressType.p2wshInP2sh);

  final opHash160 = _getOpHash160();
  final sha256 = _getOpSHA256();
  final hash256 = _getOpHASH256();
  final tapHash160 = _getTapScriptHash160();

  final utxos = await getPsbtUtxo(addresses: [
    PsbtUtxoRequest(
        address: tapHash160.$1,
        leafScript: TaprootLeaf(script: tapHash160.$2),
        treeScript: TaprootLeaf(script: tapHash160.$2),
        xOnlyOrInternalPubKey: tapHash160.$3.xOnly,
        // p2shRedeemScript: opHash160.$3,
        hash160: [PsbtInputHash160.fromPreImage(opHash160.$4)]),
    PsbtUtxoRequest(
        address: opHash160.$1,
        p2shRedeemScript: opHash160.$3,
        hash160: [PsbtInputHash160.fromPreImage(opHash160.$4)]),
    PsbtUtxoRequest(
        address: opHash160.$2,
        witnessScript: opHash160.$3,
        hash160: [PsbtInputHash160.fromPreImage(opHash160.$4)]),
    PsbtUtxoRequest(
        address: sha256.$1,
        p2shRedeemScript: sha256.$3,
        sha256: [PsbtInputSha256.fromPreImage(sha256.$4)]),
    PsbtUtxoRequest(
        address: sha256.$2,
        witnessScript: sha256.$3,
        sha256: [PsbtInputSha256.fromPreImage(sha256.$4)]),
    PsbtUtxoRequest(
        address: hash256.$1,
        p2shRedeemScript: hash256.$3,
        hash256: [PsbtInputHash256.fromPreImage(sha256.$4)]),
    PsbtUtxoRequest(
        address: hash256.$2,
        witnessScript: hash256.$3,
        hash256: [PsbtInputHash256.fromPreImage(sha256.$4)]),
    PsbtUtxoRequest(
        address: btcAddress14,
        treeScript: treeScript14,
        privateKeys: [_getSigner31().privateKey, _getSigner32().privateKey],
        xOnlyOrInternalPubKey: internalKey14.signerPublicKey.toXOnly()),
    PsbtUtxoRequest(
        address: btcAddress13,
        treeScript: treeScript13,
        leafScript: leafScript13,
        privateKeys: [_getSigner30().privateKey, _getSigner31().privateKey],
        xOnlyOrInternalPubKey: internalKey13.toXOnly()),
    PsbtUtxoRequest(
        address: btcAddress12,
        leafScript: leafScript12,
        treeScript: treeScript12,
        xOnlyOrInternalPubKey: internalKey12,
        privateKeys: [
          _getSigner2().privateKey,
          _getSigner3().privateKey,
        ]),
    PsbtUtxoRequest(
        address: btcAddress9,
        witnessScript: _mSigOnlyWitness().multiSigScript,
        privateKeys: [
          _getSigner2().privateKey,
          _getSigner().privateKey,
          _getSigner3().privateKey
        ]),
    PsbtUtxoRequest(
        address: btcAddress10,
        p2shRedeemScript: _multisig().multiSigScript,
        privateKeys: [
          _getSigner2().privateKey,
          _getSigner().privateKey,
          _getSigner5().privateKey
        ]),
    PsbtUtxoRequest(
        address: btcAddress11,
        p2shRedeemScript: _multisig2().multiSigScript,
        privateKeys: [
          _getSigner2().privateKey,
          _getSigner().privateKey,
          _getSigner5().privateKey
        ]),
    PsbtUtxoRequest(
        address: btcAddress15, p2shRedeemScript: Script(script: ["OP_TRUE"])),
    PsbtUtxoRequest(
        address: btcAddress17,
        p2shRedeemScript: btcAddress16.toScriptPubKey(),
        witnessScript: Script(script: ["OP_TRUE"])),
    PsbtUtxoRequest(
        address: btcAddress1,
        privateKeys: [_getSigner().privateKey],
        p2shRedeemScript: _getSigner().signerPublicKey.toRedeemScript()),
    PsbtUtxoRequest(
        address: btcAddress5,
        witnessScript: _getSigner5().signerPublicKey.toP2wshScript(),
        privateKeys: [_getSigner5().privateKey],
        p2shRedeemScript:
            _getSigner5().signerPublicKey.toP2wshAddress().toScriptPubKey()),
    PsbtUtxoRequest(
        address: btcAddress6,
        privateKeys: [_getSigner6().privateKey],
        xOnlyOrInternalPubKey: _getSigner6().privateKey.getPublic().toXOnly()),
    PsbtUtxoRequest(
        address: btcAddress2, privateKeys: [_getSigner2().privateKey]),
    PsbtUtxoRequest(
        address: btcAddress3,
        p2shRedeemScript:
            _getSigner3().signerPublicKey.toAddress().toScriptPubKey(),
        privateKeys: [_getSigner3().privateKey]),
    PsbtUtxoRequest(
        address: btcAddress4,
        privateKeys: [_getSigner4().privateKey],
        p2shRedeemScript:
            _getSigner4().signerPublicKey.toSegwitAddress().toScriptPubKey()),
    PsbtUtxoRequest(
        address: btcAddress7,
        privateKeys: [_getSigner11().privateKey],
        p2shRedeemScript: _getSigner11()
            .signerPublicKey
            .toRedeemScript(mode: PubKeyModes.uncompressed)),
    PsbtUtxoRequest(
        address: btcAddress8, privateKeys: [_getSigner12().privateKey]),
  ]);
  psbt.addUtxos(utxos);
  final totalAmount =
      utxos.fold<BigInt>(BigInt.zero, (p, c) => p + c.utxo.value);

  final rec1Amount = BtcUtils.toSatoshi("0.00002");

  final fee = BtcUtils.toSatoshi("0.0001");
  final changeAmount = totalAmount - (rec1Amount + fee);
  assert(!changeAmount.isNegative);

  psbt.addOutput(
      PsbtTransactionOutput(amount: rec1Amount, address: _getReceipt2()));
  psbt.addOutput(
      PsbtTransactionOutput(amount: changeAmount, address: _getReceipt()));

  psbt.signAllInput(
    (param) {
      if (param.scriptPubKey == btcAddress13.toScriptPubKey()) {
        assert(param.address == btcAddress13);
        return PsbtSignerResponse(
          sighash: BitcoinOpCodeConst.sighashAll,
          signers: [_getSigner30(), _getSigner31()],
          tapleafHash: leafScript13.hash(),
        );
      }
      if (param.scriptPubKey == btcAddress14.toScriptPubKey()) {
        assert(param.address == btcAddress14);
        return PsbtSignerResponse(
          sighash: BitcoinOpCodeConst.sighashNone,
          signers: [_getSigner31(), _getSigner32()],
        );
      }
      if (param.scriptPubKey == btcAddress1.toScriptPubKey()) {
        assert(param.address == btcAddress1);
        return PsbtSignerResponse(signers: [_getSigner()]);
      }
      if (param.scriptPubKey == btcAddress2.toScriptPubKey()) {
        assert(param.address == btcAddress2);
        return PsbtSignerResponse(signers: [_getSigner2()]);
      }
      if (param.scriptPubKey == btcAddress3.toScriptPubKey()) {
        assert(param.address == btcAddress3);
        return PsbtSignerResponse(signers: [_getSigner3()]);
      }
      if (param.scriptPubKey == btcAddress4.toScriptPubKey()) {
        assert(param.address == btcAddress4);
        return PsbtSignerResponse(signers: [_getSigner4()]);
      }
      if (param.scriptPubKey == btcAddress5.toScriptPubKey()) {
        assert(param.address == btcAddress5);
        return PsbtSignerResponse(signers: [_getSigner5()]);
      }
      if (param.scriptPubKey == btcAddress6.toScriptPubKey()) {
        assert(param.address == btcAddress6);
        return PsbtSignerResponse(signers: [_getSigner6()]);
      }
      if (param.scriptPubKey == btcAddress7.toScriptPubKey()) {
        assert(param.address == btcAddress7);
        return PsbtSignerResponse(signers: [_getSigner11()]);
      }
      if (param.scriptPubKey == btcAddress8.toScriptPubKey()) {
        assert(param.address == btcAddress8);
        return PsbtSignerResponse(signers: [_getSigner12()]);
      }
      if (param.scriptPubKey == btcAddress12.toScriptPubKey()) {
        assert(param.address == btcAddress12);
        return PsbtSignerResponse(
          signers: [_getSigner2(), _getSigner3()],
          tapleafHash: leafScript12.hash(),
        );
      }
      if (param.scriptPubKey == btcAddress9.toScriptPubKey()) {
        assert(param.address == btcAddress9);
        return PsbtSignerResponse(
          signers: [_getSigner2(), _getSigner(), _getSigner3()],
        );
      }
      if (param.scriptPubKey == btcAddress10.toScriptPubKey()) {
        assert(param.address == btcAddress10);
        return PsbtSignerResponse(
          signers: [_getSigner2(), _getSigner(), _getSigner5()],
        );
      }
      if (param.scriptPubKey == btcAddress11.toScriptPubKey()) {
        assert(param.address == btcAddress11);
        return PsbtSignerResponse(
          signers: [_getSigner2(), _getSigner(), _getSigner5()],
        );
      }

      return null;
    },
  );
  // ignore: unused_local_variable
  final finalTx = psbt.finalizeAll(
    onFinalizeInput: (params) {
      if (params.scriptPubKey == btcAddress13.toScriptPubKey()) {
        return PsbtFinalizeResponse(tapleafHash: leafScript13.hash());
      }
      return null;
    },
  );
}

PsbtDefaultSigner _getSigner() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/1022");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

PsbtDefaultSigner _getSigner11() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/1033");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

PsbtDefaultSigner _getSigner12() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/1034");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

PsbtDefaultSigner _getSigner6() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/0");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

PsbtDefaultSigner _getSigner2() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/1025");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

BitcoinBaseAddress _getBtcAddress2() {
  final s = _getSigner2();
  return s.privateKey.getPublic().toSegwitAddress();
}

BitcoinBaseAddress _getBtcAddress1() {
  final s = _getSigner();
  return s.privateKey.getPublic().toP2pkInP2sh();
}

BitcoinBaseAddress _getBtcAddress7() {
  final s = _getSigner11();
  return s.privateKey
      .getPublic()
      .toP2pkInP2sh(mode: PublicKeyType.uncompressed);
}

BitcoinBaseAddress _getBtcAddress8() {
  final s = _getSigner12();
  return s.privateKey.getPublic().toAddress(mode: PublicKeyType.uncompressed);
}

BitcoinBaseAddress _getBtcAddress6() {
  final s = _getSigner6();
  return s.privateKey.getPublic().toTaprootAddress();
}

BitcoinBaseAddress _getReceipt() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/1022");
  final pk = ECPublic.fromBytes(acc.publicKey.compressed);
  return pk.toP2wpkhInP2sh();
}

BitcoinBaseAddress _getReceipt2() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/1025");
  final pk = ECPublic.fromBytes(acc.publicKey.compressed);
  return pk.toP2wshInP2sh();
}

PsbtDefaultSigner _getSigner3() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/1025");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

BitcoinBaseAddress _getBtcAddress3() {
  final s = _getSigner3();
  return s.privateKey.getPublic().toP2pkhInP2sh();
}

PsbtDefaultSigner _getSigner4() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/1022");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

PsbtDefaultSigner _getSigner5() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/1025");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

BitcoinBaseAddress _getBtcAddress5() {
  final s = _getSigner5();
  return s.privateKey.getPublic().toP2wshInP2sh();
}

BitcoinBaseAddress _getBtcAddress4() {
  final s = _getSigner4();
  return s.privateKey.getPublic().toP2wpkhInP2sh();
}

TaprootLeaf _getScript12() {
  final pk2 = _getSigner2().privateKey.getPublic();
  final pk3 = _getSigner3().privateKey.getPublic();
  return TaprootLeaf(
      script: Script(script: [
    pk2.toXOnlyHex(),
    BitcoinOpcode.opCheckSig,
    pk3.toXOnlyHex(),
    BitcoinOpcode.opCheckSigAdd,
    2,
    BitcoinOpcode.opNumEqual,
  ]));
}

BitcoinBaseAddress _getBtcAddress12() {
  final s = _getSigner();

  return P2trAddress.fromInternalKey(
      internalKey: s.privateKey.getPublic().toXOnly(),
      treeScript: _getScript12());
}

PsbtDefaultSigner _getTapScriptSigner() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/1022");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

MultiSignatureAddress _mSigOnlyWitness() {
  final s1 = _getSigner();
  final s2 = _getSigner2();
  final s3 = _getSigner3();
  final m = MultiSignatureAddress(threshold: 3, signers: [
    MultiSignatureSigner(publicKey: s1.signerPublicKey.toHex(), weight: 1),
    MultiSignatureSigner(publicKey: s2.signerPublicKey.toHex(), weight: 1),
    MultiSignatureSigner(publicKey: s3.signerPublicKey.toHex(), weight: 1),
  ]);

  return m;
}

MultiSignatureAddress _multisig() {
  final s1 = _getSigner();
  final s2 = _getSigner2();
  final s3 = _getSigner5();
  final m = MultiSignatureAddress(threshold: 4, signers: [
    MultiSignatureSigner(publicKey: s1.signerPublicKey.toHex(), weight: 1),
    MultiSignatureSigner(
        publicKey: s2.signerPublicKey.toHex(mode: PubKeyModes.uncompressed),
        weight: 1),
    MultiSignatureSigner(
        publicKey: s3.signerPublicKey.toHex(mode: PubKeyModes.uncompressed),
        weight: 2),
  ]);

  return m;
}

MultiSignatureAddress _multisig2() {
  final s1 = _getSigner();
  final s2 = _getSigner2();
  final s3 = _getSigner5();
  final m = MultiSignatureAddress(threshold: 2, signers: [
    MultiSignatureSigner(publicKey: s1.signerPublicKey.toHex(), weight: 1),
    MultiSignatureSigner(
        publicKey: s2.signerPublicKey.toHex(mode: PubKeyModes.uncompressed),
        weight: 1),
    MultiSignatureSigner(
        publicKey: s3.signerPublicKey.toHex(mode: PubKeyModes.uncompressed),
        weight: 1),
  ]);

  return m;
}

BitcoinBaseAddress _getBtcAddress9() {
  return _mSigOnlyWitness().toP2wshAddress(network: BitcoinNetwork.testnet);
}

BitcoinBaseAddress _getBtcAddress10() {
  return _multisig().toP2shAddress();
}

BitcoinBaseAddress _getBtcAddress11() {
  return _multisig2().toP2shAddress();
}

PsbtDefaultSigner _getSigner30() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/1025");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

PsbtDefaultSigner _getTapScriptSigner6() {
  final acc = _deriveKey(path: "m/86'/1'/0'/1/80");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

PsbtDefaultSigner _getSigner33() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0'/1025");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

PsbtDefaultSigner _getSigner31() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/1022");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

PsbtDefaultSigner _getSigner32() {
  final acc = _deriveKey(path: "m/86'/1'/0'/0/1025");
  return PsbtDefaultSigner(ECPrivate.fromBytes(acc.privateKey.raw));
}

TaprootLeaf _getLeafScript13() {
  final pk2 = _getSigner30().privateKey.getPublic();
  final pk4 = _getSigner31().privateKey.getPublic();
  return TaprootLeaf(
      script: Script(script: [
    pk2.toXOnlyHex(),
    BitcoinOpcode.opCheckSig,
    pk4.toXOnlyHex(),
    BitcoinOpcode.opCheckSigAdd,
    2,
    BitcoinOpcode.opNumEqual,
  ]));
}

TaprootTree _getScript13() {
  final pk2 = _getSigner30().privateKey.getPublic();
  final pk3 = _getSigner33().privateKey.getPublic();
  final pk4 = _getSigner31().privateKey.getPublic();
  final pk5 = _getSigner32().privateKey.getPublic();
  final c1 = TaprootLeaf(
      script: Script(script: [pk2.toXOnlyHex(), BitcoinOpcode.opCheckSig]));
  final c2 = TaprootLeaf(
      script: Script(script: [pk3.toXOnlyHex(), BitcoinOpcode.opCheckSig]));
  final c3 = TaprootLeaf(
      script: Script(script: [pk4.toXOnlyHex(), BitcoinOpcode.opCheckSig]));

  final c4 = TaprootLeaf(
      script: Script(script: [
    pk2.toXOnlyHex(),
    BitcoinOpcode.opCheckSig,
    pk4.toXOnlyHex(),
    BitcoinOpcode.opCheckSigAdd,
    2,
    BitcoinOpcode.opNumEqual,
  ]));
  final c5 = TaprootLeaf(
      script: Script(script: [pk5.toXOnlyHex(), BitcoinOpcode.opCheckSig]));

  return TaprootBranch(
      a: TaprootBranch(
          a: c1,
          b: TaprootBranch(
              a: c1, b: TaprootBranch(a: c2, b: TaprootBranch(a: c3, b: c5)))),
      b: TaprootBranch(a: c4, b: c1));
}

ECPublic _getInternalKey8() {
  return _getTapScriptSigner().signerPublicKey;
}

P2trAddress _getBtcAddress13() {
  final pk1 = _getTapScriptSigner();
  return P2trAddress.fromInternalKey(
      internalKey: pk1.signerPublicKey.toXOnly(), treeScript: _getScript13());
}

TaprootTree _treeScript25() {
  final pk2 = _getSigner12().privateKey.getPublic();
  final pk3 = _getSigner11().privateKey.getPublic();
  final pk4 = _getSigner31().privateKey.getPublic();
  final pk5 = _getSigner32().privateKey.getPublic();
  final pk6 = _getSigner32().privateKey.getPublic();
  return TaprootLeaf(
      script: Script(script: [
    pk2.toXOnlyHex(),
    BitcoinOpcode.opCheckSig,
    pk3.toXOnlyHex(),
    BitcoinOpcode.opCheckSigAdd,
    pk4.toXOnlyHex(),
    BitcoinOpcode.opCheckSigAdd,
    pk5.toXOnlyHex(),
    BitcoinOpcode.opCheckSigAdd,
    pk6.toXOnlyHex(),
    BitcoinOpcode.opCheckSigAdd,
    3,
    BitcoinOpcode.opNumEqual,
  ]));
}

P2trAddress _getBtcAddress14() {
  final pk7 = _getTapScriptSigner6().privateKey.getPublic();
  final c4 = _treeScript25();
  return P2trAddress.fromInternalKey(
      internalKey: pk7.toXOnly(), treeScript: c4);
}

(BitcoinBaseAddress, BitcoinBaseAddress, Script, List<int>) _getOpHash160() {
  final payload = StringUtils.encode('https://github.com/mrtnetwork');
  final hash160 = QuickCrypto.hash160(payload);
  final script = Script(script: [
    BitcoinOpcode.opHash160,
    BytesUtils.toHexString(hash160),
    BitcoinOpcode.opEqual
  ]);
  final p2sh = P2shAddress.fromScript(script: script);
  final p2wsh = P2wshAddress.fromScript(script: script);
  return (p2sh, p2wsh, script, payload);
}

(BitcoinBaseAddress, BitcoinBaseAddress, Script, List<int>) _getOpSHA256() {
  final payload = StringUtils.encode('https://github.com/mrtnetwork');
  final hash160 = QuickCrypto.sha256Hash(payload);
  final script = Script(script: [
    BitcoinOpcode.opSha256,
    BytesUtils.toHexString(hash160),
    BitcoinOpcode.opEqual
  ]);
  final p2sh = P2shAddress.fromScript(script: script);
  final p2wsh = P2wshAddress.fromScript(script: script);
  return (p2sh, p2wsh, script, payload);
}

(BitcoinBaseAddress, BitcoinBaseAddress, Script, List<int>) _getOpHASH256() {
  final preimage = StringUtils.encode('https://github.com/mrtnetwork');
  final hash = QuickCrypto.sha256DoubleHash(preimage);
  final script = Script(script: [
    BitcoinOpcode.opHash256,
    BytesUtils.toHexString(hash),
    BitcoinOpcode.opEqual
  ]);
  final p2sh = P2shAddress.fromScript(script: script);
  final p2wsh = P2wshAddress.fromScript(script: script);
  return (p2sh, p2wsh, script, preimage);
}

(BitcoinBaseAddress, Script, TaprootControlBlock, List<int>)
    _getTapScriptHash160() {
  final preImage = StringUtils.encode('https://github.com/mrtnetwork');
  final hash = QuickCrypto.hash160(preImage);
  final script = Script(script: [
    BitcoinOpcode.opHash160,
    BytesUtils.toHexString(hash),
    BitcoinOpcode.opEqual
  ]);
  final key = ECPrivate.fromBytes(List<int>.filled(32, 12));
  final block = TaprootControlBlock.generate(
      xOnlyOrInternalPubKey: key.getPublic().toXOnly(),
      leafScript: TaprootLeaf(script: script),
      scriptTree: TaprootLeaf(script: script));

  final p2sh = P2trAddress.fromInternalKey(
      internalKey: key.getPublic().toXOnly(),
      treeScript: TaprootLeaf(script: script));
  return (p2sh, script, block, preImage);
}

Bip32Slip10Secp256k1 _deriveKey(
    {String key =
        "tprv8ZgxMBicQKsPdgBQV2Y9EVPSjAGhyZXArhwSzHwnV3FytzPRr8KCR8EKEpLeHbANAncgbc31a6QoXjBTARQiZ2h1Z2NgSCjFYeTqKpAN5Gc",
    String path = "m/86'/1'/0'/0/1"}) {
  Bip32Slip10Secp256k1 secp = Bip32Slip10Secp256k1.fromExtendedKey(
      key, Bip44Coins.bitcoinTestnet.conf.keyNetVer);
  return secp.derivePath(path) as Bip32Slip10Secp256k1;
}
