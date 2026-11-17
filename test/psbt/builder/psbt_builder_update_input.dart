import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';
import 'psbt_update_output.dart';
import 'utxos_vector2.dart';

void psbtTest3() {
  void test_(PsbtBuilder builder, PsbtVersion version) {
    final expandUtxos = utxosVector2.expand((e) => e).toList();
    final psbtUtxos = expandUtxos.map((e) => PsbtUtxo.fromJson(e)).toList();
    final amount1 = BtcUtils.toSatoshi('0.001');
    final amount2 = BtcUtils.toSatoshi('0.0011');
    final amount3 = BtcUtils.toSatoshi('0.0012');
    builder.addUtxo(psbtUtxos[0]);
    builder.addOutput(
      PsbtTransactionOutput(amount: amount1, address: recipient1()),
    );
    expect(
      () => builder.addUtxo(psbtUtxos[0]),
      throwsA(
        isA<BuError>().having(
          (p0) => p0.message,
          'error message',
          contains('Duplicate input detected'),
        ),
      ),
    );
    builder = signFinalize(
      builder: builder,
      index: 0,
      utxos: expandUtxos,
      sighash: BitcoinOpCodeConst.sighashSingleAnyOneCanPay,
    );
    builder.addUtxo(psbtUtxos[1]);
    expect(
      () => builder.updateOutput(
        0,
        PsbtTransactionOutput(amount: amount2, address: recipient2()),
      ),
      throwsA(
        isA<BuError>().having(
          (p0) => p0.message,
          'error message',
          contains('Unable to modify output'),
        ),
      ),
    );
    builder.addOutput(
      PsbtTransactionOutput(amount: amount2, address: recipient2()),
    );
    builder = signFinalize(
      builder: builder,
      index: 1,
      utxos: expandUtxos,
      sighash: BitcoinOpCodeConst.sighashNoneAnyOneCanPay,
    );
    builder.updateOutput(
      1,
      PsbtTransactionOutput(amount: amount3, address: recipient3()),
    );
    expect(builder.txOutputs().length, 2);
    expect(builder.txOutputs()[0].scriptPubKey, recipient1().toScriptPubKey());
    expect(builder.txOutputs()[0].amount, amount1);
    expect(builder.txOutputs()[1].scriptPubKey, recipient3().toScriptPubKey());
    expect(builder.txOutputs()[1].amount, amount3);
    builder.addUtxo(psbtUtxos[2]);
    builder = signFinalize(
      builder: builder,
      index: 2,
      utxos: expandUtxos,
      sighash: BitcoinOpCodeConst.sighashAll,
    );
    expect(
      () => builder.addOutput(
        PsbtTransactionOutput(amount: amount2, address: recipient4()),
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
      () => builder.addUtxo(psbtUtxos[3]),
      throwsA(
        isA<BuError>().having(
          (p0) => p0.message,
          'error message',
          contains('Unable to modify input'),
        ),
      ),
    );
    expect(builder.txInputs().length, 3);
    expect(builder.indexFinalized(0), true);
    expect(builder.indexFinalized(1), true);
    expect(builder.indexFinalized(2), true);
    final tx = builder.finalizeAll();
    expect(
      tx.serialize(),
      "02000000000103cb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0000000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0100000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0200000000ffffffff02a086010000000000225120adf0c64c5b821de7bce3b840ce764edbb50adb61dbbe98caa3ffde6c612a71b0c0d401000000000017a9141849e0be5299d74ff8310a31ab6b93d9d98dad8087074180c5213ae6ddce9f53a9512cea35660ad4f341d76beb4c58bd7c5c9792f38e9fc3f91b4feaabeaf593515fdb45e96697b56bde83395158d56622c3445236515b834180c5213ae6ddce9f53a9512cea35660ad4f341d76beb4c58bd7c5c9792f38e9fc3f91b4feaabeaf593515fdb45e96697b56bde83395158d56622c3445236515b83414ec49c1c525e2ec6d7bb95058b03c932b18479f30b69d82227647a601cf52f39b91e1c7210b148f224eba069a8bc346ab081659d5092f6e3f83d9730a4fed0b6830000ac205e6ae939f1e87542d2b43ba27dabfddee68bb03c0f8ea1893e1f09e2f50e256bac203a1a902bf14317faffae2568fdcbdc188d9455ae60a2dfbf5dc3b226d7844977ba2026733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87ba20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba539c21c1af82536a8922025e345e6bd10f15061b22ff8d3dacc86dd6403c136d5b47f11e0441d14e230a6484aaa72b6db119f9051ae95664236564ea0e63d54c9958072b3b0a17d152a169e67e6bdd70f1ec7cbd0c49657120773ddc711b5a292e2cb2302bc48241d91fe91f409ae77ef0a4fe23029568a1c3036a4145f945df3c6ed36ff7dc49406f2e4c4dbefa6224cde89f9122c6baa1acf7c24f6c6bf9dc956cb29d21806b7b824620cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fac2026733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87ba529c61c126733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87e696fde00a8758def6d9648541848f44e36d9f823864c659f8f1f2bf3203c1c4d968d4f3d4ebada4fbe1211c2a276b48a0081d1e1a8391b86a1adacb8a85523d044185a17154fc19ac6cae71964135a50f48184c3559102f6c0e3a42e98707ae02dfce30b21d1851011330ec03ff28ece52f710e001864bc71427ca1b081a0e86f29014185a17154fc19ac6cae71964135a50f48184c3559102f6c0e3a42e98707ae02dfce30b21d1851011330ec03ff28ece52f710e001864bc71427ca1b081a0e86f29014620cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fac20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba529c21c126733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d8700000000",
    );
    expect(version, builder.psbtVersion);
  }

  test("description", () {
    test_(PsbtBuilderV0.create(), PsbtVersion.v0);
    test_(PsbtBuilderV2.create(), PsbtVersion.v2);
  });
}

void psbtTest4() {
  test("description", () {
    final expandUtxos = utxosVector2.expand((e) => e).toList();
    final psbtUtxos = expandUtxos.map((e) => PsbtUtxo.fromJson(e)).toList();
    PsbtBuilder builder = PsbtBuilderV0.create();
    builder.addUtxo(psbtUtxos[0]);
    expect(builder.txInputs().length, 1);
    _expectInput(builder: builder, utxo: psbtUtxos[0], index: 0);
    builder.updateInput(0, PsbtTransactionInput.fromUtxo(psbtUtxos[1]));
    _expectInput(builder: builder, utxo: psbtUtxos[1], index: 0);
    builder = signFinalize(
      builder: builder,
      index: 0,
      utxos: expandUtxos,
      sighash: BitcoinOpCodeConst.sighashAll,
    );

    expect(() => builder.removeInput(0), throwsA(isA<BuError>()));
    builder = PsbtBuilderV0.create();
    expect(builder.txInputs().length, 0);
    expect(builder.txOutputs().length, 0);
    expect(
      () => builder.psbtInput(0),
      throwsA(
        isA<BuError>().having(
          (p0) => p0.message,
          'error message',
          contains('Invalid input index'),
        ),
      ),
    );
    builder.addUtxo(psbtUtxos[0]);
    final amount2 = BtcUtils.toSatoshi('0.0011');
    final amount3 = BtcUtils.toSatoshi('0.0012');
    builder.addOutput(
      PsbtTransactionOutput(amount: amount2, address: recipient1()),
    );
    builder.addOutput(
      PsbtTransactionOutput(amount: amount3, address: recipient2()),
    );
    builder = signFinalize(
      builder: builder,
      index: 0,
      utxos: expandUtxos,
      sighash: BitcoinOpCodeConst.sighashNoneAnyOneCanPay,
    );
    builder.addUtxo(psbtUtxos[1]);
    builder = signFinalize(
      builder: builder,
      index: 1,
      utxos: expandUtxos,
      sighash: BitcoinOpCodeConst.sighashNoneAnyOneCanPay,
    );

    builder.addUtxo(psbtUtxos[2]);

    builder = signFinalize(
      builder: builder,
      index: 2,
      utxos: expandUtxos,
      sighash: BitcoinOpCodeConst.sighashAll,
    );
    final tx = builder.finalizeAll();
    expect(
      tx.txId(),
      "f9a4f122347356516a40f49ab5b14d71ae4f88ec82b285dff5835f9ec9dc3e2b",
    );
  });
}

void _expectInput({
  required PsbtBuilder builder,
  required PsbtUtxo utxo,
  required int index,
}) {
  final txInputs = builder.txInputs();
  expect(txInputs[index].txId, utxo.utxo.txHash);
  expect(txInputs[index].txIndex, utxo.utxo.vout);
}
