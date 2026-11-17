// Bitcoin regtest: DKLs23(secp256k1) threshold ECDSA on non-Taproot outputs (P2WPKH, P2SH-P2WPKH, P2PKH).

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/examples/local/local_node.dart';

/// A DKLs23(secp256k1) quorum and the addresses it can spend.
class DklsQuorum {
  DklsQuorum._({required this.key, required this.addresses});

  /// Quorum key; `threshold` is `t` (or `n` when null).
  final Dkls23Secp256k1PrivateKey key;

  /// Address of the group key for each non-Taproot type.
  final Map<String, BitcoinNetworkAddress> addresses;

  int? get threshold => key.publicKey.threshold;

  int get n => key.publicKey.n ?? key.publicKey.members!.length;

  /// 33-byte group public key.
  List<int> get groupKey => key.publicKey.aggKey.toBytes();

  /// `t`-of-`n` display string.
  String get describe => '${threshold ?? n}-of-$n';

  /// Signs a 32-byte ECDSA digest.
  IECDSASignature sign(List<int> digest, {List<int>? subset}) {
    return Dkls23Secp256k1Signer(key).signHash(
      digest,
      subset: subset,
    );
  }

  /// ECDSA signature in Bitcoin's DER form with the sighash byte appended.
  ///
  /// `IECDSASignature.toBytes(encoding: der)` produces the minimal-length
  /// DER Bitcoin requires; hand-rolling `DerCodec.encodeEcdsaSignatureDer`
  /// can leave a redundant leading zero in `r`/`s`, which the consensus
  /// rules reject.
  String signDer(List<int> digest, int sighash) {
    final sig = sign(digest);
    return BytesUtils.toHexString([
      ...sig.toBytes(encoding: ECDSASignatureEncoding.der),
      sighash,
    ]);
  }
}

/// Deterministic `t`-of-`n` DKLs23 secp256k1 quorum.
///
/// [threshold] `null` keeps the full quorum (`t == n`); a value selects a
/// proper threshold. Fixed `sid` + `seeds` make the group key identical on
/// every run, so a funded address stays funded.
DklsQuorum buildQuorum({
  required BasedUtxoNetwork network,
  required String label,
  int? threshold,
  int parties = 3,
}) {
  final sid = QuickCrypto.keccak256Hash(
    [...'bitcoin_base/dkls23'.codeUnits, ...label.codeUnits],
  ).toList();
  final seeds = [
    for (var i = 0; i < parties; i++)
      QuickCrypto.keccak256Hash([
        ...'bitcoin_base/dkls23/seed'.codeUnits,
        ...label.codeUnits,
        i,
      ]).toList(),
  ].expand((e) => e).toList();

  final key = Dkls23Secp256k1PrivateKey.generate(
    sid: sid,
    n: parties,
    seeds: seeds,
    threshold: threshold,
  );
  final pub = key.publicKey;

  /// The group key is a normal secp256k1 key, so it derives every address
  /// type the network supports (except Taproot).
  final group = ECPublic.fromBytes(pub.aggKey.toBytes());
  final addresses = <String, BitcoinNetworkAddress>{
    'P2WPKH': group.generateNetworkAddress(
      addressType: SegwitAddressType.p2wpkh,
      encoding: CryptoKeyEncoding.base,
      network: network,
    ),
    'P2SH-P2WPKH': group.generateNetworkAddress(
      addressType: P2shAddressType.p2wpkhInP2sh,
      encoding: CryptoKeyEncoding.base,
      network: network,
    ),
    'P2PKH': group.generateNetworkAddress(
      addressType: P2pkhAddressType.p2pkh,
      encoding: CryptoKeyEncoding.base,
      network: network,
    ),
  };
  return DklsQuorum._(key: key, addresses: addresses);
}

/// Rewrites the owner of [utxos] to [groupKey].
///
/// `readUtxos` records the funding wallet's public key as the UTXO owner so
/// the builder can put a pubkey in the P2WPKH scriptSig/witness. A quorum has
/// no single private key, so the owner must be the *group* key: the witness
/// then commits to the same key the output was paid to.
List<UtxoWithAddress> withGroupKey({
  required List<UtxoWithAddress> utxos,
  required List<int> groupKey,
  required BitcoinNetworkAddress address,
}) {
  return utxos
      .map(
        (e) => UtxoWithAddress(
          utxo: e.utxo,
          ownerDetails: UtxoAddressDetails(
            publicKey: ECPublic.fromBytes(groupKey).toHex(),
            address: address.baseAddress,
          ),
        ),
      )
      .toList();
}

/// Spends [utxos] (all of one address type) back to [destination].
///
/// SegWit v0 inputs sign a BIP-143 digest; legacy P2PKH signs the legacy
/// digest. `BitcoinTransactionBuilder` handles the digest selection and the
/// witness/scriptSig assembly, so the callback only signs.
Future<String> spend({
  required BitcoinProvider provider,
  required RegtestNode node,
  required BasedUtxoNetwork network,
  required List<UtxoWithAddress> utxos,
  required BitcoinNetworkAddress destination,
  required String miningAddress,
  required DklsQuorum quorum,
  List<int>? subset,
}) async {
  final total = utxos.fold(BigInt.zero, (sum, utxo) => sum + utxo.utxo.value);
  final tx = BitcoinTransactionBuilder(
    outPuts: [
      BitcoinOutput(
        address: destination.baseAddress,
        value: total - exampleFee,
      ),
    ],
    fee: exampleFee,
    network: network,
    utxos: utxos,
  ).buildTransaction((digest, utxo, publicKey, sighash) {
    /// Non-Taproot: ECDSA (DER + sighash byte) for every address type.
    final sig = quorum.sign(digest, subset: subset);
    return BytesUtils.toHexString([
      ...sig.toBytes(encoding: ECDSASignatureEncoding.der),
      sighash,
    ]);
  });

  return broadcastAndConfirm(provider, node, tx, miningAddress);
}

Future<void> main() async {
  const network = BitcoinNetwork.regtest;
  final node = RegtestNode.bitcoin;
  final mining = Mining(network);

  final service = await node.connectElectrum();
  final provider = BitcoinProvider(service);
  final destination = LocalWallet(index: 5, network: network);

  print('Bitcoin regtest: DKLs23(secp256k1) threshold ECDSA');
  print('  electrum: ${service.url}');
  print('  tip:      ${await waitForTip(provider, node)}');
  print('');

  /// ---- 1. 2-of-3 quorum, P2WPKH ------------------------------------------
  {
    final quorum = buildQuorum(network: network, label: '2of3', threshold: 2);
    final address = quorum.addresses['P2WPKH']!;
    print('quorum:           ${quorum.describe}');
    print('group key:        ${quorum.groupKey.toBytes.toHex()}');
    print('P2WPKH address:   ${address.address}');

    final spendable = await node.fundFresh(
      provider,
      LocalWallet(index: 10, network: network),
      address,
      throwaway: mining.throwaway,
    );
    final utxos = withGroupKey(
      utxos: [largestUtxo(spendable)],
      groupKey: quorum.groupKey,
      address: address,
    );
    print('funded:           ${formatCoins(utxos.sumOfUtxosValue())} BTC');

    final txId = await spend(
      provider: provider,
      node: node,
      network: network,
      utxos: utxos,
      destination: destination.p2pkh,
      miningAddress: mining.confirm,
      quorum: quorum,
    );
    print('P2WPKH spend:     $txId');
    print('');
  }

  /// ---- 2. 3-of-3 quorum, P2SH-P2WPKH -------------------------------------
  {
    final quorum = buildQuorum(network: network, label: '3of3', parties: 3);
    final address = quorum.addresses['P2SH-P2WPKH']!;
    print('quorum:           ${quorum.describe}');
    print('group key:        ${quorum.groupKey.toBytes.toHex()}');
    print('P2SH-P2WPKH:      ${address.address}');

    final spendable = await node.fundFresh(
      provider,
      LocalWallet(index: 11, network: network),
      address,
      throwaway: mining.throwaway,
    );
    final utxos = withGroupKey(
      utxos: [largestUtxo(spendable)],
      groupKey: quorum.groupKey,
      address: address,
    );
    print('funded:           ${formatCoins(utxos.sumOfUtxosValue())} BTC');

    final txId = await spend(
      provider: provider,
      node: node,
      network: network,
      utxos: utxos,
      destination: destination.p2pkh,
      miningAddress: mining.confirm,
      quorum: quorum,
    );
    print('P2SH-P2WPKH spend:$txId');
    print('');
  }

  /// ---- 3. 2-of-3 quorum, P2PKH -------------------------------------------
  {
    final quorum = buildQuorum(network: network, label: '2of3pkh', threshold: 2);
    final address = quorum.addresses['P2PKH']!;
    print('quorum:           ${quorum.describe}');
    print('group key:        ${quorum.groupKey.toBytes.toHex()}');
    print('P2PKH address:    ${address.address}');

    final spendable = await node.fundFresh(
      provider,
      LocalWallet(index: 12, network: network),
      address,
      throwaway: mining.throwaway,
    );
    final utxos = withGroupKey(
      utxos: [largestUtxo(spendable)],
      groupKey: quorum.groupKey,
      address: address,
    );
    print('funded:           ${formatCoins(utxos.sumOfUtxosValue())} BTC');

    final txId = await spend(
      provider: provider,
      node: node,
      network: network,
      utxos: utxos,
      destination: destination.p2pkh,
      miningAddress: mining.confirm,
      quorum: quorum,
    );
    print('P2PKH spend:      $txId');
    print('');
  }

  /// ---- 4. Every signing subset works (2-of-3) -----------------------------
  {
    final quorum = buildQuorum(network: network, label: '2of3', threshold: 2);
    print('subset check (2-of-3):');
    final digest = QuickCrypto.keccak256Hash([...'subset'.codeUnits]);
    for (final subset in <List<int>>[
      [0, 1],
      [0, 2],
      [1, 2],
      [0],
    ]) {
      try {
        final sig = quorum.sign(digest, subset: subset);
        print('  $subset -> r=${sig.r.toHex().substring(0, 12)}...');
      } catch (e) {
        print('  $subset -> rejected (${e.runtimeType})');
      }
    }
    print('');
  }

  print(
    'destination balance: '
    '${formatCoins(await balanceOf(provider, destination.p2pkh))} BTC',
  );

  await service.close();
  print('');
  print('done.');
}