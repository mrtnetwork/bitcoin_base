import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

void main() {
  test("IAddress encoding", () {
    {
      final network = BitcoinNetwork.testnet;
      final pk = ECPrivate.random().getPublic();
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toAddress(),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      // return;
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toP2pkAddress(),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toP2pkInP2sh(),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toP2pkhInP2sh(),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toP2wpkhInP2sh(),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toP2wshAddress(),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toSegwitAddress(),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toTaprootAddress(),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toP2wshInP2sh(),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
    }
  });
  test("Bitcoincash encoding", () {
    {
      final network = BitcoinCashNetwork.testnet;
      final pk = ECPrivate.random().getPublic();
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toAddress(),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toP2pkAddress(),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toP2pkInP2sh(),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toP2pkInP2sh(useBCHP2sh32: true),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toP2pkhInP2sh(),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toP2pkhInP2sh(useBCHP2sh32: true),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: pk.toP2pkhInP2sh(useBCHP2sh32: true),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
      {
        final addr = BitcoinNetworkAddress.fromBaseAddress(
          address: P2shAddress.fromHash160(
            addrHash: pk.toP2pkhInP2sh(useBCHP2sh32: true).addressProgram,
            type: P2shAddressType.p2pkInP2sh32wt,
          ),
          network: network,
        );
        final decode = BitcoinNetworkAddress.deserializeIAddress(
          bytes: addr.encodeAsIAddress(),
        );
        expect(addr, decode);
        expect(addr.address, decode.address);
      }
    }
  });
}
