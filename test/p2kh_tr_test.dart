import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

void main() {
  group('P2KH', () {
    final txin = TxInput(
        txId:
            'fb48f4e23bf6ddf606714141ac78c3e921c8c0bebeb7c8abb2c799e9ff96ce6c',
        txIndex: 0);
    final addr = P2pkhAddress.fromAddress(
        address: 'n4bkvTyU1dVdzsrhWBqBw8fEMbHjJvtmJR',
        network: BitcoinNetwork.testnet);
    final txout = TxOutput(
        amount: BigInt.from(10000000),
        scriptPubKey: Script(script: [
          BitcoinOpcode.opDup,
          BitcoinOpcode.opHash160,
          addr.addressProgram,
          BitcoinOpcode.opEqualVerify,
          BitcoinOpcode.opCheckSig,
        ]));
    final changeAddr = P2pkhAddress.fromAddress(
        address: 'mytmhndz4UbEMeoSZorXXrLpPfeoFUDzEp',
        network: BitcoinNetwork.testnet);
    final changeTxout = TxOutput(
        amount: BigInt.from(29000000),
        scriptPubKey: changeAddr.toScriptPubKey());
    final changeLowSAddr = P2pkhAddress.fromAddress(
        address: 'mmYNBho9BWQB2dSniP1NJvnPoj5EVWw89w',
        network: BitcoinNetwork.testnet);
    final changeLowSTxout = TxOutput(
        amount: BigInt.from(29000000),
        scriptPubKey: changeLowSAddr.toScriptPubKey());
    final sk = ECPrivate.fromWif(
        'cRvyLwCPLU88jsyj94L7iJjQX5C2f8koG4G2gevN4BeSGcEvfKe9',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    final fromAddr = P2pkhAddress.fromAddress(
        address: 'myPAE9HwPeKHh8FjKwBNBaHnemApo3dw6e',
        network: BitcoinNetwork.testnet);

    const coreTxResult =
        '02000000016cce96ffe999c7b2abc8b7bebec0c821e9c378ac41417106f6ddf63be2f448fb0000000000ffffffff0280969800000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac4081ba01000000001976a914c992931350c9ba48538003706953831402ea34ea88ac00000000';
    const coreTxSignedResult =
        '02000000016cce96ffe999c7b2abc8b7bebec0c821e9c378ac41417106f6ddf63be2f448fb000000006a473044022079dad1afef077fa36dcd3488708dd05ef37888ef550b45eb00cdb04ba3fc980e02207a19f6261e69b604a92e2bffdf6ddbed0c64f55d5003e9dfb58b874b07aef3d7012103a2fef1829e0742b89c218c51898d9e7cb9d51201ba2bf9d9e9214ebb6af32708ffffffff0280969800000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac4081ba01000000001976a914c992931350c9ba48538003706953831402ea34ea88ac00000000';
    const coreTxSignedLowSSigallResult =
        '02000000016cce96ffe999c7b2abc8b7bebec0c821e9c378ac41417106f6ddf63be2f448fb000000006a473044022044ef433a24c6010a90af14f7739e7c60ce2c5bc3eab96eaee9fbccfdbb3e272202205372a617cb235d0a0ec2889dbfcadf15e10890500d184c8dda90794ecdf79492012103a2fef1829e0742b89c218c51898d9e7cb9d51201ba2bf9d9e9214ebb6af32708ffffffff0280969800000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac4081ba01000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000';
    const coreTxSignedLowSSignoneResult =
        '02000000016cce96ffe999c7b2abc8b7bebec0c821e9c378ac41417106f6ddf63be2f448fb000000006a47304402201e4b7a2ed516485fdde697ba63f6670d43aa6f18d82f18bae12d5fd228363ac10220670602bec9df95d7ec4a619a2f44e0b8dcf522fdbe39530dd78d738c0ed0c430022103a2fef1829e0742b89c218c51898d9e7cb9d51201ba2bf9d9e9214ebb6af32708ffffffff0280969800000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac4081ba01000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000';
    const coreTxSignedLowSSignoneTxid =
        '105933681b0ca37ae0c0af43ae6f111803c899232b7fd586584b532dbe21ae6f';

    final sigTxin1 = TxInput(
        txId:
            '76464c2b9e2af4d63ef38a77964b3b77e629dddefc5cb9eb1a3645b1608b790f',
        txIndex: 0);
    final sigTxin2 = TxInput(
        txId:
            '76464c2b9e2af4d63ef38a77964b3b77e629dddefc5cb9eb1a3645b1608b790f',
        txIndex: 1);
    final sigFromAddr1 = P2pkhAddress.fromAddress(
        address: 'n4bkvTyU1dVdzsrhWBqBw8fEMbHjJvtmJR',
        network: BitcoinNetwork.testnet);
    final sigFromAddr2 = P2pkhAddress.fromAddress(
        address: 'mmYNBho9BWQB2dSniP1NJvnPoj5EVWw89w',
        network: BitcoinNetwork.testnet);
    final sigSk1 = ECPrivate.fromWif(
        'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    final sigSk2 = ECPrivate.fromWif(
        'cVf3kGh6552jU2rLaKwXTKq5APHPoZqCP4GQzQirWGHFoHQ9rEVt',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    final sigToAddr1 = P2pkhAddress.fromAddress(
        address: 'myPAE9HwPeKHh8FjKwBNBaHnemApo3dw6e',
        network: BitcoinNetwork.testnet);
    final sigTxout1 = TxOutput(
        amount: BigInt.from(9000000),
        scriptPubKey: Script(script: [
          BitcoinOpcode.opDup,
          BitcoinOpcode.opHash160,
          sigToAddr1.addressProgram,
          BitcoinOpcode.opEqualVerify,
          BitcoinOpcode.opCheckSig,
        ]));
    final sigToAddr2 = P2pkhAddress.fromAddress(
        address: 'mmYNBho9BWQB2dSniP1NJvnPoj5EVWw89w',
        network: BitcoinNetwork.testnet);
    final sigTxout2 = TxOutput(
        amount: BigInt.from(900000),
        scriptPubKey: Script(script: [
          BitcoinOpcode.opDup,
          BitcoinOpcode.opHash160,
          sigToAddr2.addressProgram,
          BitcoinOpcode.opEqualVerify,
          BitcoinOpcode.opCheckSig,
        ]));
    const sigSighashSingleResult =
        '02000000010f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676000000006a47304402202cfd7077fe8adfc5a65fb3953fa3482cad1413c28b53f12941c1082898d4935102201d393772c47f0699592268febb5b4f64dabe260f440d5d0f96dae5bc2b53e11e032102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546ffffffff0240548900000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988aca0bb0d00000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000';
    const signSighashAll2in2outResult =
        '02000000020f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676000000006a4730440220355c3cf50b1d320d4ddfbe1b407ddbe508f8e31a38cc5531dec3534e8cb2e565022037d4e8d7ba9dd1c788c0d8b5b99270d4c1d4087cdee7f139a71fea23dceeca33012102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546ffffffff0f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676010000006a47304402206b728374b8879fd7a10cbd4f347934d583f4301aa5d592211487732c235b85b6022030acdc07761f227c27010bd022df4b22eb9875c65a59e8e8a5722229bc7362f4012102364d6f04487a71b5966eae3e14a4dc6f00dbe8e55e61bedd0b880766bfe72b5dffffffff0240548900000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988aca0bb0d00000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000';
    const signSighashNone2in2outResult =
        '02000000020f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676000000006a47304402202a2804048b7f84f2dd7641ec05bbaf3da9ae0d2a9f9ad476d376adfd8bf5033302205170fee2ab7b955d72ae2beac3bae15679d75584c37d78d82b07df5402605bab022102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546ffffffff0f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676010000006a473044022021a82914b002bd02090fbdb37e2e739e9ba97367e74db5e1de834bbab9431a2f02203a11f49a3f6ac03b1550ee04f9d84deee2045bc038cb8c3e70869470126a064d022102364d6f04487a71b5966eae3e14a4dc6f00dbe8e55e61bedd0b880766bfe72b5dffffffff0240548900000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988aca0bb0d00000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000';

    const signSighashAllSingleAnyone2in2outResult =
        '02000000020f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676000000006a47304402205360315c439214dd1da10ea00a7531c0a211a865387531c358e586000bfb41b3022064a729e666b4d8ac7a09cb7205c8914c2eb634080597277baf946903d5438f49812102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546ffffffff0f798b60b145361aebb95cfcdedd29e6773b4b96778af33ed6f42a9e2b4c4676010000006a473044022067943abe9fa7584ba9816fc9bf002b043f7f97e11de59155d66e0411a679ba2c02200a13462236fa520b80b4ed85c7ded363b4c9264eb7b2d9746200be48f2b6f4cb832102364d6f04487a71b5966eae3e14a4dc6f00dbe8e55e61bedd0b880766bfe72b5dffffffff0240548900000000001976a914c3f8e5b0f8455a2b02c29c4488a550278209b66988aca0bb0d00000000001976a91442151d0c21442c2b038af0ad5ee64b9d6f4f4e4988ac00000000';

    test('test1', () {
      final tx = BtcTransaction(inputs: [txin], outputs: [txout, changeTxout]);
      expect(tx.serialize(), coreTxResult);
    });
    test('test2', () {
      final tx = BtcTransaction(inputs: [txin], outputs: [txout, changeTxout]);
      final digit = tx.getTransactionDigest(
          txInIndex: 0,
          script: Script(script: [
            BitcoinOpcode.opDup,
            BitcoinOpcode.opHash160,
            fromAddr.addressProgram,
            BitcoinOpcode.opEqualVerify,
            BitcoinOpcode.opCheckSig,
          ]));
      final sig = sk.signInput(digit);
      txin.scriptSig = Script(script: [sig, sk.getPublic().toHex()]);
      expect(tx.serialize(), coreTxSignedResult);
    });
    test('test3', () {
      final tx =
          BtcTransaction(inputs: [txin], outputs: [txout, changeLowSTxout]);
      final digit = tx.getTransactionDigest(
          txInIndex: 0, script: fromAddr.toScriptPubKey());
      final sig = sk.signInput(digit);
      txin.scriptSig = Script(script: [sig, sk.getPublic().toHex()]);
      expect(tx.serialize(), coreTxSignedLowSSigallResult);
    });
    test('test4', () {
      final tx =
          BtcTransaction(inputs: [txin], outputs: [txout, changeLowSTxout]);
      final digit = tx.getTransactionDigest(
          txInIndex: 0,
          script: fromAddr.toScriptPubKey(),
          sighash: BitcoinOpCodeConst.sighashNone);
      final sig = sk.signInput(digit, sigHash: BitcoinOpCodeConst.sighashNone);
      txin.scriptSig = Script(script: [sig, sk.getPublic().toHex()]);
      expect(tx.serialize(), coreTxSignedLowSSignoneResult);
      expect(tx.txId(), coreTxSignedLowSSignoneTxid);
    });
    test('test5', () {
      final tx =
          BtcTransaction(inputs: [sigTxin1], outputs: [sigTxout1, sigTxout2]);
      final digit = tx.getTransactionDigest(
          txInIndex: 0,
          script: sigFromAddr1.toScriptPubKey(),
          sighash: BitcoinOpCodeConst.sighashSingle);
      final sig =
          sigSk1.signInput(digit, sigHash: BitcoinOpCodeConst.sighashSingle);
      sigTxin1.scriptSig = Script(script: [sig, sigSk1.getPublic().toHex()]);
      expect(tx.serialize(), sigSighashSingleResult);
    });
    test('test6', () {
      final tx = BtcTransaction(
          inputs: [sigTxin1, sigTxin2], outputs: [sigTxout1, sigTxout2]);
      final digit = tx.getTransactionDigest(
          txInIndex: 0,
          script: sigFromAddr1.toScriptPubKey(),
          sighash: BitcoinOpCodeConst.sighashAll);
      final sig =
          sigSk1.signInput(digit, sigHash: BitcoinOpCodeConst.sighashAll);
      final digit2 = tx.getTransactionDigest(
          txInIndex: 1,
          script: sigFromAddr2.toScriptPubKey(),
          sighash: BitcoinOpCodeConst.sighashAll);
      final sig2 =
          sigSk2.signInput(digit2, sigHash: BitcoinOpCodeConst.sighashAll);
      sigTxin1.scriptSig = Script(script: [sig, sigSk1.getPublic().toHex()]);
      sigTxin2.scriptSig = Script(script: [sig2, sigSk2.getPublic().toHex()]);
      expect(tx.serialize(), signSighashAll2in2outResult);
    });
    test('test7', () {
      final tx = BtcTransaction(
          inputs: [sigTxin1, sigTxin2], outputs: [sigTxout1, sigTxout2]);
      final digit = tx.getTransactionDigest(
          txInIndex: 0,
          script: sigFromAddr1.toScriptPubKey(),
          sighash: BitcoinOpCodeConst.sighashNone);
      final sig =
          sigSk1.signInput(digit, sigHash: BitcoinOpCodeConst.sighashNone);
      final digit2 = tx.getTransactionDigest(
          txInIndex: 1,
          script: sigFromAddr2.toScriptPubKey(),
          sighash: BitcoinOpCodeConst.sighashNone);
      final sig2 =
          sigSk2.signInput(digit2, sigHash: BitcoinOpCodeConst.sighashNone);
      sigTxin1.scriptSig = Script(script: [sig, sigSk1.getPublic().toHex()]);
      sigTxin2.scriptSig = Script(script: [sig2, sigSk2.getPublic().toHex()]);
      expect(tx.serialize(), signSighashNone2in2outResult);
    });
    test('test8', () {
      final tx = BtcTransaction(
          inputs: [sigTxin1, sigTxin2], outputs: [sigTxout1, sigTxout2]);
      final digit = tx.getTransactionDigest(
          txInIndex: 0,
          script: sigFromAddr1.toScriptPubKey(),
          sighash: BitcoinOpCodeConst.sighashAll |
              BitcoinOpCodeConst.sighashAnyoneCanPay);

      final sig = sigSk1.signInput(digit,
          sigHash: BitcoinOpCodeConst.sighashAll |
              BitcoinOpCodeConst.sighashAnyoneCanPay);

      final digit2 = tx.getTransactionDigest(
          txInIndex: 1,
          script: sigFromAddr2.toScriptPubKey(),
          sighash: BitcoinOpCodeConst.sighashSingle |
              BitcoinOpCodeConst.sighashAnyoneCanPay);
      final sig2 = sigSk2.signInput(digit2,
          sigHash: BitcoinOpCodeConst.sighashSingle |
              BitcoinOpCodeConst.sighashAnyoneCanPay);
      sigTxin1.scriptSig = Script(script: [sig, sigSk1.getPublic().toHex()]);
      sigTxin2.scriptSig = Script(script: [sig2, sigSk2.getPublic().toHex()]);
      expect(tx.serialize(), signSighashAllSingleAnyone2in2outResult);
    });
  });
}
