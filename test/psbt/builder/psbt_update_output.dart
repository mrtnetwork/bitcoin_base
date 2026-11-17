import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import 'psbt_builder_v0.dart';
import 'utxos_vector2.dart';

/// Pinned BIP-340 aux for golden comparisons: default aux is fresh randomness
/// per call, so exact-hex goldens below need deterministic signing.
final List<int> _zeroAux = List<int>.filled(32, 0);

void psbtTest5() {
  void test_(PsbtBuilder builder) {
    final expandUtxos = utxosVector2.expand((e) => e).toList();
    final psbtUtxos = expandUtxos.map((e) => PsbtUtxo.fromJson(e)).toList();
    builder.addUtxos(psbtUtxos);
    final inputs = builder.txInputs();
    expect(inputs.length, 18);
    final amount1 = BtcUtils.toSatoshi('0.001');
    final amount2 = BtcUtils.toSatoshi('0.0011');
    final amount3 = BtcUtils.toSatoshi('0.0012');
    builder.addOutput(
      PsbtTransactionOutput(amount: amount1, address: recipient1()),
    );
    builder.addOutput(
      PsbtTransactionOutput(amount: amount2, address: recipient2()),
    );
    builder.addOutput(
      PsbtTransactionOutput(amount: amount3, address: recipient3()),
    );

    /// sign input 1 signash signle
    builder.signInput(
      signer: (p0) {
        final signers =
            (expandUtxos[0]["privateKeys"] as List)
                .map((e) => ECPrivate.fromHex(e))
                .toList();
        return PsbtSignerResponse(
          signers:
              signers.map((e) => PsbtDefaultSigner(e, aux: _zeroAux)).toList(),
          sighash: BitcoinOpCodeConst.sighashSingle,
          tapleafHash: BytesUtils.tryFromHexString(
            expandUtxos[0]["select_leaf"],
          ),
        );
      },
      index: 0,
    );

    /// must output 0 update beacuse we dont change script pubkey of receipment and just add some additional fields to output.
    builder.updateOutput(
      0,
      PsbtTransactionOutput.witnessV1(
        amount: amount1,
        address: recipient1(),
        taprootKeyBip32DerivationPath: [
          PsbtOutputTaprootKeyBip32DerivationPath.fromBip32(
            masterKey: getMasterKey(path: null),
            path: "m/86'/1'/0'/0/1",
            treeScript: receipt1Script(),
          ),
        ],
      ),
    );

    /// failed becuse of changing output 0 scriptPubKey
    expect(
      () => builder.updateOutput(
        0,
        PsbtTransactionOutput(amount: amount1, address: recipient2()),
      ),
      throwsA(
        isA<BuError>().having(
          (p0) => p0.message,
          'error message',
          contains('Unable to modify output'),
        ),
      ),
    );
    final decode = PsbtBuilder.fromBase64(builder.toBase64());
    final output = decode.psbtOutput(0);
    expect(output.address, recipient1());
    expect(output.scriptPubKey, recipient1().toScriptPubKey());
    expect(output.amount, amount1);
    expect(output.taprootKeyBip32DerivationPath?.length, 1);
    final key = output.taprootKeyBip32DerivationPath![0];
    expect(key.path, "m/86'/1'/0'/0/1");
    final bip32 = key.toKeyDerivation().derive(getMasterKey(path: null));
    expect(ECPublic.fromBip32(bip32.publicKey).toXOnly(), key.xOnlyPubKey);
    final tx = signAll(
      builder: decode,
      start: 1,
      utxos: utxosVector2.expand((e) => e).toList(),
    );
    expect(
      tx.serialize(),
      "02000000000112cb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0000000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0100000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0200000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0300000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd04000000fd0e020047304402202d3750152b4b07fb29e8eb12a22b354743b1dc8050d5e70d8761a4aab907719f0220113c1df38506b392847245e2c2b136458675f107c210dd2d943b75a6e86e52bc0247304402207fd7bdb8785729b8f108dbc6ed5411d71bf45366e92ba69e8f33b8969247c323022008713a7e0baedf5dbd9c264644abcbb8d0fce5479039707a08aa39a9674d013b0247304402207fd7bdb8785729b8f108dbc6ed5411d71bf45366e92ba69e8f33b8969247c323022008713a7e0baedf5dbd9c264644abcbb8d0fce5479039707a08aa39a9674d013b0247304402207fd7bdb8785729b8f108dbc6ed5411d71bf45366e92ba69e8f33b8969247c323022008713a7e0baedf5dbd9c264644abcbb8d0fce5479039707a08aa39a9674d013b024ceb54210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d874104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc36494104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc36494104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc364954aeffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd05000000fd3c01004730440220657fd158a9954909dde886d77201f9b1d3d5a15a4f714de848731c5a5260348e02206e57fd77f9d6e15cc321012dfae5399a14052aa3fe25a0a819f0511a4e5fe60a02473044022004dfa64708a804edcf0c6475f27228437fa9575deda42d762318afe9b601eeb702207de93b2a509b8e559223a21dd9b0d45a7d8a82182dd90cbcef324a69b053d414024ca952210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d874104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc36494104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc364953aeffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd06000000020151ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd07000000232200204ae81572f06e1b88fd5ced7a1a000945432e83e1551e6f721ee9c00b8cc33260ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd080000006c4730440220770e91d320f9fc8907d8640c90698e474a300bbc4c6c6ce11b525a14af54872d02201ad64ec583c9a7717b3de4887957681d12f2daaa567495ae63af672e05c4d3290223210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87acffffffff6251cd87d9e60941a02995fd6c17f7eb541eb6944fd4064ac308f749036bd7910000000023220020640f8c50d23cdfb05deeeb989304ba8e2d270eda368c3b0c024191c3370467a9ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0900000023220020640f8c50d23cdfb05deeeb989304ba8e2d270eda368c3b0c024191c3370467a9ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0a00000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0c00000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0d0000008447304402204cc480d90a8e1b0f0f3399e6e7da2f15e754c63786c574bde06c38b57570e7dc0220515944140cd51930ac213838b94d53ff8a44c698f4d82bb783a8c2e1ea76a6ae022103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f1976a914b273443219d7f2652349caceecbb641cceb7b92288acffffffff6251cd87d9e60941a02995fd6c17f7eb541eb6944fd4064ac308f749036bd791010000001716001425761a501d439b764831e1a9c1b50c48c7cb2af1ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0e0000001716001425761a501d439b764831e1a9c1b50c48c7cb2af1ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0f0000008c47304402205ad0284476ab36b12e75e7c241127805da935f891f47577fa427098fc592b29502202406e1e1c4d1abf37ec5a840512521a662cbddb68cc8fd61876eaecc09c2811c024341043a1a902bf14317faffae2568fdcbdc188d9455ae60a2dfbf5dc3b226d784497726f6523d1cd0da24863f8d943dd1fd3c7030efc2636d3238bec7d558c075ce7eacffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd100000008a473044022006f8f52055b41e46197ed5af9ff857d0509a683c3abad5fa620a15597affe79902204a5b15d7a9a0d94afa446dbbace0580fb24692aaf87598e4c3569f1b0fdd4a000241045e6ae939f1e87542d2b43ba27dabfddee68bb03c0f8ea1893e1f09e2f50e256bba49f505c6292cb76bea21868164f1ce9187ff94d302ecb2ab209eea2bc9274effffffff03a086010000000000225120adf0c64c5b821de7bce3b840ce764edbb50adb61dbbe98caa3ffde6c612a71b0b0ad01000000000017a914da1745e9b549bd0bfa1a569971c77eba30cd5a4b87c0d401000000000017a9141849e0be5299d74ff8310a31ab6b93d9d98dad80870741566083c58879e979fb04daa0044e19241154917e5f49330b9c14c4526fdb74d0e7ca22488db9050fda774f83c488fe55546c750a9d4a176f612dcc4d3758c9470341566083c58879e979fb04daa0044e19241154917e5f49330b9c14c4526fdb74d0e7ca22488db9050fda774f83c488fe55546c750a9d4a176f612dcc4d3758c947034147d5284bf6e5d956074c7debd18ce32fad3ebf64dd7da476e2a128531167f8c0d8b6e9c0ae6569b213f71e05fa863e2bb8d91ef5a093a5727f9a94e4f8d89179030000ac205e6ae939f1e87542d2b43ba27dabfddee68bb03c0f8ea1893e1f09e2f50e256bac203a1a902bf14317faffae2568fdcbdc188d9455ae60a2dfbf5dc3b226d7844977ba2026733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87ba20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba539c21c1af82536a8922025e345e6bd10f15061b22ff8d3dacc86dd6403c136d5b47f11e044117d2c4aecca6317423c4824164d097c48be5a7177ef348ddb27e8db740998e40e930ba939311d6ffb606bde9f42950b5a4293ba6c5233307260e084d3c5c2efd024155c6acb887c44fe7969a77a921a4b645aeef7c43dfd3fb8bff91887c45c8736b4347700ac0bc63d8fe0df1c22330590c67ff8f166ec226d21c570fae0a1fea1a024620cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fac2026733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87ba529c61c126733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87e696fde00a8758def6d9648541848f44e36d9f823864c659f8f1f2bf3203c1c4d968d4f3d4ebada4fbe1211c2a276b48a0081d1e1a8391b86a1adacb8a85523d0441e2aa5154437771120fa61df901cf38d9c9870c75a3290e82a3a439a1e249335c3e8cc138a6a0a1ab139cf0b483a0f3354d8f884cec5369c38df3f2ea467f99ad0241e2aa5154437771120fa61df901cf38d9c9870c75a3290e82a3a439a1e249335c3e8cc138a6a0a1ab139cf0b483a0f3354d8f884cec5369c38df3f2ea467f99ad024620cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fac20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba529c21c126733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87050047304402203b8b7f7582861fcb0a123384fb27eed955211981cace15be5f23dcba91acc1ea0220069e22b95f0b3b8b84900fff3ee36c2023b7d666cea79ee6b2943c10f086b4af02473044022067aa8ae099bc506607e9003f1ac700e3d9e002850638b64deb1e348f3923062e02202a243956ca84fee515f5ea73d72e8ac13004ae9ea0ec2883e5e0304810b22f9d02473044022067aa8ae099bc506607e9003f1ac700e3d9e002850638b64deb1e348f3923062e02202a243956ca84fee515f5ea73d72e8ac13004ae9ea0ec2883e5e0304810b22f9d026953210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d872103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f2103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f53ae0000000101510003004730440220763676877907f84386c2d3395dc98326c88c64e9219a6261ae2ce8b8b232628d0220527c318d19c2e57ac063979bf7345f19aaf41d39bf4249537341ad7a753177690225512103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f51ae0300473044022034ed3ac6b1bef3872b39f1f7a802f3538e4ded7493850cb31650d2ab9f99556602201f1a1c937cb13238a73aa18f1c4108651400fc7007b3941ca01671fb20d823540225512103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f51ae01411fce73f411078dbbf65adb0cb15dd4e2c1320b56c4bd02b56cd509a12fc69f01bbfebd912567c2b6f2f2167d70fbb3cef3ce5cff4d19f77e453169f93f39dd2902024730440220721850489b542f24fcda6155faa5347286127afeeb25b160de53671674967944022058b73c7582a70698d4567a4c84ff06c8d4eaf3758c0c5f6525970f9a38f7448b022103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f00024730440220203b0547e76224744d05fb94fd9f3f5b2b81055a223dd8dd07b1b2846df9f44b02206f607ffa6f3dba6d95c0f26963e2a169bafbe49c5bb145d1e6789bc7d77dfb6902210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87024730440220211bb5644b9179618b33365e6ad396ee98626b81a55861983e8675ad5f87d14d022003d2a48cc13059bee9eba42f7992d452d2f95e7e2ab862ea46fe6595cd1fee9002210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87000000000000",
    );
  }

  test("PSBTV2", () {
    test_(PsbtBuilderV0.create());
    test_(PsbtBuilderV2.create());
  });
}

BtcTransaction signAll({
  required PsbtBuilder builder,
  required int start,
  required List<Map<String, dynamic>> utxos,
}) {
  PsbtBuilder bl = builder;
  for (int i = start; i < utxos.length; i++) {
    bl = PsbtBuilder.fromBase64(bl.toBase64());
    bl.signInput(
      index: i,
      signer: (p0) {
        final signers =
            (utxos[p0.index]["privateKeys"] as List)
                .map((e) => ECPrivate.fromHex(e))
                .toList();
        return PsbtSignerResponse(
          signers:
              signers.map((e) => PsbtDefaultSigner(e, aux: _zeroAux)).toList(),
          sighash: BitcoinOpCodeConst.sighashNone,
          tapleafHash: BytesUtils.tryFromHexString(
            utxos[p0.index]["select_leaf"],
          ),
        );
      },
    );
    bl.finalizeInput(
      i,
      onFinalizeInput: (params) {
        return PsbtFinalizeResponse(
          tapleafHash: BytesUtils.tryFromHexString(
            utxos[params.index]["select_leaf"],
          ),
        );
      },
    );
  }
  return bl.finalizeAll();
}

PsbtBuilder signFinalize({
  required PsbtBuilder builder,
  required int index,
  required List<Map<String, dynamic>> utxos,
  required int sighash,
}) {
  sign(builder: builder, index: index, utxos: utxos, sighash: sighash);
  builder.finalizeInput(
    index,
    onFinalizeInput: (params) {
      return PsbtFinalizeResponse(
        tapleafHash: BytesUtils.tryFromHexString(
          utxos[params.index]["select_leaf"],
        ),
      );
    },
  );
  return PsbtBuilder.fromBase64(builder.toBase64());
}

PsbtBuilder sign({
  required PsbtBuilder builder,
  required int index,
  required List<Map<String, dynamic>> utxos,
  required int sighash,
}) {
  builder.signInput(
    signer: (p0) {
      final signers =
          (utxos[p0.index]["privateKeys"] as List)
              .map((e) => ECPrivate.fromHex(e))
              .toList();
      return PsbtSignerResponse(
        signers:
            signers.map((e) => PsbtDefaultSigner(e, aux: _zeroAux)).toList(),
        sighash: sighash,
        tapleafHash: BytesUtils.tryFromHexString(
          utxos[p0.index]["select_leaf"],
        ),
      );
    },
    index: index,
  );
  return PsbtBuilder.fromBase64(builder.toBase64());
}

void psbtTest6() {
  void test_(PsbtBuilder builder) {
    final utxos = utxosVector2.expand((e) => e).toList();
    final psbtUtxos = utxos.map((e) => PsbtUtxo.fromJson(e)).toList();
    builder.addUtxos(psbtUtxos);
    final inputs = builder.txInputs();
    expect(inputs.length, 18);
    final amount1 = BtcUtils.toSatoshi('0.001');
    final amount2 = BtcUtils.toSatoshi('0.0011');
    builder.addOutput(
      PsbtTransactionOutput(amount: amount1, address: recipient1()),
    );

    sign(
      builder: builder,
      index: 0,
      utxos: utxos,
      sighash: BitcoinOpCodeConst.sighashSingle,
    );

    /// must output 0 update beacuse we dont change script pubkey of receipment and just add some additional fields to output.
    builder.updateOutput(
      0,
      PsbtTransactionOutput.witnessV1(
        amount: amount1,
        address: recipient1(),
        taprootKeyBip32DerivationPath: [
          PsbtOutputTaprootKeyBip32DerivationPath.fromBip32(
            masterKey: getMasterKey(path: null),
            path: "m/86'/1'/0'/0/1",
            treeScript: receipt1Script(),
          ),
        ],
      ),
    );

    /// failed becuse of changing output 0 scriptPubKey
    expect(
      () => builder.updateOutput(
        0,
        PsbtTransactionOutput(amount: amount1, address: recipient2()),
      ),
      throwsA(
        isA<BuError>().having(
          (p0) => p0.message,
          'error message',
          contains('Unable to modify output'),
        ),
      ),
    );
    expect(builder.txOutputs().length, 1);

    sign(
      builder: builder,
      index: 1,
      utxos: utxos,
      sighash: BitcoinOpCodeConst.sighashNone,
    );
    builder.addOutput(
      PsbtTransactionOutput(amount: amount2, address: recipient2()),
    );
    builder.updateOutput(
      1,
      PsbtTransactionOutput(amount: amount2, address: recipient3()),
    );
    final outs = builder.txOutputs();
    expect(outs.length, 2);
    expect(outs[1].scriptPubKey, recipient3().toScriptPubKey());
    expect(outs[1].amount, amount2);
    sign(
      builder: builder,
      index: 2,
      utxos: utxos,
      sighash: BitcoinOpCodeConst.sighashAll,
    );
    expect(
      () => builder.updateOutput(
        0,
        PsbtTransactionOutput(amount: amount1, address: recipient2()),
      ),
      throwsA(
        isA<BuError>().having(
          (p0) => p0.message,
          'error message',
          contains('Unable to modify output'),
        ),
      ),
    );
    expect(
      () => builder.addOutput(
        PsbtTransactionOutput(amount: amount1, address: recipient2()),
      ),
      throwsA(
        isA<BuError>().having(
          (p0) => p0.message,
          'error message',
          contains('Unable to modify output'),
        ),
      ),
    );
    final r = signAll(builder: builder, start: 3, utxos: utxos);
    expect(
      r.serialize(),
      "02000000000112cb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0000000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0100000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0200000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0300000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd04000000fd0e020047304402202d3750152b4b07fb29e8eb12a22b354743b1dc8050d5e70d8761a4aab907719f0220113c1df38506b392847245e2c2b136458675f107c210dd2d943b75a6e86e52bc0247304402207fd7bdb8785729b8f108dbc6ed5411d71bf45366e92ba69e8f33b8969247c323022008713a7e0baedf5dbd9c264644abcbb8d0fce5479039707a08aa39a9674d013b0247304402207fd7bdb8785729b8f108dbc6ed5411d71bf45366e92ba69e8f33b8969247c323022008713a7e0baedf5dbd9c264644abcbb8d0fce5479039707a08aa39a9674d013b0247304402207fd7bdb8785729b8f108dbc6ed5411d71bf45366e92ba69e8f33b8969247c323022008713a7e0baedf5dbd9c264644abcbb8d0fce5479039707a08aa39a9674d013b024ceb54210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d874104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc36494104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc36494104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc364954aeffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd05000000fd3c01004730440220657fd158a9954909dde886d77201f9b1d3d5a15a4f714de848731c5a5260348e02206e57fd77f9d6e15cc321012dfae5399a14052aa3fe25a0a819f0511a4e5fe60a02473044022004dfa64708a804edcf0c6475f27228437fa9575deda42d762318afe9b601eeb702207de93b2a509b8e559223a21dd9b0d45a7d8a82182dd90cbcef324a69b053d414024ca952210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d874104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc36494104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc364953aeffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd06000000020151ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd07000000232200204ae81572f06e1b88fd5ced7a1a000945432e83e1551e6f721ee9c00b8cc33260ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd080000006c4730440220770e91d320f9fc8907d8640c90698e474a300bbc4c6c6ce11b525a14af54872d02201ad64ec583c9a7717b3de4887957681d12f2daaa567495ae63af672e05c4d3290223210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87acffffffff6251cd87d9e60941a02995fd6c17f7eb541eb6944fd4064ac308f749036bd7910000000023220020640f8c50d23cdfb05deeeb989304ba8e2d270eda368c3b0c024191c3370467a9ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0900000023220020640f8c50d23cdfb05deeeb989304ba8e2d270eda368c3b0c024191c3370467a9ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0a00000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0c00000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0d0000008447304402204cc480d90a8e1b0f0f3399e6e7da2f15e754c63786c574bde06c38b57570e7dc0220515944140cd51930ac213838b94d53ff8a44c698f4d82bb783a8c2e1ea76a6ae022103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f1976a914b273443219d7f2652349caceecbb641cceb7b92288acffffffff6251cd87d9e60941a02995fd6c17f7eb541eb6944fd4064ac308f749036bd791010000001716001425761a501d439b764831e1a9c1b50c48c7cb2af1ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0e0000001716001425761a501d439b764831e1a9c1b50c48c7cb2af1ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0f0000008c47304402205ad0284476ab36b12e75e7c241127805da935f891f47577fa427098fc592b29502202406e1e1c4d1abf37ec5a840512521a662cbddb68cc8fd61876eaecc09c2811c024341043a1a902bf14317faffae2568fdcbdc188d9455ae60a2dfbf5dc3b226d784497726f6523d1cd0da24863f8d943dd1fd3c7030efc2636d3238bec7d558c075ce7eacffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd100000008a473044022006f8f52055b41e46197ed5af9ff857d0509a683c3abad5fa620a15597affe79902204a5b15d7a9a0d94afa446dbbace0580fb24692aaf87598e4c3569f1b0fdd4a000241045e6ae939f1e87542d2b43ba27dabfddee68bb03c0f8ea1893e1f09e2f50e256bba49f505c6292cb76bea21868164f1ce9187ff94d302ecb2ab209eea2bc9274effffffff02a086010000000000225120adf0c64c5b821de7bce3b840ce764edbb50adb61dbbe98caa3ffde6c612a71b0b0ad01000000000017a9141849e0be5299d74ff8310a31ab6b93d9d98dad80870741566083c58879e979fb04daa0044e19241154917e5f49330b9c14c4526fdb74d0e7ca22488db9050fda774f83c488fe55546c750a9d4a176f612dcc4d3758c9470341566083c58879e979fb04daa0044e19241154917e5f49330b9c14c4526fdb74d0e7ca22488db9050fda774f83c488fe55546c750a9d4a176f612dcc4d3758c947034147d5284bf6e5d956074c7debd18ce32fad3ebf64dd7da476e2a128531167f8c0d8b6e9c0ae6569b213f71e05fa863e2bb8d91ef5a093a5727f9a94e4f8d89179030000ac205e6ae939f1e87542d2b43ba27dabfddee68bb03c0f8ea1893e1f09e2f50e256bac203a1a902bf14317faffae2568fdcbdc188d9455ae60a2dfbf5dc3b226d7844977ba2026733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87ba20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba539c21c1af82536a8922025e345e6bd10f15061b22ff8d3dacc86dd6403c136d5b47f11e044117d2c4aecca6317423c4824164d097c48be5a7177ef348ddb27e8db740998e40e930ba939311d6ffb606bde9f42950b5a4293ba6c5233307260e084d3c5c2efd024155c6acb887c44fe7969a77a921a4b645aeef7c43dfd3fb8bff91887c45c8736b4347700ac0bc63d8fe0df1c22330590c67ff8f166ec226d21c570fae0a1fea1a024620cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fac2026733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87ba529c61c126733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87e696fde00a8758def6d9648541848f44e36d9f823864c659f8f1f2bf3203c1c4d968d4f3d4ebada4fbe1211c2a276b48a0081d1e1a8391b86a1adacb8a85523d0441f918f87d11887f8ce5aff1059d83842cfecfea490ce7e9fcb63246074d200855ef72b35b81211a94579fe3d21e041582ed7f78f798331647e516d4231639c3280141f918f87d11887f8ce5aff1059d83842cfecfea490ce7e9fcb63246074d200855ef72b35b81211a94579fe3d21e041582ed7f78f798331647e516d4231639c328014620cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fac20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba529c21c126733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87050047304402203b8b7f7582861fcb0a123384fb27eed955211981cace15be5f23dcba91acc1ea0220069e22b95f0b3b8b84900fff3ee36c2023b7d666cea79ee6b2943c10f086b4af02473044022067aa8ae099bc506607e9003f1ac700e3d9e002850638b64deb1e348f3923062e02202a243956ca84fee515f5ea73d72e8ac13004ae9ea0ec2883e5e0304810b22f9d02473044022067aa8ae099bc506607e9003f1ac700e3d9e002850638b64deb1e348f3923062e02202a243956ca84fee515f5ea73d72e8ac13004ae9ea0ec2883e5e0304810b22f9d026953210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d872103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f2103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f53ae0000000101510003004730440220763676877907f84386c2d3395dc98326c88c64e9219a6261ae2ce8b8b232628d0220527c318d19c2e57ac063979bf7345f19aaf41d39bf4249537341ad7a753177690225512103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f51ae0300473044022034ed3ac6b1bef3872b39f1f7a802f3538e4ded7493850cb31650d2ab9f99556602201f1a1c937cb13238a73aa18f1c4108651400fc7007b3941ca01671fb20d823540225512103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f51ae01411fce73f411078dbbf65adb0cb15dd4e2c1320b56c4bd02b56cd509a12fc69f01bbfebd912567c2b6f2f2167d70fbb3cef3ce5cff4d19f77e453169f93f39dd2902024730440220721850489b542f24fcda6155faa5347286127afeeb25b160de53671674967944022058b73c7582a70698d4567a4c84ff06c8d4eaf3758c0c5f6525970f9a38f7448b022103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f00024730440220203b0547e76224744d05fb94fd9f3f5b2b81055a223dd8dd07b1b2846df9f44b02206f607ffa6f3dba6d95c0f26963e2a169bafbe49c5bb145d1e6789bc7d77dfb6902210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87024730440220211bb5644b9179618b33365e6ad396ee98626b81a55861983e8675ad5f87d14d022003d2a48cc13059bee9eba42f7992d452d2f95e7e2ab862ea46fe6595cd1fee9002210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87000000000000",
    );
  }

  test("description", () {
    test_(PsbtBuilderV0.create());
    test_(PsbtBuilderV2.create());
  });
}

BitcoinBaseAddress recipient2() {
  return P2shAddress.fromAddress(
    address: "2ND8PB9RrfCaAcjfjP1Y6nAgFd9zWHYX4DN",
    network: BitcoinNetwork.testnet,
  );
}

BitcoinBaseAddress recipient3() {
  return P2shAddress.fromAddress(
    address: "2MuTei1oXmMKbmnDBCfKCtrbWDdbnriYZXm",
    network: BitcoinNetwork.testnet,
  );
}

BitcoinBaseAddress recipient4() {
  return P2pkhAddress.fromAddress(
    address: "modADgm9UHadfWLQVKeHapbHjETkwwY6zs",
    network: BitcoinNetwork.testnet,
  );
}

TaprootTree receipt1Script() {
  final signerOne = getPublicKeyFromMasterKey(path: "m/86'/1'/0'/1/1");
  final signerTwo = getPublicKeyFromMasterKey(path: "m/86'/1'/0'/1/2");
  return TaprootBranch(
    a: TaprootLeaf(
      script: Script(
        script: [signerOne.toXOnlyHex(), BitcoinOpcode.opCheckSig],
      ),
    ),
    b: TaprootLeaf(
      script: Script(
        script: [signerTwo.toXOnlyHex(), BitcoinOpcode.opCheckSig],
      ),
    ),
  );
}

BitcoinBaseAddress recipient1() {
  final key = getMasterKey();
  final publicKey = ECPublic.fromBip32(key.publicKey);
  return P2trAddress.fromInternalKey(internalKey: publicKey.toXOnly());
}
