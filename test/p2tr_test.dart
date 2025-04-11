import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

Map<Script, int> findAllLeafIndexes(List<dynamic> treeScripts) {
  int index = 0; // Tracks current leaf index
  Map<Script, int> leafIndexes = {}; // Stores script -> index mapping

  void traverse(dynamic level) {
    if (level is List) {
      if (level.length == 1) {
        traverse(level[0]); // Flatten single-element lists
      } else if (level.length == 2) {
        traverse(level[0]); // Left branch
        traverse(level[1]); // Right branch
      } else {
        throw DartBitcoinPluginException(
            "Invalid Merkle branch: A list must have at most 2 branches.");
      }
    } else if (level is Script) {
      leafIndexes[level] = index; // Store script with its leaf index
      index++; // Move to next index
    }
  }

  traverse(treeScripts);
  return leafIndexes;
}

void main() {
  group('TestCreateP2trWithSingleTapScript', () {
    late ECPrivate toPriv1;
    late ECPublic toPub1;
    late ECPrivate toPriv2;
    late ECPublic toPub2;
    late ECPrivate privkeyTrScript1;
    late ECPublic pubkeyTrScript1;
    late Script trScriptP2pk1;
    late String toTaprootScriptAddress1;
    late P2trAddress toAddress2;
    late ECPrivate fromPriv2;
    late ECPublic fromPub2;
    late P2trAddress fromAddress2;
    late TxInput txIn2;
    late TxOutput txOut2;
    late Script scriptPubKey2;
    late String signedTx2;
    late String signedTx3;

    setUp(() {
      toPriv1 = ECPrivate.fromWif(
          'cT33CWKwcV8afBs5NYzeSzeSoGETtAB8izjDjMEuGqyqPoF7fbQR',
          netVersion: BitcoinNetwork.testnet.wifNetVer);
      toPub1 = toPriv1.getPublic();
      toPriv2 = ECPrivate.fromWif(
          'cNxX8M7XU8VNa5ofd8yk1eiZxaxNrQQyb7xNpwAmsrzEhcVwtCjs',
          netVersion: BitcoinNetwork.testnet.wifNetVer);
      toPub2 = toPriv2.getPublic();
      toAddress2 = toPub2.toTaprootAddress();
      privkeyTrScript1 = ECPrivate.fromWif(
          'cSW2kQbqC9zkqagw8oTYKFTozKuZ214zd6CMTDs4V32cMfH3dgKa',
          netVersion: BitcoinNetwork.testnet.wifNetVer);
      pubkeyTrScript1 = privkeyTrScript1.getPublic();
      trScriptP2pk1 = Script(script: [
        pubkeyTrScript1.toXOnlyHex(),
        BitcoinOpcode.opCheckSig,
      ]);
      toTaprootScriptAddress1 =
          'tb1p0fcjs5l5xqdyvde5u7ut7sr0gzaxp4yya8mv06d2ygkeu82l65xs6k4uqr';
      fromPriv2 = ECPrivate.fromWif(
          'cT33CWKwcV8afBs5NYzeSzeSoGETtAB8izjDjMEuGqyqPoF7fbQR',
          netVersion: BitcoinNetwork.testnet.wifNetVer);
      fromPub2 = fromPriv2.getPublic();
      fromAddress2 = fromPub2.toTaprootAddress(
          treeScript: TaprootLeaf(script: trScriptP2pk1));
      txIn2 = TxInput(
          txId:
              '3d4c9d73c4c65772e645ff26493590ae4913d9c37125b72398222a553b73fa66',
          txIndex: 0);
      txOut2 = TxOutput(
          amount: BigInt.from(3000), scriptPubKey: toAddress2.toScriptPubKey());
      scriptPubKey2 = fromAddress2.toScriptPubKey();
      signedTx2 =
          '0200000000010166fa733b552a229823b72571c3d91349ae90354926ff45e67257c6c4739d4c3d0000000000ffffffff01b80b000000000000225120d4213cd57207f22a9e905302007b99b84491534729bd5f4065bdcb42ed10fcd50140f1776ddef90a87b646a45ad4821b8dd33e01c5036cbe071a2e1e609ae0c0963685cb8749001944dbe686662dd7c95178c85c4f59c685b646ab27e34df766b7b100000000';
      signedTx3 =
          '0200000000010166fa733b552a229823b72571c3d91349ae90354926ff45e67257c6c4739d4c3d0000000000ffffffff01b80b000000000000225120d4213cd57207f22a9e905302007b99b84491534729bd5f4065bdcb42ed10fcd50340bf0a391574b56651923abdb256731059008a08b5a3406cd81ce10ef5e7f936c6b9f7915ec1054e2a480e4552fa177aed868dc8b28c6263476871b21584690ef8222013f523102815e9fbbe132ffb8329b0fef5a9e4836d216dce1824633287b0abc6ac21c01036a7ed8d24eac9057e114f22342ebf20c16d37f0d25cfd2c900bf401ec09c900000000';
      // Initialize your variables here if needed
    });

    // 1-create address with single script spending path
    test('address_with_script_path', () {
      final toAddress = toPub1.toTaprootAddress(
          treeScript: TaprootLeaf(script: trScriptP2pk1));

      expect(
          toAddress.toAddress(BitcoinNetwork.testnet), toTaprootScriptAddress1);
    });

    // 2-spend taproot from key path (has single tapleaf script for spending)
    test('spend_key_path2', () {
      var tx = BtcTransaction(
        inputs: [txIn2],
        outputs: [txOut2],
      );

      const signHash = BitcoinOpCodeConst.sighashDefault;
      final txDigit = tx.getTransactionTaprootDigset(
          txIndex: 0,
          scriptPubKeys: [scriptPubKey2],
          amounts: [BigInt.from(3500)],
          sighash: signHash);
      final signatur = fromPriv2.signBip340(txDigit,
          treeScript: TaprootLeaf(script: trScriptP2pk1), sighash: signHash);
      tx = tx.copyWith(witnesses: [
        TxWitnessInput(stack: [signatur])
      ]);
      expect(tx.serialize(), signedTx2);
      final decode = BtcTransaction.deserialize(tx.toBytes());
      expect(decode.serialize(), tx.serialize());
    });

    // // 3-spend taproot from script path (has single tapleaf script for spending)
    test('spend_script_path2', () {
      var tx = BtcTransaction(
        outputs: [txOut2],
        inputs: [txIn2],
      );
      final digit = tx.getTransactionTaprootDigset(
        amounts: [BigInt.from(3500)],
        scriptPubKeys: [scriptPubKey2],
        txIndex: 0,
        tapleafScript: TaprootLeaf(script: trScriptP2pk1),
      );
      final sig = privkeyTrScript1.signBip340(digit,
          sighash: BitcoinOpCodeConst.sighashDefault, tweak: false);
      final controlBlock = TaprootControlBlock.generate(
          xOnlyOrInternalPubKey: fromPub2.toXOnly(),
          scriptTree: TaprootLeaf(script: trScriptP2pk1),
          leafScript: TaprootLeaf(script: trScriptP2pk1));

      tx = tx.copyWith(witnesses: [
        TxWitnessInput(
            stack: [sig, trScriptP2pk1.toHex(), controlBlock.toHex()])
      ]);
      expect(tx.serialize(), signedTx3);
    });
  });

  group('TestCreateP2trWithTwoTapScripts', () {
    late final privkeyTrScriptA = ECPrivate.fromWif(
        'cSW2kQbqC9zkqagw8oTYKFTozKuZ214zd6CMTDs4V32cMfH3dgKa',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    late final pubkeyTrScriptA = privkeyTrScriptA.getPublic();
    late final trScriptP2pkA = Script(script: [
      pubkeyTrScriptA.toXOnlyHex(),
      BitcoinOpcode.opCheckSig,
    ]);

    late final privkeyTrScriptB = ECPrivate.fromWif(
        'cSv48xapaqy7fPs8VvoSnxNBNA2jpjcuURRqUENu3WVq6Eh4U3JU',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    late final pubkeyTrScriptB = privkeyTrScriptB.getPublic();

    late final trScriptP2pkB = Script(script: [
      pubkeyTrScriptB.toXOnlyHex(),
      BitcoinOpcode.opCheckSig,
    ]);

    late final fromPriv = ECPrivate.fromWif(
        'cT33CWKwcV8afBs5NYzeSzeSoGETtAB8izjDjMEuGqyqPoF7fbQR',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    late final fromPub = fromPriv.getPublic();
    late final fromAddress = fromPub.toTaprootAddress(
      treeScript: TaprootBranch(
          a: TaprootLeaf(script: trScriptP2pkA),
          b: TaprootLeaf(script: trScriptP2pkB)),
    );

    late final txIn = TxInput(
        txId:
            '808ec85db7b005f1292cea744b24e9d72ba4695e065e2d968ca17744b5c5c14d',
        txIndex: 0);

    late final toPriv = ECPrivate.fromWif(
        'cNxX8M7XU8VNa5ofd8yk1eiZxaxNrQQyb7xNpwAmsrzEhcVwtCjs',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    late final toPub = toPriv.getPublic();
    late final toAddress = toPub.toTaprootAddress();
    late final txOut = TxOutput(
        amount: BigInt.from(3000), scriptPubKey: toAddress.toScriptPubKey());

    late final scriptPubkey = fromAddress.toScriptPubKey();
    late final allUtxosScriptpubkeys = [scriptPubkey];
    const signedTx3 =
        '020000000001014dc1c5b54477a18c962d5e065e69a42bd7e9244b74ea2c29f105b0b75dc88e800000000000ffffffff01b80b000000000000225120d4213cd57207f22a9e905302007b99b84491534729bd5f4065bdcb42ed10fcd50340ab89d20fee5557e57b7cf85840721ef28d68e91fd162b2d520e553b71d604388ea7c4b2fcc4d946d5d3be3c12ef2d129ffb92594bc1f42cdaec8280d0c83ecc2222013f523102815e9fbbe132ffb8329b0fef5a9e4836d216dce1824633287b0abc6ac41c01036a7ed8d24eac9057e114f22342ebf20c16d37f0d25cfd2c900bf401ec09c9682f0e85d59cb20fd0e4503c035d609f127c786136f276d475e8321ec9e77e6c00000000';

    // 1-spend taproot from first script path (A) of two (A,B)
    test('test_spend_script_path_A_from_AB', () {
      var tx = BtcTransaction(
        inputs: [txIn],
        outputs: [txOut],
      );

      final txDigit = tx.getTransactionTaprootDigset(
        amounts: [BigInt.from(3500)],
        scriptPubKeys: allUtxosScriptpubkeys,
        txIndex: 0,
        tapleafScript: TaprootLeaf(script: trScriptP2pkA),
      );

      final sign = privkeyTrScriptA.signBip340(
        txDigit,
        tweak: false,
      );
      final controlBlock = TaprootControlBlock.generate(
        xOnlyOrInternalPubKey: fromPub.toXOnly(),
        scriptTree: TaprootBranch(
            a: TaprootLeaf(script: trScriptP2pkA),
            b: TaprootLeaf(script: trScriptP2pkB)),
        leafScript: TaprootLeaf(script: trScriptP2pkA),
        // treeScripts: [
        //   [
        //     TapLeafScript(script: trScriptP2pkA),
        //     TapLeafScript(script: trScriptP2pkB)
        //   ]
        // ],
        // leafScripts: [
        //   [TapLeafScript(script: trScriptP2pkA)]
        // ],
      );
      tx = tx.copyWith(witnesses: [
        TxWitnessInput(
            stack: [sign, trScriptP2pkA.toHex(), controlBlock.toHex()])
      ]);

      expect(tx.serialize(), signedTx3);
      final decode = BtcTransaction.deserialize(tx.toBytes());
      expect(decode.serialize(), tx.serialize());
    });
  });

  group('TestCreateP2trWithThreeTapScripts', () {
    // 1-spend taproot from key path (has three tapleaf script for spending)
    final privkeyTrScriptA = ECPrivate.fromWif(
        'cSW2kQbqC9zkqagw8oTYKFTozKuZ214zd6CMTDs4V32cMfH3dgKa',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    final pubkeyTrScriptA = privkeyTrScriptA.getPublic();
    final trScriptP2pkA = Script(script: [
      pubkeyTrScriptA.toXOnlyHex(),
      BitcoinOpcode.opCheckSig,
    ]);

    final privkeyTrScriptB = ECPrivate.fromWif(
        'cSv48xapaqy7fPs8VvoSnxNBNA2jpjcuURRqUENu3WVq6Eh4U3JU',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    final pubkeyTrScriptB = privkeyTrScriptB.getPublic();
    final trScriptP2pkB = Script(script: [
      pubkeyTrScriptB.toXOnlyHex(),
      BitcoinOpcode.opCheckSig,
    ]);

    final privkeyTrScriptC = ECPrivate.fromWif(
        'cRkZPNnn3jdr64o3PDxNHG68eowDfuCdcyL6nVL4n3czvunuvryC',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    final pubkeyTrScriptC = privkeyTrScriptC.getPublic();
    final trScriptP2pkC = Script(script: [
      pubkeyTrScriptC.toXOnlyHex(),
      BitcoinOpcode.opCheckSig,
    ]);

    final fromPriv = ECPrivate.fromWif(
        'cT33CWKwcV8afBs5NYzeSzeSoGETtAB8izjDjMEuGqyqPoF7fbQR',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    final fromPub = fromPriv.getPublic();
    final fromAddress = fromPub.toTaprootAddress(
      treeScript: TaprootBranch(
          a: TaprootBranch(
              b: TaprootLeaf(script: trScriptP2pkA),
              a: TaprootLeaf(script: trScriptP2pkB)),
          b: TaprootLeaf(script: trScriptP2pkC)),
    );

    final txIn = TxInput(
        txId:
            '9b8a01d0f333b2440d4d305d26641e14e0e1932ebc3c4f04387c0820fada87d3',
        txIndex: 0);

    final toPriv = ECPrivate.fromWif(
        'cNxX8M7XU8VNa5ofd8yk1eiZxaxNrQQyb7xNpwAmsrzEhcVwtCjs',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    final toPub = toPriv.getPublic();
    final toAddress = toPub.toTaprootAddress();
    final txOut = TxOutput(
        amount: BigInt.from(3000), scriptPubKey: toAddress.toScriptPubKey());

    // final fromAmount = priceToBtcUnit(0.000035);
    final allAmounts = [BigInt.from(3500)];

    final scriptPubkey = fromAddress.toScriptPubKey();
    final allUtxosScriptPubkeys = [scriptPubkey];

    const signedTx =
        '02000000000101d387dafa20087c38044f3cbc2e93e1e0141e64265d304d0d44b233f3d0018a9b0000000000ffffffff01b80b000000000000225120d4213cd57207f22a9e905302007b99b84491534729bd5f4065bdcb42ed10fcd50340644e392f5fd88d812bad30e73ff9900cdcf7f260ecbc862819542fd4683fa9879546613be4e2fc762203e45715df1a42c65497a63edce5f1dfe5caea5170273f2220e808f1396f12a253cf00efdf841e01c8376b616fb785c39595285c30f2817e71ac61c01036a7ed8d24eac9057e114f22342ebf20c16d37f0d25cfd2c900bf401ec09c9ed9f1b2b0090138e31e11a31c1aea790928b7ce89112a706e5caa703ff7e0ab928109f92c2781611bb5de791137cbd40a5482a4a23fd0ffe50ee4de9d5790dd100000000';

    test('test_spend_script_path_A_from_AB', () {
      var tx = BtcTransaction(
        inputs: [txIn],
        outputs: [txOut],
      );
      final digit = tx.getTransactionTaprootDigset(
          txIndex: 0,
          scriptPubKeys: allUtxosScriptPubkeys.map((e) => e).toList(),
          tapleafScript: TaprootLeaf(script: trScriptP2pkB),
          amounts: allAmounts.map((e) => e).toList());
      final sig = privkeyTrScriptB.signBip340(digit, tweak: false);
      final controlBlock = TaprootControlBlock.generate(
        xOnlyOrInternalPubKey: fromPub.toXOnly(),
        scriptTree: TaprootBranch(
            a: TaprootBranch(
                a: TaprootLeaf(script: trScriptP2pkA),
                b: TaprootLeaf(script: trScriptP2pkB)),
            b: TaprootLeaf(script: trScriptP2pkC)),
        leafScript: TaprootLeaf(script: trScriptP2pkB),
        // leafScripts: [
        //   [TapLeafScript(script: trScriptP2pkB)],
        // ],
      );

      tx = tx.copyWith(witnesses: [
        TxWitnessInput(
            stack: [sig, trScriptP2pkB.toHex(), controlBlock.toHex()])
      ]);
      expect(tx.serialize(), signedTx);
      final decode = BtcTransaction.deserialize(tx.toBytes());
      expect(decode.serialize(), tx.serialize());
    });
  });
  return;
}
