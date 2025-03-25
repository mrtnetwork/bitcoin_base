import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';
import 'psbt_update_output_test.dart';
import 'utxos_vector2.dart';

void main() {
  _test1();
  _test();
}

void _test() {
  void test_(PsbtBuilder builder, PsbtVersion version) {
    final expandUtxos = utxosVector2.expand((e) => e).toList();
    final psbtUtxos = expandUtxos.map((e) => PsbtUtxo.fromJson(e)).toList();
    final amount1 = BtcUtils.toSatoshi('0.001');
    final amount2 = BtcUtils.toSatoshi('0.0011');
    final amount3 = BtcUtils.toSatoshi('0.0012');
    builder.addUtxo(psbtUtxos[0]);
    builder.addOutput(
        PsbtTransactionOutput(amount: amount1, address: recipient1()));
    expect(
        () => builder.addUtxo(psbtUtxos[0]),
        throwsA(isA<DartBitcoinPluginException>().having((p0) => p0.message,
            'error message', contains('Duplicate input detected'))));
    builder = signFinalize(
        builder: builder,
        index: 0,
        utxos: expandUtxos,
        sighash: BitcoinOpCodeConst.sighashSingleAnyOneCanPay);
    builder.addUtxo(psbtUtxos[1]);
    expect(
        () => builder.updateOutput(
            0, PsbtTransactionOutput(amount: amount2, address: recipient2())),
        throwsA(isA<DartBitcoinPluginException>().having((p0) => p0.message,
            'error message', contains('Unable to modify output'))));
    builder.addOutput(
        PsbtTransactionOutput(amount: amount2, address: recipient2()));
    builder = signFinalize(
        builder: builder,
        index: 1,
        utxos: expandUtxos,
        sighash: BitcoinOpCodeConst.sighashNoneAnyOneCanPay);
    builder.updateOutput(
        1, PsbtTransactionOutput(amount: amount3, address: recipient3()));
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
        sighash: BitcoinOpCodeConst.sighashAll);
    expect(
        () => builder.addOutput(
            PsbtTransactionOutput(amount: amount2, address: recipient4())),
        throwsA(isA<DartBitcoinPluginException>().having((p0) => p0.message,
            'error message', contains('Unable to modify output'))));
    expect(
        () => builder.addUtxo(psbtUtxos[3]),
        throwsA(isA<DartBitcoinPluginException>().having((p0) => p0.message,
            'error message', contains('Unable to modify input'))));
    expect(builder.txInputs().length, 3);
    expect(builder.indexFinalized(0), true);
    expect(builder.indexFinalized(1), true);
    expect(builder.indexFinalized(2), true);
    final tx = builder.finalizeAll();
    expect(tx.serialize(),
        "02000000000103cb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0000000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0100000000ffffffffcb518ff0d558dd716c3612204fbb2c6f152597ae2dc12da71961a4bc2cf41edd0200000000ffffffff02a086010000000000225120adf0c64c5b821de7bce3b840ce764edbb50adb61dbbe98caa3ffde6c612a71b0c0d401000000000017a9141849e0be5299d74ff8310a31ab6b93d9d98dad80870741b7267375cc52dbbab47f5ce818511c19b942f1b6d7800ee89a67aba8ab9da42ddc45675128c755f9519bf7cbbfd7a6f4f0aa2b7e91f7ccc34b6aef95be0452088341b7267375cc52dbbab47f5ce818511c19b942f1b6d7800ee89a67aba8ab9da42ddc45675128c755f9519bf7cbbfd7a6f4f0aa2b7e91f7ccc34b6aef95be04520883418c8a6fe46a6568667c363710cd57e1cec85f50160cf5d0d19a72b82b8c99420dbc3bbb9884f56d91ef54a0a9658f07e06bf83ae8c7efb599957f408da798539b830000ac205e6ae939f1e87542d2b43ba27dabfddee68bb03c0f8ea1893e1f09e2f50e256bac203a1a902bf14317faffae2568fdcbdc188d9455ae60a2dfbf5dc3b226d7844977ba2026733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87ba20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba539c21c1af82536a8922025e345e6bd10f15061b22ff8d3dacc86dd6403c136d5b47f11e0441bd0f97b640a9bbecc0b4cc8008d5cec04556eae7ac7d8e6b348d55947e659db021e99901f487c1e87fbcd2a90864c9c6a43fc2ce7bfd007eff74ad0e6019715d824162087df7de3018936968dda1a2627c6cfaf89ae512dd466a285a7bd6ee19a8faad661225d6b14b52b2a983791a6b11494ffaa6b287225bcdd37895a195ec8aaf824620cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fac2026733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87ba529c61c126733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d87e696fde00a8758def6d9648541848f44e36d9f823864c659f8f1f2bf3203c1c4d968d4f3d4ebada4fbe1211c2a276b48a0081d1e1a8391b86a1adacb8a85523d0441565003500b20d4488c2e49c7d6de32aa4b3734cc30316be40fcd583e2ec4999265c37e3236854b9c3c72cf5b551417294c62cc89008ab8028d2e354753bd2ee00141565003500b20d4488c2e49c7d6de32aa4b3734cc30316be40fcd583e2ec4999265c37e3236854b9c3c72cf5b551417294c62cc89008ab8028d2e354753bd2ee0014620cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fac20cf65d59727afaa2a63a6dff145acc408a1d9e05f95f5ebc70e58f7342aa2972fba529c21c126733c182391e43d803292c4eb2403e059591fedc2203f2b590e8fd677214d8700000000");
    expect(version, builder.psbtVersion);
  }

  test("description", () {
    test_(PsbtBuilderV0.create(), PsbtVersion.v0);
    test_(PsbtBuilderV2.create(), PsbtVersion.v2);
  });
}

void _test1() {
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
        sighash: BitcoinOpCodeConst.sighashAll);
    builder.removeInput(0);
    expect(builder.txInputs().length, 0);
    expect(builder.txOutputs().length, 0);
    expect(
        () => builder.psbtInput(0),
        throwsA(isA<DartBitcoinPluginException>().having((p0) => p0.message,
            'error message', contains('Invalid input index'))));
    builder.addUtxo(psbtUtxos[0]);
    final amount2 = BtcUtils.toSatoshi('0.0011');
    final amount3 = BtcUtils.toSatoshi('0.0012');
    builder.addOutput(
        PsbtTransactionOutput(amount: amount2, address: recipient1()));
    builder.addOutput(
        PsbtTransactionOutput(amount: amount3, address: recipient2()));
    builder = signFinalize(
        builder: builder,
        index: 0,
        utxos: expandUtxos,
        sighash: BitcoinOpCodeConst.sighashNoneAnyOneCanPay);
    builder.addUtxo(psbtUtxos[1]);
    builder = signFinalize(
        builder: builder,
        index: 1,
        utxos: expandUtxos,
        sighash: BitcoinOpCodeConst.sighashNoneAnyOneCanPay);

    builder.addUtxo(psbtUtxos[2]);

    builder = signFinalize(
        builder: builder,
        index: 2,
        utxos: expandUtxos,
        sighash: BitcoinOpCodeConst.sighashAll);
    final tx = builder.finalizeAll();
    expect(tx.txId(),
        "f9a4f122347356516a40f49ab5b14d71ae4f88ec82b285dff5835f9ec9dc3e2b");
  });
}

void _expectInput(
    {required PsbtBuilder builder,
    required PsbtUtxo utxo,
    required int index}) {
  final txInputs = builder.txInputs();
  expect(txInputs[index].txId, utxo.utxo.txHash);
  expect(txInputs[index].txIndex, utxo.utxo.vout);
}
