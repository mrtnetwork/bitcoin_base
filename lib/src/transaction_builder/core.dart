import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/provider/models/utxo_details.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

typedef BitcoinSignerCallBack =
    String Function(
      List<int> trDigest,
      UtxoWithAddress utxo,
      String publicKey,
      int sighash,
    );
typedef BitcoinSignerCallBackAsync =
    Future<String> Function(
      List<int> trDigest,
      UtxoWithAddress utxo,
      String publicKey,
      int sighash,
    );

/// Signer callback for multi-signature inputs.
///
/// Unlike [BitcoinSignerCallBack], this callback is called **once per
/// multi-signature input** (and not once per signer) and it returns the
/// signatures of all the signers at once, keyed by the signer's public key.
///
/// A signer that is not present in the returned map (or that has an empty
/// signature) is considered as "not signed".
typedef BitcoinMultiSigSignerCallBack =
    Map<String, String> Function(
      List<int> trDigest,
      UtxoWithAddress utxo,
      List<String> publicKeys,
      int sighash,
    );

/// Asynchronous version of [BitcoinMultiSigSignerCallBack].
typedef BitcoinMultiSigSignerCallBackAsync =
    Future<Map<String, String>> Function(
      List<int> trDigest,
      UtxoWithAddress utxo,
      List<String> publicKeys,
      int sighash,
    );

abstract class BasedBitcoinTransacationBuilder {
  final List<BitcoinBaseOutput> outPuts;
  final List<UtxoWithAddress> utxos;
  final BitcoinOrdering inputOrdering;
  final BitcoinOrdering outputOrdering;
  final BigInt fee;
  final BasedUtxoNetwork network;
  BasedBitcoinTransacationBuilder({
    required List<BitcoinBaseOutput> outPuts,
    required List<UtxoWithAddress> utxos,
    required this.inputOrdering,
    required this.outputOrdering,
    required this.fee,
    required this.network,
  }) : outPuts = outPuts.immutable,
       utxos = utxos.immutable;

  /// Builds and signs the transaction.
  ///
  /// [sign] is called for each single-signature input.
  ///
  /// [multiSigSign] is called once for each multi-signature input and must
  /// return the signatures of the signers keyed by their public key. When it is
  /// `null` the legacy behaviour is used and [sign] is called once for each
  /// signer of the multi-signature address.
  BtcTransaction buildTransaction(
    BitcoinSignerCallBack sign, {
    BitcoinMultiSigSignerCallBack? multiSigSign,
  });

  /// Builds and signs the transaction asynchronously.
  ///
  /// [sign] is called for each single-signature input.
  ///
  /// [multiSigSign] is called once for each multi-signature input and must
  /// return the signatures of the signers keyed by their public key. When it is
  /// `null` the legacy behaviour is used and [sign] is called once for each
  /// signer of the multi-signature address.
  Future<BtcTransaction> buildTransactionAsync(
    BitcoinSignerCallBackAsync sign, {
    BitcoinMultiSigSignerCallBackAsync? multiSigSign,
  });

  /// how many signature we need for each publicKey (utxo)
  Map<String, int> getSignatureCount();
}

enum BitcoinOrdering { bip69, shuffle, none }
