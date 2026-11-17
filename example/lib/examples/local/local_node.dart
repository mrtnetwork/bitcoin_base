// Shared helpers for the local regtest bitcoin_base examples.
//
// Every example in this folder runs against two local regtest nodes (no
// public network): bitcoind RPC + a Fulcrum Electrum server per chain.
// Point the examples at your nodes with:
//   BITCOIN_CLI_PATH BITCOIN_DATA_DIR             (bitcoin)
//   BITCOIN_CASH_CLI_PATH BITCOIN_CASH_DATA_DIR   (bitcoin_cash)
// Funding is done by mining regtest blocks with `generatetoaddress`; the
// only server the library talks to is the local Fulcrum instance, through
// a plain-TCP Electrum client.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// Newline-delimited JSON-RPC client for the Electrum protocol.
class ElectrumTcpService with BitcoinServiceProvider {
  ElectrumTcpService._(this._socket, this._host, this._port) {
    _subscription = _socket.listen(
      _onData,
      onError: (_) => _failAll('connection error'),
      onDone: () => _failAll('connection closed'),
    );
  }

  final Socket _socket;
  final String _host;
  final int _port;
  StreamSubscription<List<int>>? _subscription;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final StringBuffer _buffer = StringBuffer();

  bool _closed = false;

  String get url => '$_host:$_port';

  static Future<ElectrumTcpService> connect(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final socket = await Socket.connect(host, port).timeout(timeout);
    return ElectrumTcpService._(socket, host, port);
  }

  void _failAll(String reason) {
    if (_closed) return;
    _closed = true;
    for (final entry in _pending.values) {
      if (!entry.isCompleted) entry.completeError(StateError(reason));
    }
    _pending.clear();
  }

  void _onData(List<int> data) {
    _buffer.write(utf8.decode(data, allowMalformed: true));
    while (true) {
      final text = _buffer.toString();
      final newline = text.indexOf('\n');
      if (newline < 0) break;
      final line = text.substring(0, newline).trim();
      _buffer.clear();
      _buffer.write(text.substring(newline + 1));
      if (line.isEmpty) continue;
      final decoded = StringUtils.tryToJson<Map<String, dynamic>>(line);
      if (decoded == null) continue;
      final id = decoded['id'];
      if (id == null) continue;
      final completer = _pending.remove(int.parse(id.toString()));
      if (completer == null || completer.isCompleted) continue;
      if (decoded['error'] != null) {
        completer.completeError(
          StateError('electrum error: ${decoded['error']}'),
        );
      } else {
        completer.complete(Map<String, dynamic>.from(decoded));
      }
    }
  }

  @override
  Future<BaseServiceResponse> doRequest(
    BitcoinRequestDetails params, {
    Duration? timeout,
  }) async {
    if (_closed) throw StateError('electrum connection is closed');
    final completer = Completer<Map<String, dynamic>>();
    _pending[params.requestID] = completer;
    try {
      _socket.add(params.encodeBody(protocol: ServiceProtocol.tcp) ?? []);
      final response = await completer.future.timeout(
        timeout ?? const Duration(seconds: 30),
      );
      return params.toResponse(response);
    } finally {
      _pending.remove(params.requestID);
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _failAll('closed');
    await _subscription?.cancel();
    _socket.destroy();
  }
}

/// Reads a required node path from the environment, failing fast with the
/// variable name when it is missing.
String _nodeEnv(String name) {
  final value = Platform.environment[name];
  if (value == null || value.isEmpty) {
    throw StateError(
      'Set $name to the local node binary/data dir to run the regtest examples.',
    );
  }
  return value;
}

/// A local bitcoind regtest node, used for funding (mining to an address).
class RegtestNode {
  const RegtestNode({
    required this.name,
    required this.cliPath,
    required this.dataDir,
    required this.electrumHost,
    required this.electrumPort,
    this.extraCliArgs = const [],
  });

  final String name;
  final String cliPath;
  final String dataDir;
  final String electrumHost;
  final int electrumPort;
  final List<String> extraCliArgs;

  static RegtestNode get bitcoin => RegtestNode(
        name: 'bitcoin',
        cliPath: _nodeEnv('BITCOIN_CLI_PATH'),
        dataDir: _nodeEnv('BITCOIN_DATA_DIR'),
        electrumHost: '127.0.0.1',
        electrumPort: 60401,
        extraCliArgs: [
          '-rpcport=19443',
          '-rpcuser=btcregtest',
          '-rpcpassword=82eaf231843b7a867171462dae10f67a623f93b2cc7cce5b',
        ],
      );

  static RegtestNode get bitcoinCash => RegtestNode(
        name: 'bitcoin_cash',
        cliPath: _nodeEnv('BITCOIN_CASH_CLI_PATH'),
        dataDir: _nodeEnv('BITCOIN_CASH_DATA_DIR'),
        electrumHost: '127.0.0.1',
        electrumPort: 50001,
      );

  Future<String> _rpc(List<String> args) async {
    final result = await Process.run(cliPath, [
      '-regtest',
      '-datadir=$dataDir',
      ...extraCliArgs,
      ...args,
    ]);
    final stdout = result.stdout.toString().trim();
    if (result.exitCode != 0) {
      throw StateError('$name RPC failed: ${result.stderr} $stdout');
    }
    return stdout;
  }

  Future<ElectrumTcpService> connectElectrum() {
    return ElectrumTcpService.connect(electrumHost, electrumPort);
  }

  Future<int> blockCount() async {
    return int.parse(await _rpc(['getblockcount']));
  }

  /// Mines one block to [address] to confirm a freshly broadcast transaction.
  Future<void> mineBlock(String address) async {
    await _rpc(['generatetoaddress', '1', address]);
  }

  /// Funds [address] with exactly one spendable coinbase output, and returns
  /// the UTXOs that can be spent.
  ///
  /// Mining 101 blocks straight to [address] would leave 101 UTXOs there, and a
  /// transaction spending all of them would be far too large. Instead the
  /// coinbase of a single block is paid to [address] and the following 100
  /// blocks are paid to [throwaway] so the output matures, leaving [address]
  /// with one spendable UTXO.
  ///
  /// An already-funded address is left alone, so re-running the examples does
  /// not keep burning regtest blocks (the subsidy halves every 150 blocks).
  Future<List<UtxoWithAddress>> fundFresh(
    BitcoinProvider provider,
    LocalWallet wallet,
    BitcoinNetworkAddress address, {
    required String throwaway,
    bool reuseExisting = true,
  }) async {
    if (reuseExisting) {
      final existing = await readUtxos(provider, wallet, address);
      if (existing.isNotEmpty) {
        final tip = await blockCount();
        final mature = existing
            .where(
              (utxo) =>
                  utxo.utxo.blockHeight > 0 &&
                  tip - utxo.utxo.blockHeight + 1 >= 101,
            )
            .toList();
        if (mature.isNotEmpty) return mature;
      }
    }
    await _rpc(['generatetoaddress', '1', address.address]);
    await _rpc(['generatetoaddress', '100', throwaway]);
    await waitForTip(provider, this);
    return waitForSpendableUtxos(
      provider,
      wallet,
      address,
      node: this,
    );
  }
}

/// A deterministic wallet for the regtest examples.
///
/// Keys come from BIP-32 seed `7a7a…7a` (32 bytes) at `m/44'/1'/0'/0/[index]`
/// (coin type 1 = testnet), so every run uses the same addresses.
class LocalWallet {
  LocalWallet._(this.privateKey, this.network, this.index);

  final ECPrivate privateKey;
  final BasedUtxoNetwork network;
  final int index;

  static final Bip32Slip10Secp256k1 _master = Bip32Slip10Secp256k1.fromSeed(
    BytesUtils.fromHexString('7a' * 32),
  );

  factory LocalWallet({required int index, required BasedUtxoNetwork network}) {
    final child = _master.derivePath("m/44'/1'/0'/0/$index");
    return LocalWallet._(
      ECPrivate.fromBytes(child.privateKey.toBytes()),
      network,
      index,
    );
  }

  ECPublic get publicKey => privateKey.getPublic();

  /// Every address type supported by [network], in declaration order.
  List<BitcoinNetworkAddress> get addresses {
    return network.supportedAddress.map(addressFor).toList();
  }

  BitcoinNetworkAddress addressFor(BitcoinAddressType type) {
    return publicKey.generateNetworkAddress(
      addressType: type,
      encoding: CryptoKeyEncoding.base,
      network: network,
    );
  }

  BitcoinNetworkAddress get p2pkh => addressFor(P2pkhAddressType.p2pkh);

  /// UTXOs of [type] owned by this wallet.
  Future<List<UtxoWithAddress>> utxos(
    BitcoinProvider provider,
    BitcoinAddressType type, {
    bool includeTokens = false,
  }) async {
    return readUtxos(provider, this, addressFor(type), includeTokens);
  }

  Future<BigInt> balance(
    BitcoinProvider provider,
    BitcoinAddressType type,
  ) async {
    return balanceOf(provider, addressFor(type));
  }
}

/// Reads the UTXOs of [address] through the Electrum server.
Future<List<UtxoWithAddress>> readUtxos(
  BitcoinProvider provider,
  LocalWallet wallet,
  BitcoinNetworkAddress address, [
  bool includeTokens = false,
]) async {
  final electrumUtxos = await provider.request(
    ElectrumRequestScriptHashListUnspent(
      scriptHash: address.pubKeyHash(),
      includeTokens: includeTokens,
    ),
  );
  final base = address.baseAddress;
  return electrumUtxos.map((utxo) {
    return UtxoWithAddress(
      utxo: utxo.toUtxo(base.type),
      ownerDetails: UtxoAddressDetails(
        publicKey: wallet.publicKey.toHex(),
        address: base,
      ),
    );
  }).toList();
}

/// Confirmed + unconfirmed balance of [address] in satoshis.
Future<BigInt> balanceOf(
  BitcoinProvider provider,
  BitcoinNetworkAddress address,
) async {
  final result = await provider.request(
    ElectrumRequestGetScriptHashBalance(scriptHash: address.pubKeyHash()),
  );
  final confirmed = BigintUtils.tryParse(result['confirmed']) ?? BigInt.zero;
  final unconfirmed =
      BigintUtils.tryParse(result['unconfirmed']) ?? BigInt.zero;
  return confirmed + unconfirmed;
}

/// Current chain tip height according to the Electrum server.
Future<int> currentTip(BitcoinProvider provider) async {
  final header = await provider.request(ElectrumRequestHeaderSubscribe());
  return header.block;
}

/// Polls until the Electrum server has caught up with bitcoind's tip.
Future<int> waitForTip(
  BitcoinProvider provider,
  RegtestNode node, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    final nodeTip = await node.blockCount();
    final electrumTip = await currentTip(provider);
    if (electrumTip >= nodeTip) return electrumTip;
    if (DateTime.now().isAfter(deadline)) {
      throw StateError(
        'electrum tip $electrumTip did not reach node tip $nodeTip',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}

/// Polls until [address] has at least one UTXO.
Future<List<UtxoWithAddress>> waitForUtxos(
  BitcoinProvider provider,
  LocalWallet wallet,
  BitcoinNetworkAddress address, {
  Duration timeout = const Duration(seconds: 60),
  bool includeTokens = false,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    final utxos = await readUtxos(provider, wallet, address, includeTokens);
    if (utxos.isNotEmpty) return utxos;
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('no utxo for ${address.address} after $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}

/// Polls until [address] has a spendable (mature) UTXO.
///
/// Regtest coinbase outputs need 100 confirmations. The depth is measured
/// against bitcoind's own height because Fulcrum's tip can lag by a block,
/// which would otherwise mis-age a 1-deep coinbase.
Future<List<UtxoWithAddress>> waitForSpendableUtxos(
  BitcoinProvider provider,
  LocalWallet wallet,
  BitcoinNetworkAddress address, {
  RegtestNode? node,
  int requiredConfirmations = 101,
  Duration timeout = const Duration(seconds: 90),
  bool includeTokens = false,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    final tip =
        node == null ? await currentTip(provider) : await node.blockCount();
    final utxos = await readUtxos(
      provider,
      wallet,
      address,
      includeTokens,
    );
    final mature = utxos
        .where(
          (utxo) =>
              utxo.utxo.blockHeight > 0 &&
              tip - utxo.utxo.blockHeight + 1 >= requiredConfirmations,
        )
        .toList();
    if (mature.isNotEmpty) return mature;
    if (DateTime.now().isAfter(deadline)) {
      throw StateError(
        'no spendable utxo for ${address.address} after $timeout',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}

/// Picks the largest UTXO from [utxos], which keeps example transactions small
/// and makes the examples safe to re-run on an address that already has change.
UtxoWithAddress largestUtxo(List<UtxoWithAddress> utxos) {
  if (utxos.isEmpty) {
    throw StateError('no utxo to spend');
  }
  return utxos.reduce(
    (a, b) => a.utxo.value.compareTo(b.utxo.value) >= 0 ? a : b,
  );
}

/// Broadcasts [transaction], mines a block, and waits for Fulcrum to index it.
Future<String> broadcastAndConfirm(
  BitcoinProvider provider,
  RegtestNode node,
  BtcTransaction transaction,
  String miningAddress,
) async {
  final txId = await provider.request(
    ElectrumRequestBroadCastTransaction(transactionRaw: transaction.toHex()),
  );
  await node.mineBlock(miningAddress);
  await waitForTip(provider, node);
  await Future<void>.delayed(const Duration(milliseconds: 200));
  return txId;
}

/// A throwaway address used to receive the coinbase of filler blocks, plus a
/// separate address for blocks that confirm the examples' own transactions.
class Mining {
  Mining(BasedUtxoNetwork network, {int seed = 200})
      : throwaway = LocalWallet(index: seed, network: network).p2pkh.address,
        confirm = LocalWallet(index: seed + 1, network: network).p2pkh.address;

  final String throwaway;
  final String confirm;
}

/// Standard fee used by the examples.
final BigInt exampleFee = BigInt.from(3000);

/// Formats satoshis as a BTC/BCH decimal string.
String formatCoins(BigInt satoshis) {
  return BtcUtils.toBtc(satoshis);
}
