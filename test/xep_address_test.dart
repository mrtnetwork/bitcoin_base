import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

void main() {
  _test();
}

void _test() {
  test("xep address parsing", () {
    ElectraProtocolAddress address =
        ElectraProtocolAddress("ep1qyv4uspwsphhvj5keth02dk37pd0gqzmt5tw973");
    expect(address.type, SegwitAddressType.p2wpkh);
    address =
        ElectraProtocolAddress("ep1q2nxmsj9h9s6ps4tp5fce2vclm8uvkn00dtrnu7");
    expect(address.type, SegwitAddressType.p2wpkh);
    address = ElectraProtocolAddress("x8UFjR4n2h6hgFRJDdAna5nvN71qfsDmns");
    expect(address.type, P2shAddressType.p2pkInP2sh);
    address = ElectraProtocolAddress("xWzvSGpYUPucJaodadUh3yzEmLJGvHUYsP");
    expect(address.type, P2shAddressType.p2pkInP2sh);
    address = ElectraProtocolAddress("xWzvSGpYUPucJaodadUh3yzEmLJGvHUYsP");
    expect(address.type, P2shAddressType.p2pkInP2sh);
  });
}
