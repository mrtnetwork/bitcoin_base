part of 'package:bitcoin_base/src/psbt/psbt_builder/builder.dart';

mixin PsbtOutputImpl on PsbtBuilderImpl {
  /// Adds a new transaction output to the PSBT.
  ///
  /// This method appends the given `PsbtTransactionOutput` to the transaction.
  ///
  /// Note: If any existing input contains a signature with an unmodifiable
  /// sighash (e.g., `SIGHASH_ALL`), or if an input is already finalized with
  /// an unmodifiable sighash, this operation will result in an error.
  void addOutput(PsbtTransactionOutput output) {
    _addNewTxOutput(output);
  }

  /// Updates an existing transaction output in the PSBT.
  ///
  /// Replaces the output at the specified index with a new `PsbtTransactionOutput`.
  ///
  /// Note: If any existing input contains a signature with an unmodifiable
  /// sighash (e.g., `SIGHASH_ALL`), or if an input is already finalized with
  /// an unmodifiable sighash, this operation will result in an error.
  void updateOutput(int index, PsbtTransactionOutput output) {
    _updateTxOutput(index, output);
  }

  /// Removes a transaction output from the PSBT.
  ///
  /// Deletes the output at the specified index.
  ///
  /// Note: If any existing input contains a signature with an unmodifiable
  /// sighash (e.g., `SIGHASH_ALL`), or if an input is already finalized with
  /// an unmodifiable sighash, this operation will result in an error.
  void removeOutput(int index) {
    _removeOutput(index);
  }
}
