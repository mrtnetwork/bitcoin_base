import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/transaction.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/provider/api/models/api_models.dart';
import 'package:bitcoin_base/src/provider/block_cypher/block_cypher.dart';
import 'package:bitcoin_base/src/provider/electrum/electrum.dart';
import 'package:bitcoin_base/src/provider/mempool/mempool.dart';
import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:bitcoin_base/src/provider/types/types.dart';
import 'package:bitcoin_base/src/psbt/psbt_builder/types/types.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// Quick client API: one method per top request, each mapped across the
/// available providers and returning a single unified result type.
///
/// Design follows `TonQuickClientApi` (ton_dart): consumers depend on this
/// mixin instead of raw `BitcoinProvider` request classes. There is exactly
/// one [provider]; [availableProviders] selects which backend(s) each call
/// may use (first match wins, no error fallback). [network] is the chain the
/// client talks to (address encoding, mainnet checks, BCH guards).
///
/// Wallet parity: every top method of the wallet `BitcoinNetworkClient` is
/// ported here with base-native types (`BasedUtxoNetwork` instead of wallet
/// `WalletBitcoinNetwork`, [BitcoinTxStatus]/[BitcoinBlockTransactionInfo]
/// instead of wallet status types). Wallet/swap clients are intentionally not
/// migrated; they can adopt this mixin later.
mixin BitcoinQuickClientApi {
  /// Single provider serving every call.
  IProvider<IServiceProvider, IServiceRequestParams> get provider;

  /// Chain this client talks to.
  BasedUtxoNetwork get network;

  /// Backend preference order.
  List<BitcoinProviderApi> get availableProviders;

  Future<T> mapProviderApi<T>({
    required Future<T> Function() onElectrum,
    required Future<T> Function() onMempool,
    required Future<T> Function() onBlockCypher,
  }) async {
    if (availableProviders.contains(BitcoinProviderApi.electrum)) {
      return onElectrum();
    }
    if (availableProviders.contains(BitcoinProviderApi.mempool)) {
      return onMempool();
    }
    if (availableProviders.contains(BitcoinProviderApi.blockCypher)) {
      return onBlockCypher();
    }
    throw BuError(
      DefaultErrorType.invalidState,
      'No available provider.',
      details: {
        'availableProviders': availableProviders.map((e) => e.name).join(','),
      },
    );
  }

  /// UTXOs of [address]. [includeTokens] only works on electrum + BCH.
  Future<List<UtxoWithAddress>> readUtxos(
    UtxoAddressDetails address, [
    bool includeTokens = false,
  ]) async {
    if (includeTokens) {
      if (network is! BitcoinCashNetwork) {
        throw BuError(
          DefaultErrorType.unsupported,
          'Include tokens is only supported on bitcoin cash network.',
        );
      }
      if (!availableProviders.contains(BitcoinProviderApi.electrum)) {
        throw BuError(
          DefaultErrorType.unsupported,
          'Include tokens is only supported by electrum provider.',
        );
      }
    }
    final addr = address.address.toAddress(network);
    return mapProviderApi(
      onElectrum: () async {
        final utxos = await provider.request(
          ElectrumRequestScriptHashListUnspent(
            scriptHash: address.address.pubKeyHash(),
            includeTokens: includeTokens,
          ),
        );
        return utxos
            .where((element) => (!includeTokens) ? element.token == null : true)
            .map<UtxoWithAddress>(
              (e) => UtxoWithAddress(
                utxo: e.toUtxo(address.address.type),
                ownerDetails: address,
              ),
            )
            .toList();
      },
      onMempool:
          () => provider.request(
            MempoolRequestGetAccountUtxos(owner: address, address: addr),
          ),
      onBlockCypher:
          () => provider.request(
            BlockCypherRequestGetAccountUtxos(owner: address, address: addr),
          ),
    );
  }

  /// Total spendable balance of [address] (sum of UTXO values).
  Future<BigInt> getAccountBalance(BitcoinBaseAddress address) async {
    final owner = UtxoAddressDetails.watchOnly(address);
    final utxos = await readUtxos(owner);
    return utxos.sumOfUtxosValue();
  }

  /// UTXOs with coinbase flags resolved. Known [existsUtxos] keep their stored
  /// flag; confirmed new UTXOs fetch their verbose transaction once per txid
  /// (same batching as the wallet client).
  Future<BitcoinAccountUtxosInfo> readAddressUtxos({
    required UtxoAddressDetails address,
    required List<BitcoinUtxo> existsUtxos,
    bool includeTokens = false,
  }) async {
    final List<UtxoWithAddress> newUtxos = [];
    final Map<String, ElectrumVerbosTxResponse> transactions = {};
    final utxos = await readUtxos(address, includeTokens);
    for (final i in utxos) {
      BitcoinUtxo? exist;
      for (final e in existsUtxos) {
        if (e == i.utxo) {
          exist = e;
          break;
        }
      }
      if (exist != null) {
        newUtxos.add(
          UtxoWithAddress(
            utxo: i.utxo.copyWith(coinbase: exist.coinbase),
            ownerDetails: address,
          ),
        );
        continue;
      }
      if (i.utxo.blockHeight <= 0) {
        newUtxos.add(
          UtxoWithAddress(
            utxo: i.utxo.copyWith(coinbase: false),
            ownerDetails: i.ownerDetails,
          ),
        );
        continue;
      }
      final tx =
          transactions[i.utxo.txHash] ??= await getVerboseTx(i.utxo.txHash);
      newUtxos.add(
        UtxoWithAddress(
          utxo: i.utxo.copyWith(coinbase: tx.isCoinbase),
          ownerDetails: i.ownerDetails,
        ),
      );
    }
    return BitcoinAccountUtxosInfo(
      utxos: newUtxos,
      fetchedTransaction: transactions,
    );
  }

  /// Fee rates in satoshis per kilobyte. Electrum answers per-kb estimates for
  /// 2/5/10 blocks (high/medium/low); mempool and blockCypher serve their
  /// dedicated fee endpoint.
  Future<BitcoinFeeRate?> getFeeRate() {
    return mapProviderApi(
      onElectrum: () async {
        final BigInt? high = await provider.request(
          ElectrumRequestEstimateFee(numberOfBlock: 2),
        );
        if (high == null) return null;
        final BigInt? medium = await provider.request(
          ElectrumRequestEstimateFee(numberOfBlock: 5),
        );
        final BigInt? low = await provider.request(
          ElectrumRequestEstimateFee(numberOfBlock: 10),
        );
        return BitcoinFeeRate(
          high: high,
          low: low ?? high,
          medium: medium ?? high,
        );
      },
      onMempool:
          () => provider.request(const MempoolRequestGetNetworkFeeRate()),
      onBlockCypher:
          () => provider.request(const BlockCypherRequestGetNetworkFeeRate()),
    );
  }

  /// Estimated fee per byte (medium rate / 1024). Returns 1.1 on testnets when
  /// the backend has no estimate; throws on mainnet (wallet parity).
  Future<BigRational> estimateFeePerByte() async {
    final fee = await getFeeRate();
    if (fee == null) {
      if (!network.isMainnet) {
        return BigRational.parseDecimal('1.1');
      }
      throw BuError(
        DefaultErrorType.network,
        'Failed to fetch network fee rate.',
      );
    }
    return BigRational(fee.medium) / BigRational.from(1024);
  }

  /// Broadcasts [transaction], returning the txid. Electrum answers the txid
  /// on success; anything else falls back to the locally computed txid
  /// (wallet parity).
  Future<String> sendTransaction(BtcTransaction transaction) async {
    final digest = transaction.serialize();
    return mapProviderApi(
      onElectrum: () async {
        final result = await provider.request(
          ElectrumRequestBroadCastTransaction(transactionRaw: digest),
        );
        if (StringUtils.isHexBytes(
          result,
          lengthInBytes: QuickCrypto.sha256DigestSize,
        )) {
          return result;
        }
        return transaction.txId();
      },
      onMempool:
          () => provider.request(MempoolRequestSendRawTransaction(digest)),
      onBlockCypher:
          () => provider.request(BlockCypherRequestSendRawTransaction(digest)),
    );
  }

  /// Raw transaction by [txId].
  Future<BtcTransaction> getTx(String txId) {
    return mapProviderApi(
      onElectrum:
          () => provider.request(ElectrumRequestGetRawTransaction(txId)),
      onMempool: () => provider.request(MempoolRequestGetRawTransaction(txId)),
      onBlockCypher:
          () => provider.request(BlockCypherRequestGetRawTransaction(txId)),
    );
  }

  /// Verbose transaction by [txId], mapped to the unified
  /// [ElectrumVerbosTxResponse] shape on every backend (wallet parity).
  Future<ElectrumVerbosTxResponse> getVerboseTx(String txId) {
    return mapProviderApi(
      onElectrum:
          () => provider.request(ElectrumRequestGetVerboseTransaction(txId)),
      onMempool: () async {
        final tx = await provider.request(MempoolRequestGetTransaction(txId));
        return ElectrumVerbosTxResponse(
          txId: txId,
          version: tx.version,
          size: tx.size,
          vsize: tx.size,
          weight: tx.weight,
          locktime: tx.locktime,
          blockhash: tx.status.blockHash,
          blocktime: tx.status.blockTime,
          confirmations: tx.status.confirmed ? 1 : null,
          isCoinbase: tx.isCoinbse(),
        );
      },
      onBlockCypher: () async {
        final tx = await provider.request(
          BlockCypherRequestGetTransaction(txId),
        );
        return ElectrumVerbosTxResponse(
          txId: txId,
          version: tx.ver,
          size: tx.size,
          vsize: tx.vSize,
          weight: tx.size,
          locktime: 0,
          blockhash: tx.hash,
          blocktime:
              tx.received == null
                  ? null
                  : tx.received!.millisecondsSinceEpoch ~/ 1000,
          confirmations: tx.confirmations,
          isCoinbase: tx.isCoinbase(),
        );
      },
    );
  }

  /// Genesis block hash of the connected chain.
  Future<String> genesisHash() {
    return mapProviderApi(
      onElectrum: () async {
        final header = await provider.request(
          ElectrumRequestBlockHeader(startHeight: 0, cpHeight: 0),
        );
        return BytesUtils.toHexString(
          QuickCrypto.sha256DoubleHash(
            BytesUtils.fromHexString(header),
          ).reversed.toList(),
        );
      },
      onMempool:
          () => provider.request(const MempoolRequestGetBlockHashByHeight(0)),
      onBlockCypher:
          () =>
              provider.request(const BlockCypherRequestGetBlockHashByHeight(0)),
    );
  }

  /// Latest block height.
  Future<int> getLatestBlockHeight() {
    return mapProviderApi(
      onElectrum: () async {
        final block = await provider.request(ElectrumRequestHeaderSubscribe());
        return block.block;
      },
      onMempool:
          () => provider.request(const MempoolRequestLatestBlockHeight()),
      onBlockCypher:
          () => provider.request(const BlockCypherRequestLatestBlockHeight()),
    );
  }

  /// Spendable UTXOs of [addresses] with the full previous transactions
  /// attached ([PsbtUtxo]), filtered to confirmed outputs (wallet parity).
  Future<List<PsbtUtxo>> getAccountsUtxos(
    List<BitcoinSpenderAddress> addresses,
  ) async {
    final utxos = await getAccountsUtxoWithMempool(addresses);
    return utxos.where((e) {
      final height = e.utxo.blockHeight;
      return height > 0;
    }).toList();
  }

  /// All UTXOs of [addresses] (including mempool) with previous transactions.
  Future<List<PsbtUtxo>> getAccountsUtxoWithMempool(
    List<BitcoinSpenderAddress> addresses,
  ) async {
    final accountsUtxos = await Future.wait(
      addresses.map(
        (e) => readUtxos(UtxoAddressDetails.watchOnly(e.address.baseAddress)),
      ),
    );
    final accountsPsbtUtxos = await Future.wait(
      List.generate(accountsUtxos.length, (i) async {
        final request = addresses[i];
        final accountUtxos = accountsUtxos[i];
        final rawTxs = await Future.wait(
          accountUtxos.map((e) => getTx(e.utxo.txHash)).toList(),
        );
        return List.generate(accountUtxos.length, (index) {
          return PsbtUtxo(
            utxo: accountUtxos[index].utxo,
            p2shRedeemScript: request.p2shRedeemScript,
            p2wshWitnessScript: request.witnessScript,
            tx: rawTxs[index],
            scriptPubKey: request.address.toScriptPubKey(),
            xOnlyOrInternalPubKey: request.taprootInternal,
          );
        });
      }),
    );
    return accountsPsbtUtxos.expand((e) => e).toList();
  }
}
