import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'utxos_vector.dart';

void main() {
  test("PSBT", () {
    _test(PsbtBuilderV0.create());
    _test(PsbtBuilderV2.create());
  });
}

void _test(PsbtBuilder builder) {
  final expandUtxos = utxos.expand((e) => e).toList();
  final psbtUtxos = expandUtxos.map((e) => PsbtUtxo.fromJson(e)).toList();
  builder.addUtxos(psbtUtxos);
  final inputs = builder.txInputs();
  expect(inputs.length, expandUtxos.length);

  for (int i = 0; i < expandUtxos.length; i++) {
    final input = inputs[i];
    expect(input.txId, expandUtxos[i]["utxo"]["tx_hash"]);
    expect(input.txIndex, expandUtxos[i]["utxo"]["vout"]);
  }
  final output = builder.txOutputs();
  expect(output.length, 0);
  final totalAmoumt =
      psbtUtxos.fold<BigInt>(BigInt.zero, (p, c) => p + c.utxo.value);
  final fee = BtcUtils.toSatoshi('0.0001');
  final amount1 = BtcUtils.toSatoshi('0.001');
  final amount2 = BtcUtils.toSatoshi('0.0011');
  final amount3 = BtcUtils.toSatoshi('0.0012');
  final change = totalAmoumt - amount1 - amount2 - amount3 - fee;

  final r1 = P2trAddress.fromAddress(
      address: "tb1pypcrdc24z5jahxus00kgp5rr3z5hy5ma0slanjskglx6c0nyxz8suncnq7",
      network: BitcoinNetwork.testnet);
  final r2 = P2shAddress.fromAddress(
      address: "2ND8PB9RrfCaAcjfjP1Y6nAgFd9zWHYX4DN",
      network: BitcoinNetwork.testnet);
  final r3 = P2shAddress.fromAddress(
      address: "2MuTei1oXmMKbmnDBCfKCtrbWDdbnriYZXm",
      network: BitcoinNetwork.testnet);
  final r4 = P2pkhAddress.fromAddress(
      address: "modADgm9UHadfWLQVKeHapbHjETkwwY6zs",
      network: BitcoinNetwork.testnet);
  builder.addOutput(PsbtTransactionOutput(amount: amount1, address: r1));
  builder.signInput(
      signer: (params) {
        expect(params.index, 0);
        final utxo = utxos[params.index];
        expect(utxo.length, 1);
        expect(utxo[0]["address"],
            params.address.toAddress(BitcoinNetwork.testnet));
        final signers = (utxo[0]["privateKeys"] as List)
            .map((e) => ECPrivate.fromHex(e))
            .toList();
        return PsbtSignerResponse(
            signers: signers.map((e) => PsbtDefaultSigner(e)).toList(),
            sighash: BitcoinOpCodeConst.sighashSingle,
            tapleafHash: BytesUtils.tryFromHexString(utxo[0]["select_leaf"]));
      },
      index: 0);
  builder.addOutput(PsbtTransactionOutput(amount: amount2, address: r2));
  builder.signInput(
      signer: (params) {
        expect(params.index, 1);
        final utxo = utxos[params.index];
        expect(utxo.length, 2);
        expect(utxo[0]["address"],
            params.address.toAddress(BitcoinNetwork.testnet));
        final signers = (utxo[0]["privateKeys"] as List)
            .map((e) => ECPrivate.fromHex(e))
            .toList();

        /// taproot script-path with multiple tapleaf script exists
        /// in this case should we pass correct tapleaf.
        return PsbtSignerResponse(
            signers: signers.map((e) => PsbtDefaultSigner(e)).toList(),
            sighash: BitcoinOpCodeConst.sighashSingle,
            tapleafHash: BytesUtils.tryFromHexString(utxo[0]["select_leaf"]));
      },
      index: 1);
  builder.addOutput(PsbtTransactionOutput(amount: amount3, address: r3));
  builder.signInput(
      signer: (params) {
        expect(params.index, 2);
        final utxo = utxos[1];
        expect(utxo.length, 2);
        expect(utxo[1]["address"],
            params.address.toAddress(BitcoinNetwork.testnet));
        final signers = (utxo[1]["privateKeys"] as List)
            .map((e) => ECPrivate.fromHex(e))
            .toList();

        /// taproot script-path with multiple tapleaf script exists
        /// in this case should we pass correct tapleaf.
        return PsbtSignerResponse(
            signers: signers.map((e) => PsbtDefaultSigner(e)).toList(),
            sighash: BitcoinOpCodeConst.sighashSingle,
            tapleafHash: BytesUtils.tryFromHexString(utxo[1]["select_leaf"]));
      },
      index: 2);
  builder.addOutput(PsbtTransactionOutput(amount: change, address: r4));

  /// sign all inputs with SIGHASH_ALL
  builder.signAllInput(
    (p0) {
      if (p0.inputData.partialSigs != null ||
          p0.inputData.taprootScriptSpendSignature != null) {
        return null;
      }
      final signers = (expandUtxos[p0.index]["privateKeys"] as List)
          .map((e) => ECPrivate.fromHex(e))
          .toList();
      return PsbtSignerResponse(
          signers: signers.map((e) => PsbtDefaultSigner(e)).toList(),
          sighash: BitcoinOpCodeConst.sighashAll,
          tapleafHash: BytesUtils.tryFromHexString(
              expandUtxos[p0.index]["select_leaf"]));
    },
  );
  expect(
      () => builder.addInput(PsbtTransactionInput.legacy(
          outIndex: 0,
          txId: BytesUtils.toHexString(QuickCrypto.generateRandom()),
          amount: BigInt.from(10000),
          address: P2pkhAddress.fromAddress(
              address: "modADgm9UHadfWLQVKeHapbHjETkwwY6zs",
              network: BitcoinNetwork.testnet))),
      throwsA(isA<DartBitcoinPluginException>().having((p0) => p0.message,
          'error message', contains('Missing input non-witness UTXOs'))));
  final key14 = PsbtDefaultSigner(ECPrivate.fromHex(
      "efd4d62709543c1bae8a22b44640856b48398b7d06f57958760a8695b9f5f171"));
  final newBuilder = PsbtBuilder.fromBase64(builder.toBase64());
  newBuilder.signInput(
      signer: (params) => PsbtSignerResponse(signers: [key14]), index: 14);
  final tx = newBuilder.finalizeAll(
    onFinalizeInput: (params) {
      if (params.inputData.taprootLeafScript != null &&
          params.inputData.taprootLeafScript!.length > 1) {
        /// taproot script-path with multiple tapleaf script exists
        /// in this case should we pass correct tapleaf.
        return PsbtFinalizeResponse(
            tapleafHash: BytesUtils.tryFromHexString(
                expandUtxos[params.index]["select_leaf"]));
      }
      return null;
    },
  );
  expect(tx.inputs.length, expandUtxos.length);
  expect(tx.outputs.length, 4);
  expect(tx.outputs[0].scriptPubKey, r1.toScriptPubKey());
  expect(tx.outputs[1].scriptPubKey, r2.toScriptPubKey());
  expect(tx.outputs[2].scriptPubKey, r3.toScriptPubKey());
  expect(tx.outputs[3].scriptPubKey, r4.toScriptPubKey());
  expect(tx.outputs[0].amount, amount1);
  expect(tx.outputs[1].amount, amount2);
  expect(tx.outputs[2].amount, amount3);
  expect(tx.outputs[3].amount, change);
  expect(tx.hasWitness, true);
  expect(tx.serialize(),
      "02000000000113410913729457adf83e83fd620761a2adc4d3d342f96e5f1a463cbd8d42a65c890100000000ffffffff24913db187292098b5a99d7a21aceae44fa529b1892a841d4d22b26a3e213d210100000000ffffffff9f3bc50478585408a73c292d6550772d7cd138d63b55f3cd473292210eb7c7370000000000ffffffff91228f25131bd03a1b8f5c1737312d9d5963378a0481117e1b53615b71e7c2090100000000ffffffff05d94483dd289d4e8ee43202e2859a6f963541c5c7b83a928fe2878d8b1f3cba0000000000ffffffff44cd6d65362a9e09b7a16b27a1413e16a3097524cedf9282dc539d3743838fb20100000000ffffffff585d7c8ebe83e172a2de1c9651229ac58dd0ab52a83b38fcb9fd5614f4dd87600100000000ffffffff91e6377bb8cc8f2dc2e74aa35d00cee90f54439adedb9e6a70e5b54df6c8b48f01000000fd0e020047304402201c0c70413c1f7aa7d85723ccdcd6a2d01aed5afb49bedfcf8f66c28f543963640220648a6b1a480268f2752c91895d26f52809875ba966eb761e7b64db8c2e93cbd20147304402205edb3b1fa9a99a220a923523bea1d84029c488a25dcb7465b0db69628470e2dc0220668adef2514c07433756e5bc5b5eb6ddf97e5476f8ff868ef0c4e032c09bfc420147304402205edb3b1fa9a99a220a923523bea1d84029c488a25dcb7465b0db69628470e2dc0220668adef2514c07433756e5bc5b5eb6ddf97e5476f8ff868ef0c4e032c09bfc420147304402205edb3b1fa9a99a220a923523bea1d84029c488a25dcb7465b0db69628470e2dc0220668adef2514c07433756e5bc5b5eb6ddf97e5476f8ff868ef0c4e032c09bfc42014ceb54210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d874104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc36494104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc36494104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc364954aeffffffffd7f59b462d2e266956e14826a16ad1585924eaee1f3e85d45a44947ec732f2cf01000000fd3c010047304402204eecd3ee698ba7f7dee1782d6c15bbf449dcda9e6c391a95a8597e5c2bd3a70602202879f95b47bfb0237eda5f2df0f0216270072e134d20116bc1cf2cf93fce4444014730440220056c84a7afc61d9eb60f4ea0018e48786669a68b84038033f743b9c77527e5c202205ad0b5ab865f9af383048cd64529637b115ec8e4f2fc6b6852f6e72bc6d6c530014ca952210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d874104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc36494104cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fe5690748be2d1358b2e4375bf6185416fa24db998d9501a165e3a2a577bc364953aeffffffffb4dd6c05b64baf220d42702d71a6023cc9a8ef38d7d3ccf523ecab92ee2b55a501000000020151ffffffff809cd4c4df13b7914968ea849e958e64f7d90735e515d1f314858d64e33f56bd01000000232200204ae81572f06e1b88fd5ced7a1a000945432e83e1551e6f721ee9c00b8cc33260ffffffffdfec4c78c7fc29a5a67a0aa8b6ab04db5914ccfdf78a891d6c0be477f7a6bf95000000006c4730440220717139bb42e376e94c28fcea63e2f6d746dad4f7b9af162145d8e4da8c7b5be302202858971660c85ccde274095d3874193f482aa604f4e122f477cd4b2dc46e7b450123210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87acffffffffc59ff6d282bfb2308e9880129685d3b3cc8807211902103a5747e75a3a3215e50100000023220020640f8c50d23cdfb05deeeb989304ba8e2d270eda368c3b0c024191c3370467a9ffffffff6dcae52c906f44ed0d02329de0d8cd60f087bf2ba36fdd13927fda1da9e0f44c0100000000ffffffff8e09c938270e7102a804e5be2b9a89bc7ed36ce4e59e20848c8a2bc13835f2ea0100000000ffffffffdfec4c78c7fc29a5a67a0aa8b6ab04db5914ccfdf78a891d6c0be477f7a6bf95010000008447304402207494ecd0c531d3a8360b929920f5a11c48caee1c36261a01183c038aecf143cb0220318b91997cafdf8d3c15272f8b99aa51eba532adf76caa0d8b1d46685411caf4012103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f1976a914b273443219d7f2652349caceecbb641cceb7b92288acffffffff0b76290e390e13a946e727ac2d78b0c9fc220969ebbb9ded97dbb3ae7736f95f010000001716001425761a501d439b764831e1a9c1b50c48c7cb2af1ffffffff96b1b1fade7027fc7a1c826e76b9408c142958d2bb8c7a9c3f1f94c70120eba1010000008c473044022077c0ac5efbd0ebf4c06adfbafbf14bdc2603687852da25b07b994c3e277c7905022055a1bc07a45dc20985ed16f228742ff9d6e486391575a46d31eef34db08b082e014341043a1a902bf14317faffae2568fdcbdc188d9455ae60a2dfbf5dc3b226d784497726f6523d1cd0da24863f8d943dd1fd3c7030efc2636d3238bec7d558c075ce7eacffffffffbeffc3e46f588727b7d4f7a060acc0f9a546752b04f2ed461d4cc539b217420a010000008a47304402200b3aeee45f74ee61fa7b44cd93c6bdd6c1e98cb274331aaf0376dcf442751faa022025f2b6ad67d251494a9e78854edb023541bbb60b353547407b4f4a8f8d421af70141045e6ae939f1e87542d2b43ba27dabfddee68bb03c0f8ea1893e1f09e2f50e256bba49f505c6292cb76bea21868164f1ce9187ff94d302ecb2ab209eea2bc9274effffffff04a086010000000000225120207036e1551525db9b907bec80d06388a972537d7c3fd9ca1647cdac3e64308fb0ad01000000000017a914da1745e9b549bd0bfa1a569971c77eba30cd5a4b87c0d401000000000017a9141849e0be5299d74ff8310a31ab6b93d9d98dad8087f8c83900000000001976a91458ed74ce76848830523000e26d27aa2f292bcce788ac07414f1d56e9312b37afd31dbdb6e63c06fca6fb8514c7aa9a1d59d95840614e8ba4a5103066993e6d64cef441899ee45e7ac5a939a27ac7b057e894effaa367f67b03414f1d56e9312b37afd31dbdb6e63c06fca6fb8514c7aa9a1d59d95840614e8ba4a5103066993e6d64cef441899ee45e7ac5a939a27ac7b057e894effaa367f67b0341d9bf64eddc45622a109b059ea087f1f35cda617cca082cbc2812e47ca5499980367158f01d7958b938e7e19e5afa56208ffa3871d967a88cf3e57b6923a08ace030000ac205e6ae939f1e87542d2b43ba27dabfddee68bb03c0f8ea1893e1f09e2f50e256bac203a1a902bf14317faffae2568fdcbdc188d9455ae60a2dfbf5dc3b226d7844977ba2026733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87ba20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba539c21c1af82536a8922025e345e6bd10f15061b22ff8d3dacc86dd6403c136d5b47f11e0441196b2b96a538e8f101f61d077b26a8d1696ad19649a346692e2710633f841c13131dd8a1b9d7339cb0956bae79ceeabefe557aec05d2a98dc8a0e557775905490341ae46e8c16b2e80253d23ac9dea2c5e303f937e7743aa144d2c95ed49cb9750d712db56f8369aab4d57088b259d2fe5b0c338028e19d83db367009b628b5cc806034620cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fac2026733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87ba529c61c126733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87e696fde00a8758def6d9648541848f44e36d9f823864c659f8f1f2bf3203c1c4d968d4f3d4ebada4fbe1211c2a276b48a0081d1e1a8391b86a1adacb8a85523d04414f104ae761e587a559ff48ba3d184f58cdda6c63f84dfd0a0e4fc0f4ad0669b3447cc736f0f100e4ffff1af8a3ea801afc4c3a000ac3fc8844387b6ef69f67900341586a2b47877a5f005f207bee74327066816f1d48881468834103323604d70d02fe92167de3ac6434b8dc89daa93315aa7bb8eaec4cc3cab3b540abfb03050535034620cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fac2026733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87ba529c61c126733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87e696fde00a8758def6d9648541848f44e36d9f823864c659f8f1f2bf3203c1c4d968d4f3d4ebada4fbe1211c2a276b48a0081d1e1a8391b86a1adacb8a85523d0441bc66661d4f06c88cc16a4c7d7b7dcc949cddcd2e7c81a31d7703ef35231cbf307166147f96b9bbf399a7fe30eda5d44864b45c06e5cce713934faeb4df759f0a0141bc66661d4f06c88cc16a4c7d7b7dcc949cddcd2e7c81a31d7703ef35231cbf307166147f96b9bbf399a7fe30eda5d44864b45c06e5cce713934faeb4df759f0a014620cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fac20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba529c21c126733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d870441328f374971614d9826fa4faf13ef41d70dc524e2a40b77b1429c8a7c1269c16db83e5637a8d49186d1e55ac7a986230baad191fb7a3f257f373808c3b6222e900141328f374971614d9826fa4faf13ef41d70dc524e2a40b77b1429c8a7c1269c16db83e5637a8d49186d1e55ac7a986230baad191fb7a3f257f373808c3b6222e90014620cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fac20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba529c21c126733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d870441c770cbee83f94443c4f3c0bfe50906da00511843b0c8f9f21143569f31ab51f8ecfcbf7df2aed1523c93b3590ac4c2212be4873ae8c325a8b7f2d78aaf6b4b320141c770cbee83f94443c4f3c0bfe50906da00511843b0c8f9f21143569f31ab51f8ecfcbf7df2aed1523c93b3590ac4c2212be4873ae8c325a8b7f2d78aaf6b4b32014620cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fac20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba529c21c126733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87050047304402201da9ec0c6d31754213dd34bc827a55ede0b6504dbc469b5ff2226c65c6070f66022027f7f5b061b4376b4e6ddfb909c705662b543dfb579c8388ef73c838958a670e0147304402204ad1ceead0a2caa1c4496e0394852a1388920a24b133c1b11a82f1689c2031a10220014d6f1474acd3ea17e2d01ee911e2f91a81755b7d02e5dccc76e72cef63b1af0147304402204ad1ceead0a2caa1c4496e0394852a1388920a24b133c1b11a82f1689c2031a10220014d6f1474acd3ea17e2d01ee911e2f91a81755b7d02e5dccc76e72cef63b1af016953210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d872103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f2103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f53ae0000000101510003004730440220130acbcb1d91b66ece6c4e1092067eaafc7018517abad15d2ba157b93424f6a302202e94639c4aa11ac82cfd3d469afa825e7d116c7ca5a795388d945d847f9e646b0125512103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f51ae01419e27486161463fb17cd71dfd2f463a8fea78a05e8e6e17c6feb794539a2fef2bec2088a560a1ff7a2d64c1110e6e69aba377bab8dbfa4308cf4453fffed3d44e010247304402203ea2fda5871f33389ecc88d5b1d283397d286d3d92f36d14e3dcfbab388ce851022079de1cbe0021e0e533285beb182fd68b817b40a3589f430fc555747fee17d6ab012103cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972f00024730440220104bfbc220ff7c7634e502bbd1529326b1aa08f7ae8a591f65c38e7255f74551022073108e41a3151277485ffb04d3db848a6cd5912f539608de302eb88e2bbc2fa101210226733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87000000000000");
}
