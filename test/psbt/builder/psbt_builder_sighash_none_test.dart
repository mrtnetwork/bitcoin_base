import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'utxos_vector.dart';

void main() {
  test("PSBTV0", () {
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

  /// sign all inputs with SIGHASH_NONE
  builder.signAllInput(
    (p0) {
      final signers = (expandUtxos[p0.index]["privateKeys"] as List)
          .map((e) => ECPrivate.fromHex(e))
          .toList();
      return PsbtSignerResponse(
          signers: signers.map((e) => PsbtDefaultSigner(e)).toList(),
          sighash: BitcoinOpCodeConst.sighashNone,
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
          'error message', contains('Missing input non-witness UTXOs.'))));
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
  builder.addOutput(PsbtTransactionOutput(amount: amount2, address: r2));
  builder.addOutput(PsbtTransactionOutput(amount: amount3, address: r3));
  builder.addOutput(PsbtTransactionOutput(amount: change, address: r4));
  final outs = builder.txOutputs();
  expect(outs.length, 4);
  expect(outs[0].amount, amount1);
  expect(outs[0].scriptPubKey, r1.toScriptPubKey());
  expect(outs[1].amount, amount2);
  expect(outs[1].scriptPubKey, r2.toScriptPubKey());
  expect(outs[2].amount, amount3);
  expect(outs[2].scriptPubKey, r3.toScriptPubKey());
  expect(outs[3].amount, change);
  expect(outs[3].scriptPubKey, r4.toScriptPubKey());
  _partialSignSighashNone(builder.toBase64(), expandUtxos);
}

void _partialSignSighashNone(String psbt, List<Map<String, dynamic>> utxoes) {
  final key14 = PsbtDefaultSigner(ECPrivate.fromHex(
      "efd4d62709543c1bae8a22b44640856b48398b7d06f57958760a8695b9f5f171"));
  final builder = PsbtBuilder.fromBase64(psbt);
  builder.signInput(
      signer: (params) => PsbtSignerResponse(signers: [key14]), index: 14);
  final tx = builder.finalizeAll(
    onFinalizeInput: (params) {
      if (params.inputData.taprootLeafScript != null &&
          params.inputData.taprootLeafScript!.length > 1) {
        /// taproot script-path with multiple tapleaf script exists
        /// in this case should we pass correct tapleaf.
        return PsbtFinalizeResponse(
            tapleafHash: BytesUtils.tryFromHexString(
                utxoes[params.index]["select_leaf"]));
      }
      return null;
    },
  );

  expect(tx.txId(),
      "d95bf1d6a34dadcd458368f19c667f588b59b5c2217190433eb4c737575866c3");
}
