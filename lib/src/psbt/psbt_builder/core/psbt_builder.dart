part of 'package:bitcoin_base/src/psbt/psbt_builder/builder.dart';

abstract class PsbtBuilderImpl {
  Psbt get _psbt;

  /// Retrieves the transaction input at the specified index.
  ///
  /// Returns the `TxInput` at the given index.
  /// Throws an error if the index is out of bounds.
  TxInput txInput(int index);

  /// Retrieves the transaction output at the specified index.
  ///
  /// Returns the `TxOutput` at the given index.
  /// Throws an error if the index is out of bounds.
  TxOutput txOutput(int index);

  /// Retrieves a list of all transaction inputs.
  ///
  /// Returns a list of `TxInput` objects representing all inputs in the transaction.
  List<TxInput> txInputs();

  /// Retrieves a list of all transaction outputs.
  ///
  /// Returns a list of `TxOutput` objects representing all outputs in the transaction.
  List<TxOutput> txOutputs();

  /// Retrieves the PSBT representation of a transaction output at the specified index.
  PsbtTransactionOutput psbtOutput(int index) {
    return PsbtTransactionOutput.generateFromOutput(
        psbtOutput: _psbt.output, output: txOutput(index), index: index);
  }

  /// Retrieves the PSBT representation of a transaction input at the specified index.
  PsbtTransactionInput psbtInput(int index) {
    final txInputs = this.txInputs();
    PsbtUtils.validateTxInputs(
        psbInput: _psbt.input,
        inputIndex: index,
        inputsLength: txInputs.length);
    return PsbtTransactionInput.generateFromInput(
        index: index, input: _psbt.input, txInput: txInputs[index]);
  }

  /// Retrieves a list of all PSBT transaction inputs.
  List<PsbtTransactionInput> psbtInputs() {
    final inputs = txInputs();
    return List.generate(
        inputs.length,
        (index) => PsbtTransactionInput.generateFromInput(
            index: index, input: _psbt.input, txInput: inputs[index]));
  }

  /// Retrieves a list of all PSBT transaction outputs.
  List<PsbtTransactionOutput> psbtOutputs() {
    return List.generate(_psbt.output.length, (index) => psbtOutput(index));
  }

  /// Constructs an unsigned Bitcoin transaction from the PSBT.
  ///
  /// This method builds a [BtcTransaction] using the current PSBT data,
  /// excluding any signatures or finalization.
  ///
  /// Note:
  /// - The returned transaction is not ready for broadcast since it lacks signatures.
  /// - Use this to review or analyze the transaction before signing.
  ///
  /// Returns a [BtcTransaction] representing the unsigned transaction.
  BtcTransaction buildUnsignedTransaction();

  /// Checks if the specified input index is finalized.
  ///
  /// An input is considered finalized if it contains either:
  /// - A finalized script signature (`PsbtInputTypes.finalizedScriptSig`).
  /// - A finalized witness (`PsbtInputTypes.finalizedWitness`).
  ///
  /// Returns `true` if the input at the given index is finalized, otherwise `false`.
  bool indexFinalized(int index) {
    bool alreadyFinalized =
        _psbt.input.hasInput(index, PsbtInputTypes.finalizedScriptSig);
    return alreadyFinalized |=
        _psbt.input.hasInput(index, PsbtInputTypes.finalizedWitness);
  }

  /// Determines the current transaction type (Legacy, WitnessV0, or WitnessV1).
  /// The transaction type can change when inputs are added or removed.
  PsbtTxType txType() {
    return PsbtUtils.getTxType(_psbt.input);
  }

  /// Encodes the PSBT as a Base64 string.
  ///
  /// Returns a Base64-encoded representation of the PSBT.
  String toBase64() {
    return _psbt.toBase64();
  }

  /// Encodes the PSBT as a hexadecimal string.
  ///
  /// Returns a hex-encoded representation of the PSBT.
  String toHex() {
    return _psbt.toHex();
  }

  /// Returns the raw PSBT data as a hexadecimal string.
  String toBytes() {
    return _psbt.toHex();
  }

  /// Serializes the PSBT into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return _psbt.toJson();
  }

  void _musig2AddPubKeyNonce(
      int index, PsbtInputMuSig2PublicNonce pubKeyNonce) {
    List<TxInput> txInputs = this.txInputs();
    PsbtUtils.validateTxInputs(
        psbInput: _psbt.input,
        inputIndex: index,
        inputsLength: txInputs.length);
    PsbtUtils.validateAddMusig2PubKeyNonce(
        inputIndex: index,
        psbt: _psbt,
        txInputs: txInputs,
        pubKeyNonce: pubKeyNonce);
    _psbt.input.updateInputs(index, [pubKeyNonce]);
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
  BtcTransaction finalizeAll({ONFINALIZEINPUT? onFinalizeInput});

  /// Estimates the transaction size before finalization.
  /// Optionally accepts a [onFinalizeInput] callback to customize input finalization.
  /// - If any input requires custom script handling, you must provide an
  ///   `onFinalizeInput` callback to finalize it manually; otherwise,
  ///   the operation may fail.
  ///
  /// This method does not reflect the finalized transaction size.
  /// For unsigned P2PKH inputs, it assumes an uncompressed public key
  /// unlocking script for estimation.
  /// For SegWit transactions, it returns the estimated virtual size (vsize).
  int getUnSafeTransactionSize({ONFINALIZEINPUT? onFinalizeInput}) {
    final fakeSignature = PsbtGlobalProprietaryUseType(
        identifier: PsbtUtils.fakeFinalizeGlobalIdentifier,
        subkeydata: [],
        data: const []);
    final Psbt psbt = Psbt(
        global: PsbtGlobal(
            version: _psbt.version,
            entries: [..._psbt.global.entries.clone(), fakeSignature]),
        input: PsbtInput(
            version: _psbt.version, entries: _psbt.input.entries.clone()),
        output: PsbtOutput(
            version: _psbt.version, entries: _psbt.output.entries.clone()));
    final builder = PsbtBuilder.fromPsbt(psbt);
    final tx = builder.finalizeAll(onFinalizeInput: onFinalizeInput);
    return tx.getSize();
  }

  /// Finalizes all inputs and returns the serialized transaction size in bytes.
  ///
  /// Optionally accepts a [onFinalizeInput] callback to customize input finalization.
  /// The returned size is the actual size of the fully finalized transaction.
  /// For SegWit transactions, it returns the estimated virtual size (vsize).
  int finalizeAllAndGetTransactionSize({ONFINALIZEINPUT? onFinalizeInput}) {
    final tx = finalizeAll(onFinalizeInput: onFinalizeInput);
    return tx.getSize();
  }

  void _addNewTxOutput(PsbtTransactionOutput output) {
    PsbtUtils.validateCanAddOrUpdateOutput(psbt: _psbt);
  }

  void _updateTxOutput(int index, PsbtTransactionOutput output) {
    PsbtUtils.validateTxOutputs(
        psbtOutput: _psbt.output, outputIndex: index, outputs: txOutputs());
    final currentOutput = txOutput(index);
    final newOutPut = output.toTxOutput();
    if (newOutPut != currentOutput) {
      PsbtUtils.validateCanAddOrUpdateOutput(psbt: _psbt, outputIndex: index);
    }
  }

  void _removeOutput(int index) {
    final outputs = txOutputs();
    PsbtUtils.validateTxOutputs(
        psbtOutput: _psbt.output, outputIndex: index, outputs: outputs);
    PsbtUtils.validateCanAddOrUpdateOutput(
        psbt: _psbt, outputIndex: index, isUpdate: false);
  }

  void _removeTxInput(int index) {
    PsbtUtils.validateTxInputs(
        psbInput: _psbt.input,
        inputIndex: index,
        inputsLength: txInputs().length);
    PsbtUtils.validateCanAddOrUpdateInput(psbt: _psbt, inputIndex: index);
  }

  void _updateTxInput(int index, PsbtTransactionInput input) {
    List<TxInput> txInputs = this.txInputs();
    PsbtUtils.validateTxInputs(
        psbInput: _psbt.input,
        inputIndex: index,
        inputsLength: txInputs.length);
    PsbtUtils.validateCanAddOrUpdateInput(psbt: _psbt, inputIndex: index);
    txInputs = List.generate(txInputs.length, (i) {
      if (i == index) return input.txInput;
      return txInputs[i];
    });
    PsbtUtils.buildTransactionLocktime(inputs: txInputs);
  }

  void _addNewTxInput(PsbtTransactionInput input) {
    List<TxInput> inputs = txInputs();
    if (inputs.any((e) =>
        e.txId == input.txInput.txId && e.txIndex == input.txInput.txIndex)) {
      throw DartBitcoinPluginException(
          "Duplicate input detected: Transaction ID (${input.txInput.txId}), Output Index (${input.txInput.txIndex})"
          "Each input in a transaction must be unique.");
    }
    PsbtUtils.validateCanAddOrUpdateInput(psbt: _psbt);
    PsbtUtils.validateNewInputLocktime(inputs: inputs, newInput: input.txInput);
  }
}

abstract class PsbtBuilder extends PsbtBuilderImpl
    with PsbtSignerImpl, PsbtInputImpl, PsbtOutputImpl {
  PsbtVersion get psbtVersion => _psbt.version;
  @override
  final Psbt _psbt;
  PsbtBuilder._({required Psbt psbt}) : _psbt = psbt.clone();
  static PSBTBUILDER fromPsbt<PSBTBUILDER extends PsbtBuilder>(Psbt psbt) {
    PsbtBuilder builder = switch (psbt.version) {
      PsbtVersion.v0 => PsbtBuilderV0._(psbt),
      PsbtVersion.v2 => PsbtBuilderV2._(psbt),
    };
    if (builder is! PSBTBUILDER) {
      throw DartBitcoinPluginException(
        "Failed to initialize PSBT builder. Type mismatch: Expected PsbtBuilder<$PSBTBUILDER>, but got ${builder.runtimeType}.",
      );
    }
    return builder;
  }

  /// Creates a `PsbtBuilder` instance from a Base64-encoded PSBT string.
  ///
  /// This method:
  /// - Decodes the Base64 string.
  /// - Deserializes it into a `Psbt` object.
  /// - Returns the correct `PsbtBuilder` subtype based on the PSBT version.
  ///
  static PSBTBUILDER fromBase64<PSBTBUILDER extends PsbtBuilder>(
      String base64) {
    final decode = StringUtils.tryEncode(base64, type: StringEncoding.base64);
    if (decode == null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT base64: Decoding failed or malformed input.");
    }
    return fromBytes(decode);
  }

  /// Creates a `PsbtBuilder` instance from a hex-encoded PSBT string.
  ///
  /// This method:
  /// - Decodes the hex string.
  /// - Deserializes it into a `Psbt` object.
  /// - Returns the correct `PsbtBuilder` subtype based on the PSBT version.
  ///
  static PSBTBUILDER fromHex<PSBTBUILDER extends PsbtBuilder>(String psbtHex) {
    final decode = BytesUtils.tryFromHexString(psbtHex);
    if (decode == null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT Hex: Decoding failed or malformed input.");
    }
    return fromBytes(decode);
  }

  /// Creates a `PsbtBuilder` instance from a PSBT bytes.
  ///
  /// This method:
  /// - Deserializes it into a `Psbt` object.
  /// - Returns the correct `PsbtBuilder` subtype based on the PSBT version.
  ///
  static PSBTBUILDER fromBytes<PSBTBUILDER extends PsbtBuilder>(
      List<int> bytes) {
    PsbtBuilder builder;
    try {
      final psbt = Psbt.deserialize(bytes);
      switch (psbt.version) {
        case PsbtVersion.v0:
          builder = PsbtBuilderV0._(psbt);
          break;
        case PsbtVersion.v2:
          builder = PsbtBuilderV2._(psbt);
          break;
      }
    } catch (e) {
      throw DartBitcoinPluginException(
        "Invalid PSBT: Failed to deserialize.",
        details: {"error": e.toString()},
      );
    }
    if (builder is! PSBTBUILDER) {
      throw DartBitcoinPluginException(
        "Failed to initialize PSBT builder. Type mismatch: Expected PsbtBuilder<$PSBTBUILDER>, but got ${builder.runtimeType}.",
      );
    }
    return builder;
  }

  /// Creates a deep copy (clone) of the current `PsbtBuilder` instance.
  ///
  /// This method clones the internal PSBT object and returns a new instance
  /// of the `PsbtBuilder` subclass, allowing you to modify the copy without affecting the original.
  ///
  PsbtBuilder clone();
}
