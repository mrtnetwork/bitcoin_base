import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

void main() {
  test('test1', () {
    final tx = BtcTransaction(inputs: [
      TxInput(
        txId:
            'daaa0beab7411cee74768b3f1d7da7ad55fcbc9d835fda0afbe1b9a41ae42f75',
        txIndex: 0,
        scriptSig: Script(
          script: [
            '304402203795e2aa978afbbd676b36c0edd1a39478744d320c5e02dd6a39d154755a5a3e02205545a7765bae3db9b820b1db9be2f8955a8998fa92ac08b0d7416aa30a3cee4241',
            '03ac064f4489ff812c643471ed25b990e6be7212566c932b8680b900c8e6db0fd9'
          ],
        ),
      ),
      TxInput(
          txId:
              'daaa0beab7411cee74768b3f1d7da7ad55fcbc9d835fda0afbe1b9a41ae42f75',
          txIndex: 2,
          scriptSig: Script(script: [
            '3044022071b39d6aefdea7a7837310e5d78b1069ae82ed007991f8bca80bf3baf26340cc02200bc356be6e9f0019849b75b00322262a23ce179e7c0313207addfdbe596dabfd41',
            '03ac064f4489ff812c643471ed25b990e6be7212566c932b8680b900c8e6db0fd9'
          ]))
    ], outputs: [
      TxOutput(
          amount: BigInt.from(10067000),
          scriptPubKey: Script(
            script: [
              'OP_DUP',
              'OP_HASH160',
              'b8d913342894ec7b066420952a618ec2a8269bc2',
              'OP_EQUALVERIFY',
              'OP_CHECKSIG'
            ],
          )),
      TxOutput(
          amount: BigInt.from(1000),
          cashToken: CashToken(
            category:
                '4e7873d4529edfd2c6459139257042950230baa9297f111b8675829443f70430',
            bitfield: 16,
            amount: BigInt.from(2000),
          ),
          scriptPubKey: Script(
            script: [
              'OP_HASH256',
              '1d12ffe8e85fdab36794cb09418982efdbd5c8cee5fbeb216ac43887ea4817b8',
              'OP_EQUAL'
            ],
          )),
      TxOutput(
          amount: BigInt.from(1000),
          cashToken: CashToken(
            category:
                '4e7873d4529edfd2c6459139257042950230baa9297f111b8675829443f70430',
            bitfield: 16,
            amount: BigInt.parse('799999999999996000'),
          ),
          scriptPubKey: Script(
            script: [
              'OP_DUP',
              'OP_HASH160',
              'b8d913342894ec7b066420952a618ec2a8269bc2',
              'OP_EQUALVERIFY',
              'OP_CHECKSIG'
            ],
          )),
    ]);
    const raw =
        '0200000002752fe41aa4b9e1fb0ada5f839dbcfc55ada77d1d3f8b7674ee1c41b7ea0baada000000006a47304402203795e2aa978afbbd676b36c0edd1a39478744d320c5e02dd6a39d154755a5a3e02205545a7765bae3db9b820b1db9be2f8955a8998fa92ac08b0d7416aa30a3cee42412103ac064f4489ff812c643471ed25b990e6be7212566c932b8680b900c8e6db0fd9ffffffff752fe41aa4b9e1fb0ada5f839dbcfc55ada77d1d3f8b7674ee1c41b7ea0baada020000006a473044022071b39d6aefdea7a7837310e5d78b1069ae82ed007991f8bca80bf3baf26340cc02200bc356be6e9f0019849b75b00322262a23ce179e7c0313207addfdbe596dabfd412103ac064f4489ff812c643471ed25b990e6be7212566c932b8680b900c8e6db0fd9ffffffff03389c9900000000001976a914b8d913342894ec7b066420952a618ec2a8269bc288ace80300000000000048ef3004f743948275861b117f29a9ba300295427025399145c6d2df9e52d473784e10fdd007aa201d12ffe8e85fdab36794cb09418982efdbd5c8cee5fbeb216ac43887ea4817b887e80300000000000044ef3004f743948275861b117f29a9ba300295427025399145c6d2df9e52d473784e10ff60f04fecc22b1a0b76a914b8d913342894ec7b066420952a618ec2a8269bc288ac00000000';
    final tr = BtcTransaction.fromRaw(raw);
    expect(tx.toHex(), raw);
    expect(tr.toHex(), raw);

    /// https://chipnet.imaginary.cash/tx/4ab0ce5507e228ca07a0fc5a75b91714e9855f4e859435dd26a09366ce31e575
  });

  test('test 2', () {
    /// https://tbch4.loping.net/tx/caa91b0fea2843a99c3cd7375ac4d3102b6b74a25e52cd866ad7ecc486204f0d
    const encodedTr =
        '020000000252b6818f78bff46cbfdf3384875d3471f063f7c49f62658ffa22973c87649b5e000000006c473044022029198caf8776bcf9a8c3fcc79dbd4d3498cd938ba95962e5473fb77ad8d8a6510220265e7a0a14dca7bc1edb0a7bda4cd987f7893377b9cd9cfc9dbef97f85660bed41232103ac064f4489ff812c643471ed25b990e6be7212566c932b8680b900c8e6db0fd9acffffffff52b6818f78bff46cbfdf3384875d3471f063f7c49f62658ffa22973c87649b5e010000006c4730440220639b44bece1b3c2ed597c25497ee6f843ec2de033cb83292e0576b3f84cfc995022032713a60006d76c15bd0a6ddef758c06d61baa5f278bc993d98f03f69165d74741232103ac064f4489ff812c643471ed25b990e6be7212566c932b8680b900c8e6db0fd9acffffffff0510f699000000000023aa209f4ab972963cf18d86aa57fa875147f996916f06c28179f449cd14188818ba3187e80300000000000060efc4bf086c2c7bbb0405343873cf81b8b5d81d65126ce1bcddaa96591e79870d3f72156769746875622e636f6d2f6d72746e6574776f726bfe005a6202aa209f4ab972963cf18d86aa57fa875147f996916f06c28179f449cd14188818ba3187e80300000000000060efc4bf086c2c7bbb0405343873cf81b8b5d81d65126ce1bcddaa96591e79870d3f71156769746875622e636f6d2f6d72746e6574776f726bfe005a6202aa209f4ab972963cf18d86aa57fa875147f996916f06c28179f449cd14188818ba3187e80300000000000060efc4bf086c2c7bbb0405343873cf81b8b5d81d65126ce1bcddaa96591e79870d3f71156769746875622e636f6d2f6d72746e6574776f726bfe005a6202aa209f4ab972963cf18d86aa57fa875147f996916f06c28179f449cd14188818ba3187e80300000000000060efc4bf086c2c7bbb0405343873cf81b8b5d81d65126ce1bcddaa96591e79870d3f71156769746875622e636f6d2f6d72746e6574776f726bfe005a6202aa209f4ab972963cf18d86aa57fa875147f996916f06c28179f449cd14188818ba318700000000';
    final decode = BtcTransaction.fromRaw(encodedTr);
    expect(decode.toHex(), encodedTr);
  });
}
