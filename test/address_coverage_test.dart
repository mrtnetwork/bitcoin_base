import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'utils.dart';

/// Full validation of:
///  1. [ECPublic.generateAddress] for every [BitcoinAddressType].
///  2. [BitcoinNetworkAddress] for every [BasedUtxoNetwork].
void addressCoverageTest() {
  // Deterministic compressed / uncompressed generator point (privkey 1).
  const compGHex =
      '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
  const uncompGHex =
      '0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798'
      '483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8';
  final compG = ECPublic.fromHex(compGHex);
  final uncompG = ECPublic.fromHex(uncompGHex);

  group('ECPublic.generateAddress per address type', () {
    test('known vector: privkey-1 compressed P2PKH (bitcoin mainnet)', () {
      final base = compG.generateAddress(
        addressType: P2pkhAddressType.p2pkh,
        encoding: CryptoKeyEncoding.base,
      );
      expect(base.type, P2pkhAddressType.p2pkh);
      expect(
        base.toAddress(BitcoinNetwork.mainnet),
        '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH',
      );
    });

    for (final type in BitcoinAddressType.values) {
      test('generateAddress ${type.name}', () {
        for (final enc in CryptoKeyEncoding.values) {
          final supported = type.supportedKeyEncoding.contains(enc);
          if (!supported) {
            expect(
              () => compG.generateAddress(addressType: type, encoding: enc),
              throwsA(isA<BuError>()),
              reason: '${type.name} must reject $enc',
            );
            continue;
          }
          for (final pub in [compG, uncompG]) {
            // uncompressed input key can still request either encoding.
            final base = pub.generateAddress(addressType: type, encoding: enc);
            expect(base.type, type, reason: 'type echo for ${type.name}');
            expect(base.toScriptPubKey().toBytes(), isNotEmpty);
            expect(base.pubKeyHash(), isNotEmpty);

            if (base is P2pkAddress) {
              // P2PK has no hash program: addressProgram throws by design and
              // the identity lives in `publicKey`.
              expect(base.publicKey, isNotEmpty);
              expect(() => base.addressProgram, throwsA(isA<BuError>()));
              final decoded = BitcoinBaseAddress.fromProgram(
                addressProgram: base.publicKey,
                type: type,
              );
              expect(decoded, isA<P2pkAddress>());
              expect((decoded as P2pkAddress).publicKey, base.publicKey);
              continue;
            }
            expect(base.addressProgram, isNotEmpty);

            // fromProgram round-trip preserves type + script.
            final decoded = BitcoinBaseAddress.fromProgram(
              addressProgram: base.addressProgram,
              type: type,
            );
            expect(decoded.type, type);
            expect(
              decoded.toScriptPubKey().toBytes(),
              base.toScriptPubKey().toBytes(),
              reason: 'script round-trip for ${type.name}',
            );
          }
        }
      });
    }
  });

  group('BitcoinNetworkAddress per network', () {
    test('every network x every supported address type', () {
      for (final network in BasedUtxoNetwork.values) {
        if (network is ZcashNetworkTransparent) {
          // Documented gap: switch in fromBaseAddress/parse has no Zcash arm.
          final base = compG.generateAddress(
            addressType: P2pkhAddressType.p2pkh,
            encoding: CryptoKeyEncoding.base,
          );
          expect(
            () => BitcoinNetworkAddress.fromBaseAddress(
              address: base,
              network: network,
            ),
            throwsA(isA<BuError>()),
            reason: 'Zcash unsupported by BitcoinNetworkAddress',
          );
          continue;
        }
        for (final type in network.supportedAddress) {
          final enc = type.supportedKeyEncoding.first;
          final base = compG.generateAddress(addressType: type, encoding: enc);
          final netAddr = compG.generateNetworkAddress(
            addressType: type,
            encoding: enc,
            network: network,
          );
          expect(netAddr.network, network);
          expect(netAddr.type, type);
          expect(netAddr.address, isNotEmpty);

          // fromBaseAddress agrees with generateNetworkAddress.
          final viaBase = BitcoinNetworkAddress.fromBaseAddress(
            address: base,
            network: network,
          );
          expect(viaBase.address, netAddr.address);
          expect(viaBase.type, type);
          expect(
            viaBase.toScriptPubKey().toBytes(),
            base.toScriptPubKey().toBytes(),
          );

          // parse round-trip. Base58/cashaddr strings do not encode every
          // subtype, so this is lossy by design for two families:
          //  - P2PK: toAddress emits a P2PKH-version string, parse yields P2pkh.
          //  - P2SH: the string carries only (version, program). Non-BCH
          //    decodes any P2SH string to the default p2pkInP2sh; BCH recovers
          //    the (length, token) family as its p2pkh-variant. The object path
          //    above (fromBaseAddress) always preserves the exact type.
          //  The program/script are preserved in all cases (except P2PK, whose
          //  script is the pubkey itself, not the hash the string encodes).
          final parsed = BitcoinNetworkAddress.parse(
            address: netAddr.address,
            network: network,
          );
          expect(parsed.address, netAddr.address);
          if (type == PubKeyAddressType.p2pk) {
            expect(parsed.type, P2pkhAddressType.p2pkh);
          } else if (type is P2shAddressType) {
            expect(parsed.baseAddress.addressProgram, base.addressProgram);
            expect(
              parsed.toScriptPubKey().toBytes(),
              base.toScriptPubKey().toBytes(),
            );
            expect(parsed.type, _expectedParsedP2sh(network, type));
          } else {
            expect(parsed.type, type);
            expect(
              parsed.toScriptPubKey().toBytes(),
              base.toScriptPubKey().toBytes(),
            );
          }
          expect(
            BitcoinNetworkAddress.tryParse(
              address: netAddr.address,
              network: network,
            )?.address,
            netAddr.address,
          );

          // IAddress (CBOR) round-trip.
          final re = BitcoinNetworkAddress.deserializeIAddress(
            bytes: netAddr.encodeAsIAddress(),
          );
          expect(re.address, netAddr.address);
          expect(re.type, type);
        }
      }
    });

    test('unsupported type rejected per network (p2tr on Dash)', () {
      final p2tr = compG.generateAddress(
        addressType: SegwitAddressType.p2tr,
        encoding: CryptoKeyEncoding.base,
      );
      expect(
        () => BitcoinNetworkAddress.fromBaseAddress(
          address: p2tr,
          network: DashNetwork.mainnet,
        ),
        throwsA(isA<BuError>()),
      );
      expect(
        () => compG.generateNetworkAddress(
          addressType: SegwitAddressType.p2tr,
          encoding: CryptoKeyEncoding.base,
          network: DashNetwork.mainnet,
        ),
        throwsA(isA<BuError>()),
      );
    });

    test('cross-network parse rejected (mainnet addr on testnet)', () {
      final mainnet = compG.generateNetworkAddress(
        addressType: P2pkhAddressType.p2pkh,
        encoding: CryptoKeyEncoding.base,
        network: BitcoinNetwork.mainnet,
      );
      expect(
        () => BitcoinNetworkAddress.parse(
          address: mainnet.address,
          network: BitcoinNetwork.testnet,
        ),
        throwsA(anything),
      );
    });

    test('garbage address rejected', () {
      expect(
        () => BitcoinNetworkAddress.parse(
          address: 'not-an-address',
          network: BitcoinNetwork.mainnet,
        ),
        throwsA(anything),
      );
      expect(
        BitcoinNetworkAddress.tryParse(
          address: 'not-an-address',
          network: BitcoinNetwork.mainnet,
        ),
        isNull,
      );
    });
  });
}

/// Expected string-parse result for a P2SH [type] on [network].
/// Non-BCH base58 decodes every P2SH string to the default p2pkInP2sh;
/// BCH cashaddr recovers the (length, token) family as its p2pkh-variant.
P2shAddressType _expectedParsedP2sh(
  BasedUtxoNetwork network,
  P2shAddressType type,
) {
  if (network is! BitcoinCashNetwork) return P2shAddressType.p2pkInP2sh;
  if (type.hashLength == QuickCrypto.sha256DigestSize) {
    return type.withToken
        ? P2shAddressType.p2pkhInP2sh32wt
        : P2shAddressType.p2pkhInP2sh32;
  }
  return type.withToken
      ? P2shAddressType.p2pkhInP2shwt
      : P2shAddressType.p2pkhInP2sh;
}

void addressCoverageTest2() {
  BitcoinBaseTestApi.runTest(addressCoverageTest, 'Address coverage');
}

void main() {
  BitcoinBaseTestApi.runTest(addressCoverageTest2, 'Address coverage');
}
