import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

void main() {
  test("network identifier", () {
    final id = BasedUtxoNetwork.values;
    expect(id.length, id.map((e) => e.tag).toSet().length);
    expect(id.length, id.map((e) => e.identifier).toSet().length);
    expect(id.length, id.map((e) => e.name).toSet().length);
  });

  test("types identifier", () {
    final id = BitcoinAddressType.values;
    expect(id.length, id.map((e) => e.name).toSet().length);
    expect(id.length, id.map((e) => e.id).toSet().length);
  });
}
