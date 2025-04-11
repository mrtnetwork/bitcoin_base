import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

void main() {
  group('P2Sh', () {
    final fromAddr = P2pkhAddress.fromAddress(
        address: 'n4bkvTyU1dVdzsrhWBqBw8fEMbHjJvtmJR',
        network: BitcoinNetwork.testnet);
    final sk = ECPrivate.fromWif(
        'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    final p2pkSk = ECPrivate.fromWif(
        'cRvyLwCPLU88jsyj94L7iJjQX5C2f8koG4G2gevN4BeSGcEvfKe9',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    final p2pkRedeemScript = Script(script: [
      p2pkSk.getPublic().toHex(),
      BitcoinOpcode.opCheckSig,
    ]);
    final txout = TxOutput(
        amount: BigInt.from(9000000),
        scriptPubKey: P2shAddress.fromScript(
                script: p2pkRedeemScript, type: P2shAddressType.p2pkInP2sh)
            .toScriptPubKey());
    const createP2shAndSendResult =
        '02000000010f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676000000006a47304402206f4027d0a1720ea4cc68e1aa3cc2e0ca5996806971c0cd7d40d3aa4309d4761802206c5d9c0c26dec8edab91c1c3d64e46e4dd80d8da1787a9965ade2299b41c3803012102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546ffffffff01405489000000000017a9142910fc0b1b7ab6c9789c5a67c22c5bcde5b903908700000000';

    final txinSpend = TxInput(
        txId:
            '7db363d5a7fabb64ccce154e906588f1936f34481223ea8c1f2c935b0a0c945b',
        txIndex: 0);

    final toAddr = fromAddr;
    final txout2 = TxOutput(
        amount: BigInt.from(8000000), scriptPubKey: toAddr.toScriptPubKey());
    const spendP2shResult =
        '02000000015b940c0a5b932c1f8cea231248346f93f18865904e15cecc64bbfaa7d563b37d000000006c47304402204984c2089bf55d5e24851520ea43c431b0d79f90d464359899f27fb40a11fbd302201cc2099bfdc18c3a412afb2ef1625abad8a2c6b6ae0bf35887b787269a6f2d4d01232103a2fef1829e0742b89c218c51898d9e7cb9d51201ba2bf9d9e9214ebb6af32708acffffffff0100127a00000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac00000000';

    final skCsvP2pkh = ECPrivate.fromWif(
        'cRvyLwCPLU88jsyj94L7iJjQX5C2f8koG4G2gevN4BeSGcEvfKe9',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    final seq =
        Sequence(seqType: BitcoinOpCodeConst.typeRelativeTimelock, value: 200);
    final txinSeq = TxInput(
        txId:
            'f557c623e55f0affc696b742630770df2342c4aac395e0ed470923247bc51b95',
        txIndex: 0,
        sequance: seq.forInputSequence());
    final anotherAddr = P2pkhAddress.fromAddress(
        address: 'n4bkvTyU1dVdzsrhWBqBw8fEMbHjJvtmJR',
        network: BitcoinNetwork.testnet);
    const spendP2shCsvP2pkhResult =
        '0200000001951bc57b24230947ede095c3aac44223df70076342b796c6ff0a5fe523c657f5000000008947304402205c2e23d8ad7825cf44b998045cb19b49cf6447cbc1cb76a254cda43f7939982002202d8f88ab6afd2e8e1d03f70e5edc2a277c713018225d5b18889c5ad8fd6677b4012103a2fef1829e0742b89c218c51898d9e7cb9d51201ba2bf9d9e9214ebb6af327081e02c800b27576a914c3f8e5b0f8455a2b02c29c4488a550278209b66988acc80000000100ab9041000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac00000000';

    test('test1', () {
      final txin = TxInput(
          txId:
              '76464c2b9e2af4d63ef38a77964b3b77e629dddefc5cb9eb1a3645b1608b790f',
          txIndex: 0);
      final tx = BtcTransaction(inputs: [txin], outputs: [txout]);
      final digit = tx.getTransactionDigest(
          txInIndex: 0, script: fromAddr.toScriptPubKey());
      final sig = sk.signECDSA(digit);
      txin.scriptSig = Script(script: [sig, sk.getPublic().toHex()]);
      expect(tx.serialize(), createP2shAndSendResult);
    });

    test('test2', () {
      final tx = BtcTransaction(inputs: [txinSpend], outputs: [txout2]);
      final digit =
          tx.getTransactionDigest(txInIndex: 0, script: p2pkRedeemScript);
      final sig = p2pkSk.signECDSA(digit);
      txinSpend.scriptSig = Script(script: [sig, p2pkRedeemScript.toHex()]);
      expect(tx.serialize(), spendP2shResult);
    });
    test('test3', () {
      final redeemScript = Script(script: [
        seq.forScript(),
        BitcoinOpcode.opCheckSequenceVerify,
        BitcoinOpcode.opDrop,
        BitcoinOpcode.opDup,
        BitcoinOpcode.opHash160,
        skCsvP2pkh.getPublic().toHash160Hex(),
        BitcoinOpcode.opEqualVerify,
        BitcoinOpcode.opCheckSig,
      ]);

      final txout1 = TxOutput(
          amount: BigInt.from(1100000000),
          scriptPubKey: anotherAddr.toScriptPubKey());
      final tx = BtcTransaction(inputs: [txinSeq], outputs: [txout1]);

      final digit = tx.getTransactionDigest(txInIndex: 0, script: redeemScript);
      final sig = skCsvP2pkh.signECDSA(digit);

      txinSeq.scriptSig = Script(
          script: [sig, skCsvP2pkh.getPublic().toHex(), redeemScript.toHex()]);
      expect(tx.serialize(), spendP2shCsvP2pkhResult);
    });
  });
}
