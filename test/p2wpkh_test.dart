import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

void main() {
  group('P2WPKH', () {
    final sk = ECPrivate.fromWif(
        'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
        netVersion: BitcoinNetwork.testnet.wifNetVer);

    final p2pkhAddr = sk.getPublic().toAddress();

    final p2wpkhAddr = sk.getPublic().toSegwitAddress();

    final txin1 = TxInput(
        txId:
            '5a7b3aaa66d6b7b7abcdc9f1d05db4eee94a700297a319e19454e143875e1078',
        txIndex: 0);

    final txout1 = TxOutput(
        amount: BigInt.from(990000), scriptPubKey: p2wpkhAddr.toScriptPubKey());

    final txinSpend = TxInput(
        txId:
            'b3ca1c4cc778380d1e5376a5517445104e46e97176e40741508a3b07a6483ad3',
        txIndex: 0);
    final txinSpendAmount = BigInt.from(990000);
    final txout2 = TxOutput(
        amount: BigInt.from(980000), scriptPubKey: p2pkhAddr.toScriptPubKey());
    final p2pkhRedeemScript = Script(script: [
      BitcoinOpcode.opDup,
      BitcoinOpcode.opHash160,
      p2pkhAddr.addressProgram,
      BitcoinOpcode.opEqualVerify,
      BitcoinOpcode.opCheckSig,
    ]);

    final txinSpendP2pkh = TxInput(
        txId:
            '1e2a5279c868d61fb2ff0b1c2b04aa3eff02cd74952a8b4e799532635a9132cc',
        txIndex: 0);

    final txinSpendP2wpkh = TxInput(
        txId:
            'fff39047310fbf04bdd0e0bc75dde4267ae4d25219d8ad95e0ca1cee907a60da',
        txIndex: 0);
    final txinSpendP2wpkhAmount = BigInt.from(950000);

    final txout3 = TxOutput(
        amount: BigInt.from(1940000), scriptPubKey: p2pkhAddr.toScriptPubKey());

    final txin1Signone = TxInput(
        txId:
            'fb4c338a00a75d73f9a6bd203ed4bd8884edeb111fac25a7946d5df6562f1942',
        txIndex: 0);
    final txin1SignoneAmount = BigInt.from(1000000);

    final txout1Signone = TxOutput(
        amount: BigInt.from(800000), scriptPubKey: p2pkhAddr.toScriptPubKey());
    final txout2Signone = TxOutput(
        amount: BigInt.from(190000), scriptPubKey: p2pkhAddr.toScriptPubKey());

    final txin1Sigsingle = TxInput(
        txId:
            'b04909d4b5239a56d676c1d9d722f325a86878c9aa535915aa0df97df47cedeb',
        txIndex: 0);
    final txin1SigsingleAmount = BigInt.from(1930000);

    final txout1Sigsingle = TxOutput(
        amount: BigInt.from(1000000), scriptPubKey: p2pkhAddr.toScriptPubKey());
    final txout2Sigsingle = TxOutput(
        amount: BigInt.from(920000), scriptPubKey: p2pkhAddr.toScriptPubKey());

    final txin1SiganyonecanpayAll = TxInput(
        txId:
            'f67e97a2564dceed405e214843e3c954b47dd4f8b26ea48f82382f51f7626036',
        txIndex: 0);
    final txin1SiganyonecanpayAllAmount = BigInt.from(180000);

    final txin2SiganyonecanpayAll = TxInput(
        txId:
            'f4afddb77cd11a79bed059463085382c50d60c7f9e4075d8469cfe60040f68eb',
        txIndex: 0);
    final txin2SiganyonecanpayAllAmount = BigInt.from(180000);

    final txout1SiganyonecanpayAll = TxOutput(
        amount: BigInt.from(180000), scriptPubKey: p2pkhAddr.toScriptPubKey());
    final txout2SiganyonecanpayAll = TxOutput(
        amount: BigInt.from(170000), scriptPubKey: p2pkhAddr.toScriptPubKey());

    final txin1SiganyonecanpayNone = TxInput(
        txId:
            'd2ae5d4a3f390f108769139c9b5757846be6693b785c4e21eab777eec7289095',
        txIndex: 0);
    final txin1SiganyonecanpayNoneAmount = BigInt.from(900000);

    final txin2SiganyonecanpayNone = TxInput(
        txId:
            'ee5062d426677372e6de96e2eb47d572af5deaaef3ef225f3179dfa1ece3f4f5',
        txIndex: 0);
    final txin2SiganyonecanpayNoneAmount = BigInt.from(700000);

    final txout1SiganyonecanpayNone = TxOutput(
        amount: BigInt.from(800000), scriptPubKey: p2pkhAddr.toScriptPubKey());
    final txout2SiganyonecanpayNone = TxOutput(
        amount: BigInt.from(700000), scriptPubKey: p2pkhAddr.toScriptPubKey());

    final txin1SiganyonecanpaySingle = TxInput(
        txId:
            'c7bb5672266c8a5b64fe91e953a9e23e3206e3b1a2ddc8e5999b607b82485042',
        txIndex: 0);
    final txin1SiganyonecanpaySingleAmount = BigInt.from(1000000);

    final txout1SiganyonecanpaySingle = TxOutput(
        amount: BigInt.from(500000), scriptPubKey: p2pkhAddr.toScriptPubKey());
    final txout2SiganyonecanpaySingle = TxOutput(
        amount: BigInt.from(490000), scriptPubKey: p2pkhAddr.toScriptPubKey());

    const createSendToP2wpkhResult =
        '020000000178105e8743e15494e119a39702704ae9eeb45dd0f1c9cdabb7b7d666aa3a7b5a000000006a4730440220415155963673e5582aadfdb8d53874c9764cfd56c28be8d5f2838fdab6365f9902207bf28f875e15ff53e81f3245feb07c6120df4a653feabba3b7bf274790ea1fd1012102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546ffffffff01301b0f0000000000160014fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a00000000';
    const spendP2pkhResult =
        '02000000000101d33a48a6073b8a504107e47671e9464e10457451a576531e0d3878c74c1ccab30000000000ffffffff0120f40e00000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac0247304402201c7ec9b049daa99c78675810b5e36b0b61add3f84180eaeaa613f8525904bdc302204854830d463a4699b6d69e37c08b8d3c6158185d46499170cfcc24d4a9e9a37f012102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a54600000000';
    const p2pkhAndP2wpkhToP2pkhResult =
        '02000000000102cc32915a633295794e8b2a9574cd02ff3eaa042b1c0bffb21fd668c879522a1e000000006a47304402200fe842622e656a6780093f60b0597a36a57481611543a2e9576f9e8f1b34edb8022008ba063961c600834760037be20f45bbe077541c533b3fd257eae8e08d0de3b3012102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a546ffffffffda607a90ee1ccae095add81952d2e47a26e4dd75bce0d0bd04bf0f314790f3ff0000000000ffffffff01209a1d00000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac00024730440220274bb5445294033a36c360c48cc5e441ba8cc2bc1554dcb7d367088ec40a0d0302202a36f6e03f969e1b0c582f006257eec8fa2ada8cd34fe41ae2aa90d6728999d1012102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a54600000000';
    const testSignoneSendResult =
        '0200000000010142192f56f65d6d94a725ac1f11ebed8488bdd43e20bda6f9735da7008a334cfb0000000000ffffffff0200350c00000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac30e60200000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac0247304402202c47de56a42143ea94c15bdeee237104524a009e50d5359596f7c6f2208a280b022076d6be5dcab09f7645d1ee001c1af14f44420c0d0b16724d741d2a5c19816902022102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a54600000000';
    const testSigsingleSendResult =
        '02000000000101ebed7cf47df90daa155953aac97868a825f322d7d9c176d6569a23b5d40949b00000000000ffffffff0240420f00000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88acc0090e00000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac0247304402205189808e5cd0d49a8211202ea1afd7d01c180892ddf054508c349c2aa5630ee202202cbe5efa11fdde964603f4b9112d5e9ac452fba2e8ad5b6cddffbc8f0043b59e032102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a54600000000';
    const testSiganyonecanpayAllSendResult =
        '02000000000102366062f7512f38828fa46eb2f8d47db454c9e34348215e40edce4d56a2977ef60000000000ffffffffeb680f0460fe9c46d875409e7f0cd6502c3885304659d0be791ad17cb7ddaff40000000000ffffffff0220bf0200000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac10980200000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac024730440220046813b802c046c9cfa309e85d1f36b17f1eb1dfb3e8d3c4ae2f74915a3b1c1f02200c5631038bb8b6c7b5283892bb1279a40e7ac13d2392df0c7b36bde7444ec54c812102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a5460247304402206fb60dc79b5ca6c699d04ec96c4f196938332c2909fd17c04023ebcc7408f36e02202b071771a58c84e20b7bf1fcec05c0ef55c1100436a055bfcb2bf7ed1c0683a9012102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a54600000000';
    const testSiganyonecanpayNoneSendResult =
        '02000000000102959028c7ee77b7ea214e5c783b69e66b8457579b9c136987100f393f4a5daed20000000000fffffffff5f4e3eca1df79315f22eff3aeea5daf72d547ebe296dee672736726d46250ee0000000000ffffffff0200350c00000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac60ae0a00000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac0247304402203bbcbd2003244e9ccde7f705d3017f3baa2cb2d47efb63ede7e39704eff3987702206932aa4b402de898ff2fd3b2182f344dc9051b4c326dacc07b1e59059042f3ad822102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a54602473044022052dd29ab8bb0814b13633691148feceded29466ff8a1812d6d51c6fa53c55b5402205f25b3ae0da860da29a6745b0b587aa3fc3e05bef3121d3693ca2e3f4c2c3195012102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a54600000000';
    const testSiganyonecanpaySingleSendResult =
        '02000000000101425048827b609b99e5c8dda2b1e306323ee2a953e991fe645b8a6c267256bbc70000000000ffffffff0220a10700000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac107a0700000000001976a914fd337ad3bf81e086d96a68e1f8d6a0a510f8c24a88ac02473044022064b63a1da4181764a1e8246d353b72c420999c575807ec80329c64264fd5b19e022076ec4ba6c02eae7dc9340f8c76956d5efb7d0fbad03b1234297ebed8c38e43d8832102d82c9860e36f15d7b72aa59e29347f951277c21cd4d34822acdeeadbcff8a54600000000';
    test('test_signed_send_to_p2wpkh', () {
      final tx = BtcTransaction(inputs: [txin1], outputs: [txout1]);
      final digit = tx.getTransactionDigest(
          txInIndex: 0, script: p2pkhAddr.toScriptPubKey());
      final sig = sk.signECDSA(digit);
      txin1.scriptSig = Script(script: [sig, sk.getPublic().toHex()]);
      expect(tx.serialize(), createSendToP2wpkhResult);
    });
    test('test_spend_p2wpkh', () {
      var tx = BtcTransaction(inputs: [txinSpend], outputs: [txout2]);
      final digit = tx.getTransactionSegwitDigit(
          txInIndex: 0, script: p2pkhRedeemScript, amount: txinSpendAmount);
      final sig = sk.signECDSA(digit);
      tx = tx.copyWith(witnesses: [
        TxWitnessInput(stack: [sig, sk.getPublic().toHex()])
      ]);
      expect(tx.serialize(), spendP2pkhResult);
    });
    test('test_p2pkh_and_p2wpkh_to_p2pkh', () {
      var tx = BtcTransaction(
        inputs: [txinSpendP2pkh, txinSpendP2wpkh],
        outputs: [txout3],
      );
      final digit = tx.getTransactionDigest(
          txInIndex: 0, script: p2pkhAddr.toScriptPubKey());
      final sig = sk.signECDSA(digit);
      txinSpendP2pkh.scriptSig = Script(script: [sig, sk.getPublic().toHex()]);
      final segwitDigit = tx.getTransactionSegwitDigit(
          amount: txinSpendP2wpkhAmount,
          script: p2pkhRedeemScript,
          txInIndex: 1);
      final sig2 = sk.signECDSA(segwitDigit);
      tx = tx.copyWith(witnesses: [
        TxWitnessInput(stack: []),
        TxWitnessInput(stack: [sig2, sk.getPublic().toHex()])
      ]);
      expect(tx.serialize(), p2pkhAndP2wpkhToP2pkhResult);
    });
    test('test_signone_send', () {
      var tx = BtcTransaction(inputs: [txin1Signone], outputs: [txout1Signone]);
      final digit = tx.getTransactionSegwitDigit(
          txInIndex: 0,
          script: p2pkhRedeemScript,
          amount: txin1SignoneAmount,
          sighash: BitcoinOpCodeConst.sighashNone);
      final sig = sk.signECDSA(digit, sighash: BitcoinOpCodeConst.sighashNone);
      tx = tx.copyWith(witnesses: [
        TxWitnessInput(stack: [sig, sk.getPublic().toHex()])
      ]);
      tx = tx.copyWith(outputs: [...tx.outputs, txout2Signone]);

      expect(tx.serialize(), testSignoneSendResult);
    });
    test('test_sigsingle_send', () {
      var tx = BtcTransaction(
        inputs: [txin1Sigsingle],
        outputs: [txout1Sigsingle],
      );
      final digit = tx.getTransactionSegwitDigit(
          txInIndex: 0,
          script: p2pkhRedeemScript,
          amount: txin1SigsingleAmount,
          sighash: BitcoinOpCodeConst.sighashSingle);
      final sig =
          sk.signECDSA(digit, sighash: BitcoinOpCodeConst.sighashSingle);
      tx = tx.copyWith(witnesses: [
        TxWitnessInput(stack: [sig, sk.getPublic().toHex()])
      ]);
      tx = tx.copyWith(outputs: [...tx.outputs, txout2Sigsingle]);

      expect(tx.serialize(), testSigsingleSendResult);
    });
    test('test_siganyonecanpay_all_send', () {
      var tx = BtcTransaction(
        inputs: [txin1SiganyonecanpayAll],
        outputs: [txout1SiganyonecanpayAll, txout2SiganyonecanpayAll],
      );
      final digit = tx.getTransactionSegwitDigit(
          txInIndex: 0,
          script: p2pkhRedeemScript,
          amount: txin1SiganyonecanpayAllAmount,
          sighash: BitcoinOpCodeConst.sighashAll |
              BitcoinOpCodeConst.sighashAnyoneCanPay);
      final sig = sk.signECDSA(digit,
          sighash: BitcoinOpCodeConst.sighashAll |
              BitcoinOpCodeConst.sighashAnyoneCanPay);

      tx = tx.copyWith(inputs: [...tx.inputs, txin2SiganyonecanpayAll]);
      final digit2 = tx.getTransactionSegwitDigit(
          txInIndex: 1,
          script: p2pkhRedeemScript,
          amount: txin2SiganyonecanpayAllAmount,
          sighash: BitcoinOpCodeConst.sighashAll);
      final sig2 = sk.signECDSA(digit2, sighash: BitcoinOpCodeConst.sighashAll);
      tx = tx.copyWith(witnesses: [
        TxWitnessInput(stack: [sig, sk.getPublic().toHex()]),
        TxWitnessInput(stack: [sig2, sk.getPublic().toHex()])
      ]);

      expect(tx.serialize(), testSiganyonecanpayAllSendResult);
    });

    test('test_siganyonecanpay_none_send', () {
      var tx = BtcTransaction(
        inputs: [txin1SiganyonecanpayNone],
        outputs: [txout1SiganyonecanpayNone],
      );
      final digit = tx.getTransactionSegwitDigit(
          txInIndex: 0,
          script: p2pkhRedeemScript,
          amount: txin1SiganyonecanpayNoneAmount,
          sighash: BitcoinOpCodeConst.sighashNone |
              BitcoinOpCodeConst.sighashAnyoneCanPay);
      final sig = sk.signECDSA(digit,
          sighash: BitcoinOpCodeConst.sighashNone |
              BitcoinOpCodeConst.sighashAnyoneCanPay);
      tx = tx.copyWith(inputs: [...tx.inputs, txin2SiganyonecanpayNone]);
      tx = tx.copyWith(outputs: [...tx.outputs, txout2SiganyonecanpayNone]);
      final digit2 = tx.getTransactionSegwitDigit(
          txInIndex: 1,
          script: p2pkhRedeemScript,
          amount: txin2SiganyonecanpayNoneAmount,
          sighash: BitcoinOpCodeConst.sighashAll);
      final sig2 = sk.signECDSA(digit2, sighash: BitcoinOpCodeConst.sighashAll);
      tx = tx.copyWith(witnesses: [
        TxWitnessInput(stack: [sig, sk.getPublic().toHex()]),
        TxWitnessInput(stack: [sig2, sk.getPublic().toHex()])
      ]);
      expect(tx.serialize(), testSiganyonecanpayNoneSendResult);
      final deserialize = BtcTransaction.deserialize(tx.toBytes());
      expect(deserialize.serialize(), tx.serialize());
    });
    test('test_siganyonecanpay_single_send', () {
      var tx = BtcTransaction(
        inputs: [txin1SiganyonecanpaySingle],
        outputs: [txout1SiganyonecanpaySingle],
      );
      final digit = tx.getTransactionSegwitDigit(
          txInIndex: 0,
          script: p2pkhRedeemScript,
          amount: txin1SiganyonecanpaySingleAmount,
          sighash: BitcoinOpCodeConst.sighashSingle |
              BitcoinOpCodeConst.sighashAnyoneCanPay);
      final sig = sk.signECDSA(digit,
          sighash: BitcoinOpCodeConst.sighashSingle |
              BitcoinOpCodeConst.sighashAnyoneCanPay);
      tx = tx.copyWith(witnesses: [
        TxWitnessInput(stack: [sig, sk.getPublic().toHex()])
      ]);
      tx = tx.copyWith(outputs: [...tx.outputs, txout2SiganyonecanpaySingle]);
      expect(tx.serialize(), testSiganyonecanpaySingleSendResult);
      final deserialize = BtcTransaction.deserialize(tx.toBytes());
      expect(deserialize.serialize(), tx.serialize());
    });
  });
}
