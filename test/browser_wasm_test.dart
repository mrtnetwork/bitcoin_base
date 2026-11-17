@TestOn('browser')
@Tags(['wasm'])
library;

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'utils.dart';

void browserWasmTest() {
  setUpAll(() async {
    // Shared harness: injects the glue script (served by the dart-test
    // static handler from test/wasm_assets/), waits for bootstrap, then
    // selects the Rust backend. No .so involved.
    await BitcoinBaseTestApi.initWasmBrowser();
  });

  group('wasm backend smoke (bitcoin_base)', () {
    test('sha256 empty (shared backend)', () {
      expect(
        BytesUtils.toHexString(QuickCrypto.sha256Hash([])),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });
    test('p2pkh address roundtrip', () {
      const addr = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa';
      final parsed = P2pkhAddress.fromAddress(
        address: addr,
        network: BitcoinNetwork.mainnet,
      );
      expect(parsed.toAddress(BitcoinNetwork.mainnet), addr);
    });
  });
}

void main() {
  BitcoinBaseTestApi.runTest(browserWasmTest, "Browser Wasm");
}
