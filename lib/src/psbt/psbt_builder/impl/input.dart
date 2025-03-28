part of 'package:bitcoin_base/src/psbt/psbt_builder/builder.dart';

mixin PsbtInputImpl on PsbtBuilderImpl {
  /// Replaces the current input at the specified index.
  ///
  /// If the transaction ID (`txId`), transaction index (`txIndex`),
  /// or sequence number changes, this will update the input accordingly.
  ///
  /// Note: If any existing input contains a signature with an unmodifiable
  /// sighash (e.g., `SIGHASH_ALL`), or if an input is already finalized with
  /// an unmodifiable sighash, this operation will result in an error.
  void updateInput(int index, PsbtTransactionInput input) {
    _updateTxInput(index, input);
  }

  /// Remove the current input at the specified index.
  ///
  /// Note: If any existing input contains a signature with an unmodifiable
  /// sighash (e.g., `SIGHASH_ALL`), or if an input is already finalized with
  /// an unmodifiable sighash, this operation will result in an error.
  void removeInput(int index) {
    _removeTxInput(index);
  }

  /// Adds a UTXO as an input to the PSBT.
  ///
  /// This method converts the given `PsbtUtxo` into a `PsbtTransactionInput`
  /// and adds it to the transaction.
  ///
  /// Note: If any existing input contains a signature with an unmodifiable
  /// sighash (e.g., `SIGHASH_ALL`), or if an input is already finalized with
  /// an unmodifiable sighash, this operation will result in an error.
  void addUtxo(PsbtUtxo psbtUtxo) {
    addInput(PsbtTransactionInput.fromUtxo(psbtUtxo));
  }

  /// Adds a new transaction input to the PSBT.
  ///
  /// Note: If any existing input contains a signature with an unmodifiable
  /// sighash (e.g., `SIGHASH_ALL`), or if an input is already finalized with
  /// an unmodifiable sighash, this operation will result in an error.
  void addInput(PsbtTransactionInput input) {
    _addNewTxInput(input);
  }

  /// Adds multiple UTXOs as inputs to the PSBT.
  ///
  /// This method converts each `PsbtUtxo` in the list into a `PsbtTransactionInput`
  /// and adds it to the transaction.
  ///
  /// Note: If any existing input contains a signature with an unmodifiable
  /// sighash (e.g., `SIGHASH_ALL`), or if an input is already finalized with
  /// an unmodifiable sighash, this operation will result in an error.
  void addUtxos(List<PsbtUtxo> psbtUtxos) {
    for (final i in psbtUtxos) {
      addUtxo(i);
    }
  }

  /// Adds a MuSig2 public nonce to the specified input in the PSBT.
  ///
  /// This method associates a `PsbtInputMuSig2PublicNonce` with the input at
  /// the given index, which is required for the MuSig2 signing process.
  void musig2AddPubKeyNonce(int index, PsbtInputMuSig2PublicNonce pubKeyNonce) {
    _musig2AddPubKeyNonce(index, pubKeyNonce);
  }

  /// Finalizes the specified input in the PSBT.
  ///
  /// This method attempts to finalize the input at the given index.
  ///
  /// Note:
  /// - If the input is already finalized, this method does nothing.
  /// - If you are spending a custom script, you must provide an
  ///   `onFinalizeInput` callback to handle the finalization manually;
  ///   otherwise, the operation will fail.
  void finalizeInput(int index, {ONFINALIZEINPUT? onFinalizeInput}) {
    if (indexFinalized(index)) return;
    final txInputs = this.txInputs();
    PsbtFinalizeResponse? userFinalizedInput;
    if (onFinalizeInput != null) {
      final params = _generateFinalizeParams(index: index, txInputs: txInputs);
      userFinalizedInput = onFinalizeInput(params);
    }

    final inputs = PsbtUtils.finalizeInput(
        psbt: _psbt,
        index: index,
        txInputs: txInputs,
        userFinalizedInput: userFinalizedInput,
        unsignedTx: buildUnsignedTransaction());
    _psbt.input.updateInputs(index, inputs.toPsbtInput());
    _cleanFinalizedInput(index);
  }

  /// Finalizes the specified input in the PSBT.
  ///
  /// This method attempts to finalize the input at the given index.
  ///
  /// Note:
  /// - If the input is already finalized, this method does nothing.
  /// - If you are spending a custom script, you must provide an
  ///   `onFinalizeInput` callback to handle the finalization manually;
  ///   otherwise, the operation will fail.
  Future<void> finalizeInputAsync(int index,
      {ONFINALIZEINPUTASYNC? onFinalizeInput}) async {
    if (indexFinalized(index)) return;
    final txInputs = this.txInputs();
    PsbtFinalizeResponse? userFinalizedInput;
    if (onFinalizeInput != null) {
      final params = _generateFinalizeParams(index: index, txInputs: txInputs);
      userFinalizedInput = await onFinalizeInput(params);
    }
    final inputs = PsbtUtils.finalizeInput(
        psbt: _psbt,
        index: index,
        txInputs: txInputs,
        userFinalizedInput: userFinalizedInput,
        unsignedTx: buildUnsignedTransaction());
    _psbt.input.updateInputs(index, inputs.toPsbtInput());
    _cleanFinalizedInput(index);
  }

  /// Finalizes all inputs in the PSBT and returns the finalized transaction.
  ///
  /// This method attempts to finalize each input in the PSBT.
  ///
  /// Note:
  /// - If an input is already finalized, it will be skipped.
  /// - If any input requires custom script handling, you must provide an
  ///   `onFinalizeInput` callback to finalize it manually; otherwise,
  ///   the operation may fail.
  ///
  /// Returns the finalized [BtcTransaction] if successful.
  BtcTransaction finalizeAll({ONFINALIZEINPUT? onFinalizeInput}) {
    for (int i = 0; i < _psbt.input.entries.length; i++) {
      finalizeInput(i, onFinalizeInput: onFinalizeInput);
    }
    return _finalizeInputTx();
  }

  /// Finalizes all inputs in the PSBT and returns the finalized transaction.
  ///
  /// This method attempts to finalize each input in the PSBT.
  ///
  /// Note:
  /// - If an input is already finalized, it will be skipped.
  /// - If any input requires custom script handling, you must provide an
  ///   `onFinalizeInput` callback to finalize it manually; otherwise,
  ///   the operation may fail.
  ///
  /// Returns the finalized [BtcTransaction] if successful.
  Future<BtcTransaction> finalizeAllAsync(
      {ONFINALIZEINPUTASYNC? onFinalizeInput}) async {
    for (int i = 0; i < _psbt.input.entries.length; i++) {
      if (indexFinalized(i)) continue;
      await finalizeInputAsync(i, onFinalizeInput: onFinalizeInput);
    }
    return _finalizeInputTx();
  }

  PsbtFinalizeParams _generateFinalizeParams(
      {required int index, required List<TxInput> txInputs}) {
    final inputData = psbtInput(index);
    return PsbtFinalizeParams(index: index, inputData: inputData);
  }

  void _cleanFinalizedInput(int index) {
    if (indexFinalized(index)) {
      _psbt.input.removeInputKeys(index, [
        PsbtInputTypes.bip32DerivationPath,
        PsbtInputTypes.taprootBip32Derivation,
        PsbtInputTypes.partialSignature,
        PsbtInputTypes.taprootScriptSpentSignature,
        PsbtInputTypes.redeemScript,
        PsbtInputTypes.taprootLeafScript,
        PsbtInputTypes.witnessScript,
        PsbtInputTypes.taprootMerkleRoot,
        PsbtInputTypes.taprootInternalKey,
        PsbtInputTypes.taprootLeafScript,
        PsbtInputTypes.taprootKeySpentSignature,
      ]);
    }
  }

  BtcTransaction _finalizeInputTx() {
    BtcTransaction finalTx = buildUnsignedTransaction();
    List<TxWitnessInput> witnesses = [];
    for (int i = 0; i < _psbt.input.entries.length; i++) {
      final input = finalTx.inputs[i];
      final finalizedScriptSig = _psbt.input
          .getInput<PsbtInputFinalizedScriptSig>(
              i, PsbtInputTypes.finalizedScriptSig);
      final finalizedWitness = _psbt.input
          .getInput<PsbtInputFinalizedScriptWitness>(
              i, PsbtInputTypes.finalizedWitness);
      if (finalizedScriptSig != null) {
        input.scriptSig = finalizedScriptSig.finalizedScriptSig;
      }
      if (finalizedWitness != null) {
        witnesses.add(finalizedWitness.finalizedScriptWitness);
      }
    }
    if (witnesses.isNotEmpty) {
      finalTx = finalTx.copyWith(witnesses: witnesses);
    }
    return finalTx;
  }
}
