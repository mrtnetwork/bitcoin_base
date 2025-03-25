import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  _test1();
}

void _addP2PkhInout(PsbtBuilder psbt) {
  final address = P2pkhAddress.fromAddress(
      address: "modADgm9UHadfWLQVKeHapbHjETkwwY6zs",
      network: BitcoinNetwork.testnet);
  psbt.addInput(PsbtTransactionInput.legacy(
      txId: "0a4217b239c54c1d46edf2042b7546a5f9c0ac60a0f7d4b72787586fe4c3ffbe",
      amount: BigInt.from(500000),
      outIndex: 1,
      nonWitnessUtxo: BtcTransaction.deserialize(BytesUtils.fromHexString(
          "02000000000101ee63737203248a1e03e2bc03318e753a91ac988de2f4f5cdaaf0d5195b0a0ead0000000000fdffffff02ed0de508840100001600147b458433d0c04323426ef88365bd4cfef141ac7520a10700000000001976a91458ed74ce76848830523000e26d27aa2f292bcce788ac02473044022061165ee01f36822393c0705b4afd2b634929f2344f42674dc5299af4fa76a15c0220077dd5f8a746993c96b117c3ed6ed269a7d539c9d690422fc92e49f2185cd13b0121030db9616d96a7b7a8656191b340f77e905ee2885a09a7a1e80b9c8b64ec746fb300000000")),
      scriptPubKey: address.toScriptPubKey(),
      bip32derivationPath: [
        PsbtInputBip32DerivationPath.fromBip32(
            masterKey: getMasterKey(path: null), path: "m/86'/1'/0'/0/1034")
      ]));
}

void _test1() {
  test("PSBT", () {
    void checkBuilder(PsbtBuilderV0 builder) {
      final inputs = builder.txInputs();
      expect(inputs.length, 1);
      expect(inputs.first.txId,
          "0a4217b239c54c1d46edf2042b7546a5f9c0ac60a0f7d4b72787586fe4c3ffbe");
      expect(inputs.first.txIndex, 1);
      final psbtInput = builder.psbtInput(0);
      expect(psbtInput.taprootKeyBip32DerivationPath?.length, 1);
      final key = psbtInput.bip32derivationPath![0];
      expect(key.path, "m/86'/1'/0'/0/1034");
      final privateKey = key.toKeyDerivation().derive(getMasterKey(path: null));
      expect(privateKey.privateKey.toHex(),
          "39d9f93498ab9c5e833b6e22493be2aaa8d4daabb141afac801fccbf1298cd05");
      expect(privateKey.fingerPrint.toBytes(), key.fingerprint);
      expect(privateKey.publicKey.compressed, key.publicKey);
      final totalAmount = BigInt.from(500000);
      final receipt1 = _getReceipt();
      final receipt2 = _getReceipt2();
      final rec1Amount = BtcUtils.toSatoshi("0.00002");
      final fee = BtcUtils.toSatoshi("0.0001");
      final changeAmount = totalAmount - (rec1Amount + fee);
      final outputs = builder.txOutputs();
      expect(outputs.length, 2);
      expect(outputs[1].scriptPubKey, receipt1.toScriptPubKey());
      expect(outputs[1].amount, changeAmount);
      expect(outputs[0].scriptPubKey, receipt2.toScriptPubKey());
      expect(outputs[0].amount, rec1Amount);
    }

    final builder = PsbtBuilderV0.create();
    expect(builder.psbtVersion, PsbtVersion.v0);
    _addP2PkhInout(builder);

    final totalAmount = BigInt.from(500000);
    final receipt1 = _getReceipt();
    final receipt2 = _getReceipt2();
    final rec1Amount = BtcUtils.toSatoshi("0.00002");
    final fee = BtcUtils.toSatoshi("0.0001");
    final changeAmount = totalAmount - (rec1Amount + fee);
    builder.addOutput(
        PsbtTransactionOutput(amount: rec1Amount, address: receipt2));
    builder.addOutput(
        PsbtTransactionOutput(amount: changeAmount, address: receipt1));
    checkBuilder(builder);

    /// invalid signer public key
    expect(() {
      return builder.signInput(
          signer: (p0) {
            return PsbtSignerResponse(signers: [
              PsbtDefaultSigner(ECPrivate.fromHex(
                  "33053373fe566dc4f77941a449c20dfa356221dfadec5e3d507c58279e0e1991"))
            ]);
          },
          index: 0);
    }, throwsA(isA<DartBitcoinPluginException>()));
    expect(() {
      final clone = PsbtBuilder.fromBase64(builder.toBase64());
      final privateKey = ECPrivate.fromHex(
          "39d9f93498ab9c5e833b6e22493be2aaa8d4daabb141afac801fccbf1298cd05");
      clone.signInput(
          signer: (p0) {
            return PsbtSignerResponse(signers: [PsbtDefaultSigner(privateKey)]);
          },
          index: 0);
      final finalize = clone.finalizeAll();
      return finalize.serialize();
    }(),
        "0200000001beffc3e46f588727b7d4f7a060acc0f9a546752b04f2ed461d4cc539b217420a010000008a473044022058eec26fcc66609066963d4be2b5559b8863ed973fb50757a681d97ff11f0f98022052d63ce1fe1d372a09d0f1cd2389fccefdcf18f9380e168621d8809cbc1225790141045e6ae939f1e87542d2b43ba27dabfddee68bb03c0f8ea1893e1f09e2f50e256bba49f505c6292cb76bea21868164f1ce9187ff94d302ecb2ab209eea2bc9274effffffff02d00700000000000017a914e56a8afdd4489d018e28cdf5bc662aabeb3f0b8387407207000000000017a9144185f108a273961c1641b503ea1deda5fd4468868700000000");
    _addP2shAddress(builder);
  });
}

void _addP2shAddress(PsbtBuilder builder) {
  final newBuilder = PsbtBuilder.fromBase64(builder.toBase64());
  final p2shSigner = P2shAddress.fromAddress(
      address: "2N3oneRSj5C4jUWsSFmAkY6FX45kW7tUUP5",
      network: BitcoinNetwork.testnet);

  /// missing p2sh redeemscript
  expect(
      () => newBuilder.addInput(PsbtTransactionInput.legacy(
          outIndex: 1,
          txId:
              "a1eb2001c7941f3f9c7a8cbbd25829148c40b9766e821c7afc2770defab1b196",
          amount: BigInt.from(500000),
          scriptPubKey: p2shSigner.toScriptPubKey())),
      throwsA(isA<DartBitcoinPluginException>()));

  /// invalid p2sh redeemscript;
  expect(
      () => newBuilder.addInput(PsbtTransactionInput.legacy(
          outIndex: 1,
          redeemScript: Script(script: [
            "26733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87",
            BitcoinOpcode.opCheckSig,
          ]),
          nonWitnessUtxo: BtcTransaction.deserialize(BytesUtils.fromHexString(
              "02000000000101beffc3e46f588727b7d4f7a060acc0f9a546752b04f2ed461d4cc539b217420a0000000000fdffffff025f63dd08840100001600147b458433d0c04323426ef88365bd4cfef141ac7520a107000000000017a91473d9d46bdadd9cb20c68330385d21bbf457500f28702473044022055ffaa4dd3ddfe16a681a8cc07bce7c64aea0e955806fc4abc475e79e9dd1801022053cee4bf5366e32bdeb976fc654d65ca798dfebdb05f3118ceb8dda517616d6e0121030db9616d96a7b7a8656191b340f77e905ee2885a09a7a1e80b9c8b64ec746fb300000000")),
          txId:
              "a1eb2001c7941f3f9c7a8cbbd25829148c40b9766e821c7afc2770defab1b196",
          amount: BigInt.from(500000),
          scriptPubKey: p2shSigner.toScriptPubKey())),
      throwsA(isA<DartBitcoinPluginException>()));
  newBuilder.addInput(PsbtTransactionInput.legacy(
      outIndex: 1,
      redeemScript: Script(script: [
        "043a1a902bf14317faffae2568fdcbdc188d9455ae60a2dfbf5dc3b226d784497726f6523d1cd0da24863f8d943dd1fd3c7030efc2636d3238bec7d558c075ce7e",
        BitcoinOpcode.opCheckSig,
      ]),
      txId: "a1eb2001c7941f3f9c7a8cbbd25829148c40b9766e821c7afc2770defab1b196",
      nonWitnessUtxo: BtcTransaction.deserialize(BytesUtils.fromHexString(
          "02000000000101beffc3e46f588727b7d4f7a060acc0f9a546752b04f2ed461d4cc539b217420a0000000000fdffffff025f63dd08840100001600147b458433d0c04323426ef88365bd4cfef141ac7520a107000000000017a91473d9d46bdadd9cb20c68330385d21bbf457500f28702473044022055ffaa4dd3ddfe16a681a8cc07bce7c64aea0e955806fc4abc475e79e9dd1801022053cee4bf5366e32bdeb976fc654d65ca798dfebdb05f3118ceb8dda517616d6e0121030db9616d96a7b7a8656191b340f77e905ee2885a09a7a1e80b9c8b64ec746fb300000000")),
      amount: BigInt.from(500000),
      scriptPubKey: p2shSigner.toScriptPubKey()));
  expect(newBuilder.txInputs().length, 2);
  final inputs = newBuilder.txInputs();
  expect(inputs.length, 2);

  /// sign and verify txId
  expect(() {
    final clone = PsbtBuilder.fromBase64(newBuilder.toBase64());
    final privateKey = ECPrivate.fromHex(
        "39d9f93498ab9c5e833b6e22493be2aaa8d4daabb141afac801fccbf1298cd05");
    clone.signInput(
        signer: (p0) {
          return PsbtSignerResponse(signers: [PsbtDefaultSigner(privateKey)]);
        },
        index: 0);

    /// invalid signer private key
    expect(
        () => clone.signInput(
            signer: (p0) {
              return PsbtSignerResponse(
                  signers: [PsbtDefaultSigner(privateKey)]);
            },
            index: 1),
        throwsA(isA<DartBitcoinPluginException>()));
    final p2shSigner = ECPrivate.fromHex(
        "33053373fe566dc4f77941a449c20dfa356221dfadec5e3d507c58279e0e1991");
    clone.signInput(
        signer: (p0) {
          return PsbtSignerResponse(signers: [PsbtDefaultSigner(p2shSigner)]);
        },
        index: 1);
    clone.finalizeInput(0);
    clone.finalizeInput(1);
    return clone.finalizeAll().txId();
  }(), "1860946eaed196fb865910c01205fc838601fad08df99fd125b86391fd107798");
  expect(() {
    final clone = PsbtBuilder.fromBase64(newBuilder.toBase64());
    final privateKey = ECPrivate.fromHex(
        "39d9f93498ab9c5e833b6e22493be2aaa8d4daabb141afac801fccbf1298cd05");
    clone.signInput(
        signer: (p0) {
          return PsbtSignerResponse(signers: [PsbtDefaultSigner(privateKey)]);
        },
        index: 0);

    /// reject adding output after exist signature sighash all
    expect(() {
      final clone = PsbtBuilder.fromBase64(newBuilder.toBase64());
      final privateKey = ECPrivate.fromHex(
          "39d9f93498ab9c5e833b6e22493be2aaa8d4daabb141afac801fccbf1298cd05");
      clone.signInput(
          signer: (p0) {
            return PsbtSignerResponse(signers: [PsbtDefaultSigner(privateKey)]);
          },
          index: 0);
      clone.addOutput(PsbtTransactionOutput(
          amount: BigInt.from(10000), address: _getReceipt3()));
    }, throwsA(isA<DartBitcoinPluginException>()));

    /// success add wit sighash none
    int successAddAfterSighashNone() {
      final clone = PsbtBuilder.fromBase64(newBuilder.toBase64());
      final privateKey = ECPrivate.fromHex(
          "39d9f93498ab9c5e833b6e22493be2aaa8d4daabb141afac801fccbf1298cd05");
      clone.signInput(
          signer: (p0) {
            return PsbtSignerResponse(
              sighash: BitcoinOpCodeConst.sighashNone,
              signers: [PsbtDefaultSigner(privateKey)],
            );
          },
          index: 0);
      clone.addOutput(PsbtTransactionOutput(
          amount: BigInt.from(10000), address: _getReceipt3()));
      return clone.txOutputs().length;
    }

    expect(successAddAfterSighashNone(), 3);

    /// invalid signer private key
    expect(
        () => clone.signInput(
            signer: (p0) {
              return PsbtSignerResponse(
                  signers: [PsbtDefaultSigner(privateKey)]);
            },
            index: 1),
        throwsA(isA<DartBitcoinPluginException>()));
    final p2shSigner = ECPrivate.fromHex(
        "33053373fe566dc4f77941a449c20dfa356221dfadec5e3d507c58279e0e1991");
    clone.signInput(
        signer: (p0) {
          return PsbtSignerResponse(signers: [PsbtDefaultSigner(p2shSigner)]);
        },
        index: 1);
    clone.finalizeInput(0);
    clone.finalizeInput(1);
    return clone.finalizeAll().txId();
  }(), "1860946eaed196fb865910c01205fc838601fad08df99fd125b86391fd107798");
}

Bip32Slip10Secp256k1 getMasterKey(
    {String key =
        "tprv8ZgxMBicQKsPdgBQV2Y9EVPSjAGhyZXArhwSzHwnV3FytzPRr8KCR8EKEpLeHbANAncgbc31a6QoXjBTARQiZ2h1Z2NgSCjFYeTqKpAN5Gc",
    String? path = "m/86'/1'/0'/0/1"}) {
  Bip32Slip10Secp256k1 masterKey = Bip32Slip10Secp256k1.fromExtendedKey(
      key, Bip44Coins.bitcoinTestnet.conf.keyNetVer);
  if (path == null) return masterKey;
  return masterKey.derivePath(path) as Bip32Slip10Secp256k1;
}

ECPrivate getPrivateKeyFromMasterKey(
    {String key =
        "tprv8ZgxMBicQKsPdgBQV2Y9EVPSjAGhyZXArhwSzHwnV3FytzPRr8KCR8EKEpLeHbANAncgbc31a6QoXjBTARQiZ2h1Z2NgSCjFYeTqKpAN5Gc",
    String? path = "m/86'/1'/0'/0/1"}) {
  final bip = getMasterKey(key: key, path: path);
  return ECPrivate.fromBytes(bip.privateKey.raw);
}

ECPublic getPublicKeyFromMasterKey(
    {String key =
        "tprv8ZgxMBicQKsPdgBQV2Y9EVPSjAGhyZXArhwSzHwnV3FytzPRr8KCR8EKEpLeHbANAncgbc31a6QoXjBTARQiZ2h1Z2NgSCjFYeTqKpAN5Gc",
    String? path = "m/86'/1'/0'/0/1"}) {
  return getPrivateKeyFromMasterKey(key: key, path: path).getPublic();
}

BitcoinBaseAddress _getReceipt() {
  final acc = getMasterKey(path: "m/86'/1'/0'/0/1022");
  final pk = ECPublic.fromBytes(acc.publicKey.compressed);
  return pk.toP2wpkhInP2sh();
}

BitcoinBaseAddress _getReceipt2() {
  final acc = getMasterKey(path: "m/86'/1'/0'/0/1025");
  final pk = ECPublic.fromBytes(acc.publicKey.compressed);
  return pk.toP2wshInP2sh();
}

BitcoinBaseAddress _getReceipt3() {
  final acc = getMasterKey(path: "m/86'/1'/0'/0/1026");
  final pk = ECPublic.fromBytes(acc.publicKey.compressed);
  return pk.toAddress();
}
