import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'utils.dart';

const _txHash =
    'ece972a6d5d1b07062ed5aaab786b528b04a3cf675affdda8cb79ec805c53ce2';

final _key1 = ECPrivate.fromBytes(
  BytesUtils.fromHexString(
    '0101010101010101010101010101010101010101010101010101010101010101',
  ),
);
final _key2 = ECPrivate.fromBytes(
  BytesUtils.fromHexString(
    '0202020202020202020202020202020202020202020202020202020202020202',
  ),
);
final _key3 = ECPrivate.fromBytes(
  BytesUtils.fromHexString(
    '0303030303030303030303030303030303030303030303030303030303030303',
  ),
);
final _keys = [_key1, _key2, _key3];

MultiSignatureAddress _multiSigAddress({
  required int threshold,
  required List<int> weights,
}) {
  return MultiSignatureAddress(
    threshold: threshold,
    signers: [
      for (var i = 0; i < weights.length; i++)
        MultiSignatureSigner(
          publicKey: _keys[i].getPublic().toHex(),
          weight: weights[i],
        ),
    ],
  );
}

UtxoWithAddress _multiSigUtxo({
  required MultiSignatureAddress multiSigAddress,
  required BitcoinBaseAddress address,
  BigInt? value,
  int vout = 0,
}) {
  return UtxoWithAddress(
    utxo: BitcoinUtxo(
      blockHeight: 0,
      txHash: _txHash,
      value: value ?? BigInt.from(100000),
      vout: vout,
      scriptType: address.type,
    ),
    ownerDetails: UtxoAddressDetails.multiSigAddress(
      multiSigAddress: multiSigAddress,
      address: address,
    ),
  );
}

/// legacy signer, it is called once for every signer of the address
BitcoinSignerCallBack _legacySigner(
  List<ECPrivate> signingKeys, {
  List<String>? calledPublicKeys,
}) {
  return (digest, utxo, publicKey, sighash) {
    calledPublicKeys?.add(publicKey);
    for (final key in signingKeys) {
      if (key.getPublic().toHex() == publicKey) {
        return key.signECDSA(digest, sighash: sighash);
      }
    }

    /// the signer does not have the private key of this public key
    return '';
  };
}

BitcoinSignerCallBackAsync _legacySignerAsync(
  List<ECPrivate> signingKeys, {
  List<String>? calledPublicKeys,
}) {
  return (digest, utxo, publicKey, sighash) async {
    calledPublicKeys?.add(publicKey);
    for (final key in signingKeys) {
      if (key.getPublic().toHex() == publicKey) {
        return key.signECDSA(digest, sighash: sighash);
      }
    }

    /// the signer does not have the private key of this public key
    return '';
  };
}

/// multi-signature signer, it is called once for every multi-signature input
/// and it returns the signature of all the signers at once
BitcoinMultiSigSignerCallBack _multiSigSigner(
  List<ECPrivate> signingKeys, {
  List<List<String>>? calledPublicKeys,
}) {
  return (digest, utxo, publicKeys, sighash) {
    calledPublicKeys?.add(publicKeys);
    final signatures = <String, String>{};
    for (final key in signingKeys) {
      signatures[key.getPublic().toHex()] = key.signECDSA(
        digest,
        sighash: sighash,
      );
    }
    return signatures;
  };
}

BitcoinMultiSigSignerCallBackAsync _multiSigSignerAsync(
  List<ECPrivate> signingKeys, {
  List<List<String>>? calledPublicKeys,
}) {
  return (digest, utxo, publicKeys, sighash) async {
    calledPublicKeys?.add(publicKeys);
    final signatures = <String, String>{};
    for (final key in signingKeys) {
      signatures[key.getPublic().toHex()] = key.signECDSA(
        digest,
        sighash: sighash,
      );
    }
    return signatures;
  };
}

void multiSigTransactionBuilderTest() {
  group('Multi-signature transaction builder', () {
    test('legacy and multi-signature signer build the same transaction', () {
      const network = BitcoinNetwork.testnet;
      final multiSigAddress = _multiSigAddress(
        threshold: 2,
        weights: [1, 1, 1],
      );
      final address = multiSigAddress.toP2wshAddress(network: network);
      final utxos = [
        _multiSigUtxo(multiSigAddress: multiSigAddress, address: address),
      ];
      final builder = BitcoinTransactionBuilder(
        utxos: utxos,
        outPuts: [
          BitcoinOutput(
            address: _key1.getPublic().toAddress(),
            value: BigInt.from(90000),
          ),
        ],
        fee: BigInt.from(10000),
        network: network,
      );

      /// the second signer does not sign
      final legacyTransaction = builder.buildTransaction(
        _legacySigner([_key1, _key3]),
      );
      final multiSigTransaction = builder.buildTransaction(
        _legacySigner([_key1, _key3]),
        multiSigSign: _multiSigSigner([_key1, _key3]),
      );

      expect(multiSigTransaction.serialize(), legacyTransaction.serialize());
    });

    test('the multi-signature signer is called once for every input', () {
      const network = BitcoinNetwork.testnet;
      final multiSigAddress = _multiSigAddress(
        threshold: 2,
        weights: [1, 1, 1],
      );
      final address = multiSigAddress.toP2wshAddress(network: network);
      final utxos = [
        _multiSigUtxo(multiSigAddress: multiSigAddress, address: address),
      ];
      final builder = BitcoinTransactionBuilder(
        utxos: utxos,
        outPuts: [
          BitcoinOutput(
            address: _key1.getPublic().toAddress(),
            value: BigInt.from(90000),
          ),
        ],
        fee: BigInt.from(10000),
        network: network,
      );

      final legacyCalls = <String>[];
      final multiSigCalls = <List<String>>[];
      builder.buildTransaction(
        _legacySigner(_keys, calledPublicKeys: legacyCalls),
      );
      builder.buildTransaction(
        _legacySigner(_keys),
        multiSigSign: _multiSigSigner(_keys, calledPublicKeys: multiSigCalls),
      );

      /// the legacy signer is called once for every signer
      expect(legacyCalls.length, 2);

      /// the multi-signature signer is called once for the whole input
      expect(multiSigCalls.length, 1);
      expect(
        multiSigCalls.first,
        multiSigAddress.signers.map((e) => e.publicKey).toList(),
      );
    });

    test(
      'the multi-signature signer is called once for every input (async)',
      () async {
        const network = BitcoinNetwork.testnet;
        final multiSigAddress = _multiSigAddress(
          threshold: 2,
          weights: [1, 1, 1],
        );
        final address = multiSigAddress.toP2wshAddress(network: network);
        final utxos = [
          _multiSigUtxo(multiSigAddress: multiSigAddress, address: address),
        ];
        final builder = BitcoinTransactionBuilder(
          utxos: utxos,
          outPuts: [
            BitcoinOutput(
              address: _key1.getPublic().toAddress(),
              value: BigInt.from(90000),
            ),
          ],
          fee: BigInt.from(10000),
          network: network,
        );

        final legacyCalls = <String>[];
        final multiSigCalls = <List<String>>[];
        await builder.buildTransactionAsync(
          _legacySignerAsync(_keys, calledPublicKeys: legacyCalls),
        );
        await builder.buildTransactionAsync(
          _legacySignerAsync(_keys),
          multiSigSign: _multiSigSignerAsync(
            _keys,
            calledPublicKeys: multiSigCalls,
          ),
        );

        expect(legacyCalls.length, 2);
        expect(multiSigCalls.length, 1);
      },
    );

    test('weighted multi-signature address (sync and async)', () async {
      const network = BitcoinNetwork.testnet;
      final multiSigAddress = _multiSigAddress(threshold: 2, weights: [1, 3]);
      final address = multiSigAddress.toP2wshAddress(network: network);
      final utxos = [
        _multiSigUtxo(multiSigAddress: multiSigAddress, address: address),
      ];
      final builder = BitcoinTransactionBuilder(
        utxos: utxos,
        outPuts: [
          BitcoinOutput(
            address: _key1.getPublic().toAddress(),
            value: BigInt.from(90000),
          ),
        ],
        fee: BigInt.from(10000),
        network: network,
      );

      final legacyTransaction = builder.buildTransaction(_legacySigner(_keys));
      final asyncTransaction = await builder.buildTransactionAsync(
        _legacySignerAsync(_keys),
      );
      final multiSigTransaction = builder.buildTransaction(
        _legacySigner(_keys),
        multiSigSign: _multiSigSigner(_keys),
      );

      expect(asyncTransaction.serialize(), legacyTransaction.serialize());
      expect(multiSigTransaction.serialize(), legacyTransaction.serialize());
    });

    test('the signature of a signer is used as many times as its weight', () {
      const network = BitcoinNetwork.testnet;
      final multiSigAddress = _multiSigAddress(threshold: 2, weights: [3]);
      final address = multiSigAddress.toP2wshAddress(network: network);
      final utxos = [
        _multiSigUtxo(multiSigAddress: multiSigAddress, address: address),
      ];
      final builder = BitcoinTransactionBuilder(
        utxos: utxos,
        outPuts: [
          BitcoinOutput(
            address: _key1.getPublic().toAddress(),
            value: BigInt.from(90000),
          ),
        ],
        fee: BigInt.from(10000),
        network: network,
      );

      final transaction = builder.buildTransaction(
        _legacySigner([_key1]),
        multiSigSign: _multiSigSigner([_key1]),
      );

      /// the witness stack is [dummy, signature, signature, witness script]
      final witness = transaction.witnesses.first.stack;
      expect(witness.length, 4);
      expect(witness[1], witness[2]);
      expect(witness[1].isNotEmpty, true);
    });

    test('nested p2sh segwit multi-signature address', () {
      const network = BitcoinNetwork.testnet;
      final multiSigAddress = _multiSigAddress(
        threshold: 2,
        weights: [1, 1, 1],
      );
      final address = multiSigAddress.toP2wshInP2shAddress(network: network);
      final utxos = [
        _multiSigUtxo(multiSigAddress: multiSigAddress, address: address),
      ];
      final builder = BitcoinTransactionBuilder(
        utxos: utxos,
        outPuts: [
          BitcoinOutput(
            address: _key1.getPublic().toAddress(),
            value: BigInt.from(90000),
          ),
        ],
        fee: BigInt.from(10000),
        network: network,
      );

      final legacyTransaction = builder.buildTransaction(
        _legacySigner([_key1, _key2]),
      );
      final multiSigTransaction = builder.buildTransaction(
        _legacySigner([_key1, _key2]),
        multiSigSign: _multiSigSigner([_key1, _key2]),
      );

      expect(multiSigTransaction.serialize(), legacyTransaction.serialize());
    });

    test('throws an exception when the signatures are not enough', () {
      const network = BitcoinNetwork.testnet;
      final multiSigAddress = _multiSigAddress(
        threshold: 2,
        weights: [1, 1, 1],
      );
      final address = multiSigAddress.toP2wshAddress(network: network);
      final utxos = [
        _multiSigUtxo(multiSigAddress: multiSigAddress, address: address),
      ];
      final builder = BitcoinTransactionBuilder(
        utxos: utxos,
        outPuts: [
          BitcoinOutput(
            address: _key1.getPublic().toAddress(),
            value: BigInt.from(90000),
          ),
        ],
        fee: BigInt.from(10000),
        network: network,
      );

      expect(
        () => builder.buildTransaction(
          _legacySigner([_key1]),
          multiSigSign: _multiSigSigner([_key1]),
        ),
        throwsA(
          isA<BuError>().having(
            (e) => e.message,
            'message',
            'some multisig signature does not exist',
          ),
        ),
      );
    });

    test('a single signature address is not affected', () async {
      const network = BitcoinNetwork.testnet;
      final utxos = [
        UtxoWithAddress(
          utxo: BitcoinUtxo(
            blockHeight: 0,
            txHash: _txHash,
            value: BigInt.from(100000),
            vout: 0,
            scriptType: SegwitAddressType.p2wpkh,
          ),
          ownerDetails: UtxoAddressDetails(
            publicKey: _key1.getPublic().toHex(),
            address: _key1.getPublic().toSegwitAddress(),
          ),
        ),
      ];
      final builder = BitcoinTransactionBuilder(
        utxos: utxos,
        outPuts: [
          BitcoinOutput(
            address: _key1.getPublic().toAddress(),
            value: BigInt.from(90000),
          ),
        ],
        fee: BigInt.from(10000),
        network: network,
      );

      final transaction = builder.buildTransaction(
        (digest, utxo, publicKey, sighash) =>
            _key1.signECDSA(digest, sighash: sighash),
      );
      final asyncTransaction = await builder.buildTransactionAsync(
        (digest, utxo, publicKey, sighash) async =>
            _key1.signECDSA(digest, sighash: sighash),
      );

      expect(asyncTransaction.serialize(), transaction.serialize());
    });
  });

  group('Multi-signature forked transaction builder', () {
    test('legacy and multi-signature signer build the same transaction', () {
      const network = BitcoinCashNetwork.mainnet;
      final multiSigAddress = _multiSigAddress(
        threshold: 2,
        weights: [1, 1, 1],
      );
      final address = multiSigAddress.toP2shAddress();
      final utxos = [
        _multiSigUtxo(multiSigAddress: multiSigAddress, address: address),
      ];
      final builder = ForkedTransactionBuilder(
        utxos: utxos,
        outPuts: [
          BitcoinOutput(
            address: _key1.getPublic().toAddress(),
            value: BigInt.from(90000),
          ),
        ],
        fee: BigInt.from(10000),
        network: network,
      );

      final legacyTransaction = builder.buildTransaction(
        _legacySigner([_key1, _key3]),
      );
      final multiSigTransaction = builder.buildTransaction(
        _legacySigner([_key1, _key3]),
        multiSigSign: _multiSigSigner([_key1, _key3]),
      );

      expect(multiSigTransaction.serialize(), legacyTransaction.serialize());
    });

    test('the multi-signature signer is called once for every input', () async {
      const network = BitcoinCashNetwork.mainnet;
      final multiSigAddress = _multiSigAddress(
        threshold: 2,
        weights: [1, 1, 1],
      );
      final address = multiSigAddress.toP2shAddress();
      final utxos = [
        _multiSigUtxo(multiSigAddress: multiSigAddress, address: address),
      ];
      final builder = ForkedTransactionBuilder(
        utxos: utxos,
        outPuts: [
          BitcoinOutput(
            address: _key1.getPublic().toAddress(),
            value: BigInt.from(90000),
          ),
        ],
        fee: BigInt.from(10000),
        network: network,
      );

      final legacyCalls = <String>[];
      final multiSigCalls = <List<String>>[];
      await builder.buildTransactionAsync(
        _legacySignerAsync(_keys, calledPublicKeys: legacyCalls),
      );
      final transaction = await builder.buildTransactionAsync(
        _legacySignerAsync(_keys),
        multiSigSign: _multiSigSignerAsync(
          _keys,
          calledPublicKeys: multiSigCalls,
        ),
      );

      expect(legacyCalls.length, 2);
      expect(multiSigCalls.length, 1);
      expect(transaction.witnesses, isEmpty);
    });
  });
}

void multiSigTransactionBuilderTest2() {
  BitcoinBaseTestApi.runTest(
    multiSigTransactionBuilderTest,
    "Multi-signature Transaction Builder",
  );
}

void main() {
  BitcoinBaseTestApi.runTest(
    multiSigTransactionBuilderTest2,
    "Multi-signature Transaction Builder",
  );
}
