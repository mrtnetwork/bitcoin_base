part of 'package:bitcoin_base/src/psbt/psbt_builder/builder.dart';

class PsbtBuilderV0 extends PsbtBuilder {
  PsbtBuilderV0._(Psbt psbt) : super._(psbt: psbt);

  /// Creates a `PsbtBuilderV0` instance from an existing `Psbt` object.
  factory PsbtBuilderV0(Psbt psbt) {
    return PsbtBuilder.fromPsbt(psbt);
  }

  /// Creates a new `PsbtBuilderV0` instance with default values for the transaction locktime and version.
  factory PsbtBuilderV0.create(
      {List<int> txLocktime = BitcoinOpCodeConst.defaultTxLocktime,
      List<int> txVersion = BitcoinOpCodeConst.defaultTxVersion}) {
    final version = PsbtVersion.v0;
    return PsbtBuilderV0._(Psbt(
        global: PsbtGlobal(entries: [
          PsbtGlobalPSBTVersionNumber(version),
          PsbtGlobalUnsignedTransaction(
              BtcTransaction(locktime: txLocktime, version: txVersion))
        ], version: version),
        input: PsbtInput(version: version),
        output: PsbtOutput(version: version)));
  }

  BtcTransaction get _unsignedTx => _psbt.global.entries
      .whereType<PsbtGlobalUnsignedTransaction>()
      .first
      .transaction;

  @override
  TxInput txInput(int index) {
    final unsignedTx = _unsignedTx;
    PsbtUtils.validateTxInputs(
        psbInput: _psbt.input,
        inputIndex: index,
        inputsLength: unsignedTx.inputs.length);
    return _unsignedTx.inputs[index];
  }

  @override
  TxOutput txOutput(int index) {
    final txOutputs = this.txOutputs();
    PsbtUtils.validateTxOutputs(psbtOutput: _psbt.output, outputIndex: index);
    return txOutputs[index];
  }

  @override
  List<TxInput> txInputs() {
    final unsignedTx = _unsignedTx;
    return unsignedTx.inputs.clone();
  }

  @override
  List<TxOutput> txOutputs() {
    final unsignedTx = _unsignedTx;
    return unsignedTx.outputs.clone();
  }

  @override
  BtcTransaction buildUnsignedTransaction() {
    return _unsignedTx;
  }

  @override
  PsbtBuilderV0 clone() {
    return PsbtBuilderV0._(_psbt.clone());
  }

  void _updateUnsignedTx(BtcTransaction transaction) {
    _psbt.global.updateGlobals([PsbtGlobalUnsignedTransaction(transaction)]);
  }

  @override
  void _addNewTxOutput(PsbtTransactionOutput output) {
    super._addNewTxOutput(output);
    _psbt.output.addOutputs(output.toPsbtOutput(psbtVersion));
    BtcTransaction tx = _unsignedTx;
    tx = tx.copyWith(outputs: [...tx.outputs, output.toTxOutput()]);
    _updateUnsignedTx(tx);
  }

  @override
  void _updateTxOutput(int index, PsbtTransactionOutput output) {
    super._updateTxOutput(index, output);
    _psbt.output.replaceOutput(index, output.toPsbtOutput(psbtVersion));
    final txOutputs = this.txOutputs();
    txOutputs[index] = output.toTxOutput();
    BtcTransaction tx = _unsignedTx;
    tx = tx.copyWith(outputs: txOutputs);
    _updateUnsignedTx(tx);
  }

  @override
  void _removeOutput(int index) {
    super._removeOutput(index);
    final outputs = txOutputs();
    outputs.removeAt(index);
    _psbt.output.removeOutput(index);
    BtcTransaction tx = _unsignedTx;
    tx = tx.copyWith(outputs: outputs);
    _updateUnsignedTx(tx);
  }

  @override
  void _updateTxInput(int index, PsbtTransactionInput input) {
    super._updateTxInput(index, input);
    BtcTransaction tx = _unsignedTx;
    final List<TxInput> newInputs = List.generate(tx.inputs.length, (i) {
      if (i == index) return input.txInput;
      return tx.inputs[i];
    });
    final locktime = PsbtUtils.buildTransactionLocktime(inputs: newInputs);
    tx = tx.copyWith(inputs: newInputs, locktime: locktime);
    _updateUnsignedTx(tx);
  }

  @override
  void _removeTxInput(int index) {
    super._removeTxInput(index);
    _psbt.input.removeInput(index);
    final inputs = txInputs();
    inputs.removeAt(index);
    BtcTransaction tx = _unsignedTx;
    final locktime = PsbtUtils.buildTransactionLocktime(inputs: inputs);
    tx = tx.copyWith(inputs: inputs, locktime: locktime);
    _updateUnsignedTx(tx);
  }

  @override
  void _addNewTxInput(PsbtTransactionInput input) {
    super._addNewTxInput(input);
    _psbt.input.addInputs(input.toPsbtInputs(psbtVersion));
    BtcTransaction tx = _unsignedTx;
    final locktime = PsbtUtils.buildTransactionLocktime(
        inputs: [...tx.inputs, input.txInput]);
    tx = tx.copyWith(inputs: [...tx.inputs, input.txInput], locktime: locktime);
    _updateUnsignedTx(tx);
  }
}
