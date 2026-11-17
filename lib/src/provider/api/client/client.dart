import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/provider/api/api/api.dart';
import 'package:bitcoin_base/src/provider/types/types.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// Quick client: high-level provider calls with unified result types.
///
/// There is exactly one [provider]; [availableProviders] selects which
/// backend(s) each call may use (first match wins, no error fallback).
/// See [BitcoinQuickClientApi] (design follows `TonQuickClient`).
abstract class BitcoinQuickClient with BitcoinQuickClientApi {
  const BitcoinQuickClient();
}

class DefaultBitcoinQuickClient extends BitcoinQuickClient {
  @override
  final IProvider<IServiceProvider, IServiceRequestParams> provider;

  @override
  final BasedUtxoNetwork network;

  /// Backend preference order (electrum-first by default).
  @override
  final List<BitcoinProviderApi> availableProviders;

  const DefaultBitcoinQuickClient({
    required this.provider,
    required this.network,
    this.availableProviders = const [
      BitcoinProviderApi.electrum,
      BitcoinProviderApi.mempool,
      BitcoinProviderApi.blockCypher,
    ],
  });
}
