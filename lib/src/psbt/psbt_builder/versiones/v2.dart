part of 'package:bitcoin_base/src/psbt/psbt_builder/builder.dart';

class PsbtBuilderV2 extends PsbtBuilder {
  PsbtBuilderV2._(Psbt psbt) : super._(psbt: psbt);

  /// Creates a `PsbtBuilderV0` instance from an existing `Psbt` object.
  factory PsbtBuilderV2(Psbt psbt) {
    return PsbtBuilder.fromPsbt(psbt);
  }

  /// Creates a new `PsbtBuilderV2` instance with default values for the transaction locktime and version.
  factory PsbtBuilderV2.create(
      {int transactionVesion = BitcoinOpCodeConst.defaultTxVersionNumber}) {
    final PsbtVersion version = PsbtVersion.v2;
    return PsbtBuilderV2._(Psbt(
        global: PsbtGlobal(entries: [
          PsbtGlobalPSBTVersionNumber(version),
          PsbtGlobalTransactionVersion(transactionVesion),
          PsbtGlobalOutputCount(0),
          PsbtGlobalInputCount(0)
        ], version: version),
        input: PsbtInput(version: version),
        output: PsbtOutput(version: version)));
  }

  @override
  PsbtBuilderV2 clone() {
    return PsbtBuilderV2._(_psbt.clone());
  }

  List<int> _buildInputSequence(int index) {
    final sequence = _psbt.input.getInput<PsbtInputSequenceNumber>(
        index, PsbtInputTypes.sequenceNumber);
    final locktime = _psbt.input.getInput<PsbtInputRequiredTimeBasedLockTime>(
        index, PsbtInputTypes.requiredTimeBasedLockTime);
    final heightNumber = _psbt.input
        .getInput<PsbtInputRequiredHeightBasedLockTime>(
            index, PsbtInputTypes.requiredHeightBasedLockTime);
    if (sequence == null && locktime == null && heightNumber == null) {
      return BitcoinOpCodeConst.defaultTxSequence;
    }
    if (locktime != null && heightNumber != null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT input $index: Only one locktime field (PSBT_IN_REQUIRED_TIME_LOCKTIME or PSBT_IN_REQUIRED_HEIGHT_LOCKTIME) can be set.");
    }
    if (sequence != null) {
      final sequenceBytes = sequence.sequenceBytes();
      if (locktime == null && heightNumber == null) {
        return sequenceBytes;
      } else if (BytesUtils.bytesEqual(
          BitcoinOpCodeConst.defaultTxSequence, sequenceBytes)) {
        if (locktime != null &&
            BytesUtils.bytesEqual(BitcoinOpCodeConst.defaultTxSequence,
                locktime.sequenceBytes())) {
          return sequenceBytes;
        }
        throw DartBitcoinPluginException(
            'Invalid PSBT input: Locktime is set, but sequence is 0xFFFFFFFF (disable locktime).');
      }
    }
    return locktime?.sequenceBytes() ?? heightNumber!.sequenceBytes();
  }

  @override
  void _addNewTxInput(PsbtTransactionInput input) {
    super._addNewTxInput(input);
    _psbt.input.addInputs(input.toPsbtInputs(psbtVersion));
    _psbt.global.updateGlobals([PsbtGlobalInputCount(_psbt.input.length)]);
  }

  @override
  TxInput txInput(int index) {
    final txId = _psbt.input
        .getInput<PsbtInputPreviousTXID>(index, PsbtInputTypes.previousTxId);
    final txIndex = _psbt.input.getInput<PsbtInputSpentOutputIndex>(
        index, PsbtInputTypes.spentOutputIndex);
    if (txId == null) {
      throw DartBitcoinPluginException(
          'Invalid Psbt input $index: Missing required field: previous tx id (PSBT_IN_PREVIOUS_TXID)');
    }
    if (txIndex == null) {
      throw DartBitcoinPluginException(
          'Invalid Psbt input $index: Missing required field: spent output index (PSBT_IN_OUTPUT_INDEX)');
    }
    final sequence = _buildInputSequence(index);
    return TxInput(
        txId: BytesUtils.toHexString(txId.txId.reversed.toList()),
        txIndex: txIndex.index,
        sequance: sequence);
  }

  @override
  void _updateTxInput(int index, PsbtTransactionInput input) {
    super._updateTxInput(index, input);
    _psbt.input.updateInputs(index, input.toPsbtInputs(psbtVersion));
    _psbt.global.updateGlobals([PsbtGlobalInputCount(_psbt.input.length)]);
  }

  @override
  void _removeTxInput(int index) {
    super._removeTxInput(index);
    _psbt.input.removeInput(index);
    _psbt.global.updateGlobals([PsbtGlobalInputCount(_psbt.input.length)]);
  }

  @override
  void _addNewTxOutput(PsbtTransactionOutput output) {
    super._addNewTxOutput(output);
    _psbt.output.addOutputs(output.toPsbtOutput(psbtVersion));
    _psbt.global.updateGlobals([PsbtGlobalOutputCount(_psbt.output.length)]);
  }

  @override
  void _updateTxOutput(int index, PsbtTransactionOutput output) {
    super._updateTxOutput(index, output);
    _psbt.output.replaceOutput(index, output.toPsbtOutput(psbtVersion));
    _psbt.global.updateGlobals([PsbtGlobalOutputCount(_psbt.output.length)]);
  }

  @override
  void _removeOutput(int index) {
    super._removeOutput(index);
    _psbt.output.removeOutput(index);
    _psbt.global.updateGlobals([PsbtGlobalOutputCount(_psbt.output.length)]);
  }

  TxOutput _getOutput(int index) {
    final amount =
        _psbt.output.getOutput<PsbtOutputAmount>(index, PsbtOutputTypes.amount);
    final script =
        _psbt.output.getOutput<PsbtOutputScript>(index, PsbtOutputTypes.script);
    if (amount == null) {
      throw DartBitcoinPluginException(
          'Invalid Psbt output $index: Missing required field: amount (PSBT_OUT_AMOUNT)');
    }
    if (script == null) {
      throw DartBitcoinPluginException(
          'Invalid Psbt output $index: Missing required field: output script (PSBT_OUT_SCRIPT)');
    }
    return TxOutput(amount: amount.amount, scriptPubKey: script.script);
  }

  @override
  List<TxOutput> txOutputs() {
    return List.generate(_psbt.output.length, (i) => _getOutput(i));
  }

  @override
  BtcTransaction buildUnsignedTransaction() {
    final txVersion = _psbt.global
        .getGlobal<PsbtGlobalTransactionVersion>(PsbtGlobalTypes.version);
    final locktimeFallBack = _psbt.global.getGlobal<PsbtGlobalFallbackLocktime>(
        PsbtGlobalTypes.fallBackLockTime);
    if (txVersion == null) {
      throw DartBitcoinPluginException(
          'Invalid Psbt global: Missing required field: Transaction Version (PSBT_GLOBAL_TX_VERSION)');
    }
    final inputs = txInputs();
    return BtcTransaction(
        inputs: inputs,
        outputs: txOutputs(),
        version: txVersion.versionBytes(),
        locktime: PsbtUtils.buildTransactionLocktime(
            inputs: inputs,
            locktimeFallBack: locktimeFallBack?.locktimeBytes()));
  }

  @override
  List<TxInput> txInputs() {
    return List.generate(_psbt.input.length, (i) => txInput(i));
  }

  @override
  TxOutput txOutput(int index) {
    final txOutputs = this.txOutputs();
    if (index >= txOutputs.length) {
      throw DartBitcoinPluginException(
          "Index out of bounds: PSBT output index exceeds transaction outputs.");
    }
    return txOutputs[index];
  }
}
