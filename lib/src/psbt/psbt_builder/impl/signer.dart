part of 'package:bitcoin_base/src/psbt/psbt_builder/builder.dart';

mixin PsbtSignerImpl on PsbtBuilderImpl {
  void _checkFinalizeInput(int index) {
    if (PsbtUtils.finalized(index: index, input: _psbt.input)) {
      throw DartBitcoinPluginException(
          "Input at index $index is already finalized and cannot be modified.");
    }
  }

  /// Signs the specified input in the PSBT using the provided signer function.
  ///
  /// This method signs the input at the given index using the `signer` callback.
  ///
  /// Note:
  /// - If the input is already finalized, this method will fail and throw an error.
  /// - The `signer` function will receive all relevant transaction and input data.
  /// - The `signer` function should return one or multiple `PsbtSigner` or `PsbtMusig2Signer`
  ///   objects, depending on the script's signature requirements.
  ///
  /// - If any required signer’s public key is not found in the script, signing will fail.
  /// - If any signature does not pass verification, signing will fail.
  /// - If spending a Taproot leaf script with multiple possible leaf scripts,
  ///   you must determine the correct tapleafHash; otherwise, signing will fail.
  ///
  /// Throws an error if signing fails for any reason.
  void signInput({required ONBTCSIGNER signer, required int index}) {
    _checkFinalizeInput(index);
    final txInputs = this.txInputs();
    final params = PsbtUtils.getPsbtInputInfo(
        psbt: _psbt, inputIndex: index, txInputs: txInputs);
    final request = PsbtSignerParams(
        scriptPubKey: params.scriptPubKey,
        index: index,
        inputData: psbtInput(index),
        address: params.address);
    final btcSigner = signer(request);
    if (btcSigner == null || btcSigner.signers.isEmpty) return;
    for (final signer in btcSigner.signers) {
      final digest = PsbtUtils.generateInputTransactionDigest(
          index: index,
          unsignedTx: buildUnsignedTransaction(),
          params: params,
          input: _psbt.input,
          tapleafHash: btcSigner.tapleafHash,
          sighashType: btcSigner.sighash,
          psbt: _psbt);
      final signature = signer.btcSignInput(digest.createRequest(signer));
      final psbtSignature = digest.createSignature(signature, signer);
      final sighash = digest.getPsbtSigHash();
      _psbt.input
          .updateInputs(index, [psbtSignature, if (sighash != null) sighash]);
    }
  }

  /// Signs all inputs in the PSBT using the provided signer function.
  ///
  /// This method iterates through all inputs and attempts to sign each one using
  /// the `signer` callback.
  ///
  /// Note:
  /// - If the input is already finalized, this method will fail and throw an error.
  /// - The `signer` function will receive all relevant transaction and input data.
  /// - The `signer` function should return one or multiple `PsbtSigner` or `PsbtMusig2Signer`
  ///   objects, depending on the script's signature requirements.
  ///
  /// - If any required signer’s public key is not found in the script, signing will fail.
  /// - If any signature does not pass verification, signing will fail.
  /// - If spending a Taproot leaf script with multiple possible leaf scripts,
  ///   you must determine the correct tapleafHash; otherwise, signing will fail.
  ///
  /// Throws an error if signing fails for any reason.
  void signAllInput(ONBTCSIGNER signer) {
    for (int i = 0; i < _psbt.input.entries.length; i++) {
      if (indexFinalized(i)) continue;
      signInput(index: i, signer: signer);
    }
  }

  /// Signs all inputs in the PSBT using the provided signer function.
  ///
  /// This method iterates through all inputs and attempts to sign each one using
  /// the `signer` callback.
  ///
  /// Note:
  /// - If the input is already finalized, this method will fail and throw an error.
  /// - The `signer` function will receive all relevant transaction and input data.
  /// - The `signer` function should return one or multiple `PsbtSigner` or `PsbtMusig2Signer`
  ///   objects, depending on the script's signature requirements.
  ///
  /// - If any required signer’s public key is not found in the script, signing will fail.
  /// - If any signature does not pass verification, signing will fail.
  /// - If spending a Taproot leaf script with multiple possible leaf scripts,
  ///   you must determine the correct tapleafHash; otherwise, signing will fail.
  ///
  /// Throws an error if signing fails for any reason.
  Future<void> signAllInputAsync(
      {required ONBTCSIGNERASYNC signer, int? sighashType}) async {
    for (int i = 0; i < _psbt.input.entries.length; i++) {
      if (indexFinalized(i)) continue;
      await signInputAsync(index: i, signer: signer, sighashType: sighashType);
    }
  }

  /// Signs the specified input in the PSBT using the provided signer function.
  ///
  /// This method signs the input at the given index using the `signer` callback.
  ///
  /// Note:
  /// - If the input is already finalized, this method will fail and throw an error.
  /// - The `signer` function will receive all relevant transaction and input data.
  /// - The `signer` function should return one or multiple `PsbtSigner` or `PsbtMusig2Signer`
  ///   objects, depending on the script's signature requirements.
  ///
  /// - If any required signer’s public key is not found in the script, signing will fail.
  /// - If any signature does not pass verification, signing will fail.
  /// - If spending a Taproot leaf script with multiple possible leaf scripts,
  ///   you must determine the correct tapleafHash; otherwise, signing will fail.
  ///
  /// Throws an error if signing fails for any reason.
  Future<void> signInputAsync(
      {required int index,
      required ONBTCSIGNERASYNC signer,
      int? sighashType}) async {
    _checkFinalizeInput(index);
    final txInputs = this.txInputs();
    final params = PsbtUtils.getPsbtInputInfo(
        psbt: _psbt, inputIndex: index, txInputs: txInputs);
    final request = PsbtSignerParams(
        scriptPubKey: params.scriptPubKey,
        index: index,
        inputData: psbtInput(index),
        address: params.address);
    final btcSigner = await signer(request);
    if (btcSigner == null) return;
    for (final signer in btcSigner.signers) {
      final digest = PsbtUtils.generateInputTransactionDigest(
          index: index,
          unsignedTx: buildUnsignedTransaction(),
          params: params,
          input: _psbt.input,
          tapleafHash: btcSigner.tapleafHash,
          sighashType: sighashType,
          psbt: _psbt);
      final signature =
          await signer.btcSignInputAsync(digest.createRequest(signer));
      final psbtSignature = digest.createSignature(signature, signer);
      final sighash = digest.getPsbtSigHash();
      _psbt.input
          .updateInputs(index, [psbtSignature, if (sighash != null) sighash]);
    }
  }
}
