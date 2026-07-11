import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

void main() {
  group('BitcoinTransactionBuilder locktime', () {
    test('defaults to defaultTxLocktime', () {
      final b = BitcoinTransactionBuilder(
        outPuts: const [],
        fee: BigInt.zero,
        network: BitcoinNetwork.mainnet,
        utxos: const [],
      );
      expect(b.locktime, BitcoinOpCodeConst.defaultTxLocktime);
    });

    test('stores the provided locktime', () {
      final lt = [0x50, 0x01, 0xcf, 0x00];
      final b = BitcoinTransactionBuilder(
        outPuts: const [],
        fee: BigInt.zero,
        network: BitcoinNetwork.mainnet,
        utxos: const [],
        locktime: lt,
      );
      expect(b.locktime, lt);
    });
  });

  group('ForkedTransactionBuilder locktime', () {
    test('defaults to defaultTxLocktime', () {
      final b = ForkedTransactionBuilder(
        outPuts: const [],
        fee: BigInt.zero,
        network: BitcoinCashNetwork.mainnet,
        utxos: const [],
      );
      expect(b.locktime, BitcoinOpCodeConst.defaultTxLocktime);
    });

    test('stores the provided locktime', () {
      final lt = [0x50, 0x01, 0xcf, 0x00];
      final b = ForkedTransactionBuilder(
        outPuts: const [],
        fee: BigInt.zero,
        network: BitcoinCashNetwork.mainnet,
        utxos: const [],
        locktime: lt,
      );
      expect(b.locktime, lt);
    });
  });
}
