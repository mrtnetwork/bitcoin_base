import 'dart:convert';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';
import 'art_collection.dart';
import 'decentralized_application.dart';
import 'fungible_token.dart';
import 'payouts_or_dividends.dart';

/// https://github.com/bitjson/chip-bcmr/tree/master/examples
void main() {
  test('pcmr test', () {
    final registry = Registry.fromJson(payoutsOrDividends);
    expect(json.encode(registry.toJson()), json.encode(payoutsOrDividends));
    final registry2 = Registry.fromJson(artCollection);
    expect(json.encode(registry2.toJson()), json.encode(artCollection));
    final registry3 = Registry.fromJson(fungibleToken);
    expect(json.encode(registry3.toJson()), json.encode(fungibleToken));
    final registry4 = Registry.fromJson(decentralizedApplication);
    expect(
        json.encode(registry4.toJson()), json.encode(decentralizedApplication));
  });
}
