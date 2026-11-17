import 'package:bitcoin_base/src/provider/models/utxo_details.dart';
import 'package:bitcoin_base/src/provider/models/electrum/models.dart';

/// Confirmation info for a transaction (wallet `BitcoinBlockTransactionInfo` parity).
class BitcoinBlockTransactionInfo {
  final bool confirmed;
  final DateTime? blockTime;
  final String txId;
  const BitcoinBlockTransactionInfo({
    required this.confirmed,
    required this.blockTime,
    required this.txId,
  });
}

/// UTXOs of an address plus the verbose transactions fetched while resolving
/// coinbase flags (wallet `BitcoinAccountUtxosInfo` parity).
class BitcoinAccountUtxosInfo {
  final List<UtxoWithAddress> utxos;
  final Map<String, ElectrumVerbosTxResponse> fetchedTransaction;
  const BitcoinAccountUtxosInfo({
    required this.utxos,
    required this.fetchedTransaction,
  });
}
