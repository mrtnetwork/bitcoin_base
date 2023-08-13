import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/address/segwit_address.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/crypto/ec/ec_private.dart';
import 'package:bitcoin_base/src/crypto/ec/ec_public.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("TestPrivateKeys", () {
    const keyWifc = "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn";
    const keyWif = "5HpHagT65TZzG1PH3CSu63k8DbpvD8s5ip4nEB3kEsreAnchuDf";
    final keyBytes = [
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01,
    ];

    test("test1", () {
      final p = ECPrivate.fromWif(keyWifc);
      expect(p.toBytes(), keyBytes);
      expect(p.toWif(compressed: false), keyWif);
    });
  });

  group("TestPublicKeys", () {
    const String publicKeyHex =
        '0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8';
    final Uint8List publicKeyBytes = Uint8List.fromList([
      121,
      190,
      102,
      126,
      249,
      220,
      187,
      172,
      85,
      160,
      98,
      149,
      206,
      135,
      11,
      7,
      2,
      155,
      252,
      219,
      45,
      206,
      40,
      217,
      89,
      242,
      129,
      91,
      22,
      248,
      23,
      152,
      72,
      58,
      218,
      119,
      38,
      163,
      196,
      101,
      93,
      164,
      251,
      252,
      14,
      17,
      8,
      168,
      253,
      23,
      180,
      72,
      166,
      133,
      84,
      25,
      156,
      71,
      208,
      143,
      251,
      16,
      212,
      184
    ]);
    const String unCompressedAddress = '1EHNa6Q4Jz2uvNExL497mE43ikXhwF6kZm';

    test("testPubkeyCreation", () {
      final pub1 = ECPublic.fromHex(publicKeyHex);
      expect(pub1.toAddress(copressed: false).toAddress(NetworkInfo.BITCOIN),
          unCompressedAddress);
      expect(pub1.toBytes(prefix: null), publicKeyBytes);
      expect(pub1.toHash160(), pub1.toAddress(copressed: true).getH160);
    });
  });

  group("TestP2pkhAddresses", () {
    const String hash160 = '91b24bf9f5288532960ac687abb035127b1d28a5';
    const String hash160c = '751e76e8199196d454941c45d1b3a323f1433bd6';
    const String address = '1EHNa6Q4Jz2uvNExL497mE43ikXhwF6kZm';
    const String addressc = '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH';
    test("test1", () {
      final p1 = P2pkhAddress(hash160: hash160);
      final p2 = P2pkhAddress(hash160: hash160c);
      expect(p1.toAddress(NetworkInfo.BITCOIN), address);
      expect(p2.toAddress(NetworkInfo.BITCOIN), addressc);
    });
    test("test2", () {
      final p1 = P2pkhAddress(address: address);
      final p2 = P2pkhAddress(address: addressc);
      expect(p1.getH160, hash160);
      expect(p2.getH160, hash160c);
    });
  });

  group("TestSignAndVerify", () {
    const String message = "The test!";
    const String keyWifc =
        "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn";
    final ECPrivate priv = ECPrivate.fromWif(keyWifc);
    final ECPublic pub = priv.getPublic();
    const String deterministicSignature =
        '204890ee41df1aa9711d239c51fb73478802863ba925bb882090a26372ebc90f525f03de46806d25892b35dfeb814ed13fd8d7ea2d8868619830bb7d6d6fbf6db2';
    test("test1", () {
      final sign = priv.signMessage(message);
      pub.verify(message, hexToBytes(sign));
      expect(sign, deterministicSignature);
      expect(pub.verify(message, hexToBytes(sign)), true);
    });
    test("getpublic", () {
      final signer = ECPublic.getSignaturPublic(
          message, hexToBytes(deterministicSignature));
      expect(signer?.toAddress(copressed: true).toAddress(NetworkInfo.BITCOIN),
          pub.toAddress(copressed: true).toAddress(NetworkInfo.BITCOIN));
    });
    test("test2", () {});
  });

  group("TestP2pkhAddresses", () {
    final ECPrivate priv = ECPrivate.fromWif(
        'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo');
    ECPublic pub = priv.getPublic();
    const String p2shaddress = '2NDkr9uD2MSY5em3rsjkff8fLZcJzCfY3W1';
    test("test create", () {
      final script = Script(script: [pub.toHex(), 'OP_CHECKSIG']);
      final addr = P2shAddress(script: script);
      expect(addr.toAddress(NetworkInfo.TESTNET), p2shaddress);
    });
    test("p2sh to script", () {
      final script = Script(script: [pub.toHex(), 'OP_CHECKSIG']);
      final fromScript = script.toP2shScriptPubKey().toHex();
      final addr = P2shAddress(script: script);
      final fromP2shAddress = Script(script: addr.toScriptPubKey()).toHex();
      expect(fromScript, fromP2shAddress);
    });
  });

  group("TestP2pkhAddresses", () {
    final ECPrivate priv = ECPrivate.fromWif(
        'cVdte9ei2xsVjmZSPtyucG43YZgNkmKTqhwiUA8M4Fc3LdPJxPmZ');
    ECPublic pub = priv.getPublic();
    const String correctP2wpkhAddress =
        'tb1qxmt9xgewg6mxc4mvnzvrzu4f2v0gy782fydg0w';
    const String correctP2shP2wpkhAddress =
        '2N8Z5t3GyPW1hSAEJZqQ1GUkZ9ofoGhgKPf';
    const String correctP2wshAddress =
        'tb1qy4kdfavhluvnhpwcqmqrd8x0ge2ynnsl7mv2mdmdskx4g3fc6ckq8f44jg';
    const String correctP2shP2wshAddress =
        '2NC2DBZd3WfEF9cZcpBRDYxCTGCVCfPUf7Q';
    test("test1", () {
      final address = P2wpkhAddress(program: pub.toSegwitAddress().getProgram);
      expect(correctP2wpkhAddress, address.toAddress(NetworkInfo.TESTNET));
    });
    test("test2", () {
      final addr = ECPrivate.fromWif(
              "cTmyBsxMQ3vyh4J3jCKYn2Au7AhTKvqeYuxxkinsg6Rz3BBPrYKK")
          .getPublic()
          .toSegwitAddress();
      final p2sh = P2shAddress(script: Script(script: addr.toScriptPubKey()));
      expect(correctP2shP2wpkhAddress, p2sh.toAddress(NetworkInfo.TESTNET));
    });
    test("test3", () {
      final prive = ECPrivate.fromWif(
          "cNn8itYxAng4xR4eMtrPsrPpDpTdVNuw7Jb6kfhFYZ8DLSZBCg37");
      final script = Script(script: [
        'OP_1',
        prive.getPublic().toHex(),
        'OP_1',
        'OP_CHECKMULTISIG'
      ]);
      final pw = P2wshAddress(script: script);
      expect(pw.toAddress(NetworkInfo.TESTNET), correctP2wshAddress);
    });
    test("test4", () {
      final prive = ECPrivate.fromWif(
          "cNn8itYxAng4xR4eMtrPsrPpDpTdVNuw7Jb6kfhFYZ8DLSZBCg37");
      final script = Script(script: [
        'OP_1',
        prive.getPublic().toHex(),
        'OP_1',
        'OP_CHECKMULTISIG'
      ]);
      final pw = P2wshAddress(script: script);
      final p2sh = P2shAddress(script: Script(script: pw.toScriptPubKey()));
      expect(p2sh.toAddress(NetworkInfo.TESTNET), correctP2shP2wshAddress);
    });
  });

  group("TestP2trAddresses", () {
    final privEven = ECPrivate.fromWif(
        'cTLeemg1bCXXuRctid7PygEn7Svxj4zehjTcoayrbEYPsHQo248w');
    const String correctEvenPk =
        '0271fe85f75e97d22e74c2dd6425e843def8b662b928f24f724ae6a2fd0c4e0419';
    const String correctEvenTrAddr =
        'tb1pk426x6qvmncj5vzhtp5f2pzhdu4qxsshszswga8ea6sycj9nulmsu7syz0';
    const String correctEvenTweakedPk =
        'b555a3680cdcf12a305758689504576f2a03421780a0e474f9eea04c48b3e7f7';

    final privOdd = ECPrivate.fromWif(
        'cRPxBiKrJsH94FLugmiL4xnezMyoFqGcf4kdgNXGuypNERhMK6AT');
    const String correctOddPk =
        '03a957ff7ead882e4c95be2afa684ab0e84447149883aba60c067adc054472785b';
    const String correctOddTrAddr =
        'tb1pdr8q4tuqqeglxxhkxl3trxt0dy5jrnaqvg0ddwu7plraxvntp8dqv8kvyq';
    const String correctOddTweakedPk =
        '68ce0aaf800651f31af637e2b1996f692921cfa0621ed6bb9e0fc7d3326b09da';
    test("test1", () {
      final pub = privEven.getPublic();
      expect(pub.toHex(), correctEvenPk);
    });
    test("test2", () {
      final pub = privEven.getPublic();
      final addr = pub.toTaprootAddress().toAddress(NetworkInfo.TESTNET);
      expect(addr, correctEvenTrAddr);
    });
    test("test3", () {
      final pub = privEven.getPublic();
      final addr = pub.toTaprootAddress();
      expect(addr.getProgram, correctEvenTweakedPk);
    });
    test("test4", () {
      final pub = privOdd.getPublic();
      expect(pub.toHex(), correctOddPk);
    });
    test("test5", () {
      final pub = privOdd.getPublic();
      final addr = pub.toTaprootAddress().toAddress(NetworkInfo.TESTNET);
      expect(addr, correctOddTrAddr);
    });
    test("test6", () {
      final pub = privOdd.getPublic();
      final addr = pub.toTaprootAddress();
      expect(addr.getProgram, correctOddTweakedPk);
    });
  });
}
