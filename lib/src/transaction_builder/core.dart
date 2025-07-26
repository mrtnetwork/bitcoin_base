import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/provider/models/utxo_details.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

typedef BitcoinSignerCallBack = String Function(
    List<int> trDigest, UtxoWithAddress utxo, String publicKey, int sighash);
typedef BitcoinSignerCallBackAsync = Future<String> Function(
    List<int> trDigest, UtxoWithAddress utxo, String publicKey, int sighash);

abstract class BasedBitcoinTransacationBuilder {
  final List<BitcoinBaseOutput> outPuts;
  final List<UtxoWithAddress> utxos;
  final BitcoinOrdering inputOrdering;
  final BitcoinOrdering outputOrdering;
  final BigInt fee;
  final BasedUtxoNetwork network;
  BasedBitcoinTransacationBuilder(
      {required List<BitcoinBaseOutput> outPuts,
      required List<UtxoWithAddress> utxos,
      required this.inputOrdering,
      required this.outputOrdering,
      required this.fee,
      required this.network})
      : outPuts = outPuts.immutable,
        utxos = utxos.immutable;

  BtcTransaction buildTransaction(BitcoinSignerCallBack sign);
  Future<BtcTransaction> buildTransactionAsync(BitcoinSignerCallBackAsync sign);

  /// how many signature we need for each publicKey (utxo)
  Map<String, int> getSignatureCount();
}

enum BitcoinOrdering { bip69, shuffle, none }
