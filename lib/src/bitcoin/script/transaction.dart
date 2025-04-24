import 'dart:typed_data';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/cash_token/cash_token.dart';
import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'input.dart';
import 'output.dart';
import 'script.dart';
import 'witness.dart';

/// Represents a Bitcoin transaction
///
/// [inputs] A list of all the transaction inputs
/// [outputs] A list of all the transaction outputs
/// [locktime] The transaction's locktime parameter
/// [version] The transaction version
/// [witnesses] The witness structure that corresponds to the inputs
class BtcTransaction {
  BtcTransaction._(
      {List<TxInput> inputs = const [],
      List<TxOutput> outputs = const [],
      List<TxWitnessInput> witnesses = const [],
      required List<int> locktime,
      required List<int> version})
      : locktime = locktime.asImmutableBytes,
        version = version.asImmutableBytes,
        inputs = inputs.immutable,
        outputs = outputs.immutable,
        witnesses = witnesses.immutable;
  factory BtcTransaction(
      {List<TxInput> inputs = const [],
      List<TxOutput> outputs = const [],
      List<TxWitnessInput> witnesses = const [],
      List<int> locktime = BitcoinOpCodeConst.defaultTxLocktime,
      List<int> version = BitcoinOpCodeConst.defaultTxVersion}) {
    if (locktime.length != BitcoinOpCodeConst.locktimeLengthInBytes) {
      throw DartBitcoinPluginException(
          "Invalid locktime length: expected ${BitcoinOpCodeConst.locktimeLengthInBytes}, but got ${locktime.length}.");
    }
    if (version.length != BitcoinOpCodeConst.versionLengthInBytes) {
      throw DartBitcoinPluginException(
          "Invalid version length: expected ${BitcoinOpCodeConst.versionLengthInBytes}, but got ${version.length}.");
    }
    return BtcTransaction._(
        inputs: inputs,
        outputs: outputs,
        witnesses: witnesses,
        version: version,
        locktime: locktime);
  }
  final List<TxInput> inputs;
  final List<TxOutput> outputs;
  final List<int> locktime;
  final List<int> version;
  final List<TxWitnessInput> witnesses;

  BtcTransaction copyWith({
    List<TxInput>? inputs,
    List<TxOutput>? outputs,
    List<TxWitnessInput>? witnesses,
    List<int>? locktime,
    List<int>? version,
  }) {
    return BtcTransaction(
        inputs: inputs ?? this.inputs.map((e) => e.clone()).toList(),
        outputs: outputs ?? this.outputs.map((e) => e.clone()).toList(),
        witnesses: witnesses ?? this.witnesses.map((e) => e.clone()).toList(),
        locktime: locktime ?? this.locktime,
        version: version ?? this.version);
  }

  /// creates a copy of the object (classmethod)
  static BtcTransaction clone(BtcTransaction tx) {
    return BtcTransaction(
        inputs: tx.inputs.map((e) => e.clone()).toList(),
        outputs: tx.outputs.map((e) => e.clone()).toList(),
        witnesses: tx.witnesses.map((e) => e.clone()).toList(),
        locktime: tx.locktime,
        version: tx.version);
  }

  /// Instantiates a Transaction from serialized raw hexadacimal data (classmethod)
  static BtcTransaction deserialize(List<int> txBytes,
      {bool allowWitness = true}) {
    try {
      final version = txBytes.sublist(0, 4);
      int cursor = 4;
      bool hasWitness = false;
      if (allowWitness && txBytes[4] == 0 && txBytes[5] == 1) {
        hasWitness = true;
        cursor += 2;
      }
      final vi = IntUtils.decodeVarint(txBytes.sublist(cursor));
      cursor += vi.item2;
      final List<TxInput> inputs = [];
      for (int index = 0; index < vi.item1; index++) {
        final inp = TxInput.deserialize(bytes: txBytes, cursor: cursor);
        inputs.add(inp.item1);
        cursor = inp.item2;
      }
      final outputs = <TxOutput>[];
      final viOut = IntUtils.decodeVarint(txBytes.sublist(cursor));
      cursor += viOut.item2;
      for (int index = 0; index < viOut.item1; index++) {
        final inp = TxOutput.deserialize(bytes: txBytes, cursor: cursor);
        outputs.add(inp.item1);
        cursor = inp.item2;
      }
      final List<TxWitnessInput> witnesses = [];
      if (hasWitness) {
        if (cursor + 4 < txBytes.length) {
          for (int n = 0; n < inputs.length; n++) {
            final wVi = IntUtils.decodeVarint(txBytes.sublist(cursor));
            cursor += wVi.item2;
            final witnessesTmp = <String>[];
            for (int n = 0; n < wVi.item1; n++) {
              List<int> witness = [];
              final wtVi = IntUtils.decodeVarint(txBytes.sublist(cursor));
              if (wtVi.item1 != 0) {
                witness = txBytes.sublist(
                    cursor + wtVi.item2, cursor + wtVi.item1 + wtVi.item2);
              }
              cursor += wtVi.item1 + wtVi.item2;
              witnessesTmp.add(BytesUtils.toHexString(witness));
            }

            witnesses.add(TxWitnessInput(stack: witnessesTmp));
          }
        }
      }
      List<int> locktime = BitcoinOpCodeConst.defaultTxLocktime;
      if ((txBytes.length - cursor) >= 4) {
        locktime = txBytes.sublist(cursor, cursor + 4);
        cursor += 4;
      }
      assert(txBytes.length == cursor,
          "Transaction deserialization failed. Unexpected bytes.");

      return BtcTransaction(
          inputs: inputs,
          outputs: outputs,
          witnesses: witnesses,
          version: version,
          locktime: locktime);
    } catch (e) {
      throw DartBitcoinPluginException("Transaction deserialization failed.",
          details: {"error": e.toString()});
    }
  }

  /// returns the transaction input's digest that is to be signed according.
  ///
  /// [txInIndex] The index of the input that we wish to sign
  /// [script] The scriptPubKey of the UTXO that we want to spend
  /// [sighash] The type of the signature hash to be created
  List<int> getTransactionDigest(
      {required int txInIndex,
      required Script script,
      int sighash = BitcoinOpCodeConst.sighashAll}) {
    BtcTransaction tx = clone(this);
    for (final i in tx.inputs) {
      i.scriptSig = Script(script: []);
    }
    tx.inputs[txInIndex].scriptSig = script;
    if ((sighash & 0x1f) == BitcoinOpCodeConst.sighashNone) {
      tx = tx.copyWith(outputs: []);
      for (int i = 0; i < tx.inputs.length; i++) {
        if (i != txInIndex) {
          tx.inputs[i].sequence = BitcoinOpCodeConst.emptyTxSequence;
        }
      }
    } else if ((sighash & 0x1f) == BitcoinOpCodeConst.sighashSingle) {
      if (txInIndex >= tx.outputs.length) {
        throw DartBitcoinPluginException(
            "SIGHASH_SINGLE error: Input index $txInIndex is greater than or equal to the number of outputs (${tx.outputs.length}). This input cannot be signed.");
      }

      final List<TxOutput> outputs = [];
      for (int i = 0; i < txInIndex; i++) {
        outputs.add(TxOutput.negativeOne());
      }
      tx = tx.copyWith(outputs: [...outputs, tx.outputs[txInIndex]]);
      for (int i = 0; i < tx.inputs.length; i++) {
        if (i != txInIndex) {
          tx.inputs[i].sequence = BitcoinOpCodeConst.emptyTxSequence;
        }
      }
    }
    if ((sighash & BitcoinOpCodeConst.sighashAnyoneCanPay) != 0) {
      tx = tx.copyWith(inputs: [tx.inputs[txInIndex]]);
    }
    List<int> txForSign = tx.toBytes(allowWitness: false);

    txForSign = [
      ...txForSign,
      ...IntUtils.toBytes(sighash, length: 4, byteOrder: Endian.little)
    ];
    return QuickCrypto.sha256DoubleHash(txForSign);
  }

  /// Serializes Transaction to bytes
  List<int> toBytes({bool allowWitness = true}) {
    final data = DynamicByteTracker();
    data.add(version);
    if (allowWitness && witnesses.isNotEmpty) {
      data.add([0x00, 0x01]);
    }
    final txInCountBytes = IntUtils.encodeVarint(inputs.length);
    final txOutCountBytes = IntUtils.encodeVarint(outputs.length);

    data.add(txInCountBytes);
    for (final txIn in inputs) {
      data.add(txIn.toBytes());
    }

    data.add(txOutCountBytes);
    for (final txOut in outputs) {
      data.add(txOut.toBytes());
    }
    if (allowWitness && witnesses.isNotEmpty) {
      for (final wit in witnesses) {
        data.add(wit.toBytes());
      }
    }
    data.add(locktime);
    return data.toBytes();
  }

  /// returns the transaction input's segwit digest that is to be signed according to sighash.
  ///
  /// [txInIndex] The index of the input that we wish to sign.
  /// [script] The scriptCode (template) that corresponds to the segwit, transaction output type that we want to spend.
  /// [amount] The amount of the UTXO to spend is included in the signature for segwit (in satoshis).
  /// [sighash] The type of the signature hash to be created.
  List<int> getTransactionSegwitDigit(
      {required int txInIndex,
      required Script script,
      int sighash = BitcoinOpCodeConst.sighashAll,
      required BigInt amount,
      CashToken? token}) {
    final tx = clone(this);
    List<int> hashPrevouts = List<int>.filled(32, 0);
    List<int> hashSequence = List<int>.filled(32, 0);
    List<int> hashOutputs = List<int>.filled(32, 0);
    final basicSigHashType = sighash & 0x1F;
    final anyoneCanPay =
        (sighash & 0xF0) == BitcoinOpCodeConst.sighashAnyoneCanPay;
    final signAll = (basicSigHashType != BitcoinOpCodeConst.sighashSingle) &&
        (basicSigHashType != BitcoinOpCodeConst.sighashNone);
    if (!anyoneCanPay) {
      hashPrevouts = <int>[];
      for (final txin in tx.inputs) {
        final txidBytes = List<int>.from(
            BytesUtils.fromHexString(txin.txId).reversed.toList());
        hashPrevouts = [
          ...hashPrevouts,
          ...txidBytes,
          ...IntUtils.toBytes(txin.txIndex, length: 4, byteOrder: Endian.little)
        ];
      }
      hashPrevouts = QuickCrypto.sha256DoubleHash(hashPrevouts);
    }

    if (!anyoneCanPay && signAll) {
      hashSequence = <int>[];
      for (final i in tx.inputs) {
        hashSequence = [...hashSequence, ...i.sequence];
      }
      hashSequence = QuickCrypto.sha256DoubleHash(hashSequence);
    }
    if (signAll) {
      hashOutputs = <int>[];
      for (final i in tx.outputs) {
        hashOutputs = [...hashOutputs, ...i.toBytes()];
      }
      hashOutputs = QuickCrypto.sha256DoubleHash(hashOutputs);
    }
    if (basicSigHashType == BitcoinOpCodeConst.sighashSingle &&
        txInIndex < tx.outputs.length) {
      final out = tx.outputs[txInIndex];
      final packedAmount =
          BigintUtils.toBytes(out.amount, length: 8, order: Endian.little);
      final scriptBytes = IntUtils.prependVarint(out.scriptPubKey.toBytes());
      hashOutputs = [...packedAmount, ...scriptBytes];
      hashOutputs = QuickCrypto.sha256DoubleHash(hashOutputs);
    }

    final txForSigning = DynamicByteTracker();
    txForSigning.add(version);
    txForSigning.add(hashPrevouts);
    txForSigning.add(hashSequence);
    final txIn = inputs[txInIndex];

    final txidBytes = BytesUtils.fromHexString(txIn.txId).reversed.toList();
    txForSigning.add([
      ...txidBytes,
      ...IntUtils.toBytes(txIn.txIndex, length: 4, byteOrder: Endian.little)
    ]);
    if (token != null) {
      txForSigning.add(token.toBytes());
    }
    final varintBytes = IntUtils.prependVarint(script.toBytes());

    txForSigning.add(varintBytes);
    final packedAmount =
        BigintUtils.toBytes(amount, length: 8, order: Endian.little);
    txForSigning.add(packedAmount);
    txForSigning.add(txIn.sequence);
    txForSigning.add(hashOutputs);
    txForSigning.add(locktime);
    txForSigning
        .add(IntUtils.toBytes(sighash, length: 4, byteOrder: Endian.little));
    return QuickCrypto.sha256DoubleHash(txForSigning.toBytes());
  }

  /// Returns the segwit v1 (taproot) transaction's digest for signing.
  ///
  /// [txIndex] The index of the input that we wish to sign
  /// [scriptPubKeys] he scriptPubkeys that correspond to all the inputs/UTXOs
  /// [amounts] The amounts that correspond to all the inputs/UTXOs
  /// [sighash] The type of the signature hash to be created
  List<int> getTransactionTaprootDigset(
      {required int txIndex,
      required List<Script> scriptPubKeys,
      required List<BigInt> amounts,
      List<int>? annex,
      TaprootLeaf? tapleafScript,
      int sighash = BitcoinOpCodeConst.sighashDefault}) {
    final newTx = clone(this);
    final sighashNone = (sighash & 0x03) == BitcoinOpCodeConst.sighashNone;
    final sighashSingle = (sighash & 0x03) == BitcoinOpCodeConst.sighashSingle;
    final anyoneCanPay =
        (sighash & 0x80) == BitcoinOpCodeConst.sighashAnyoneCanPay;
    final txForSign = DynamicByteTracker();
    txForSign.add([0]);
    txForSign.add([sighash]);
    txForSign.add(version);
    txForSign.add(locktime);
    List<int> hashPrevouts = [];
    List<int> hashAmounts = [];
    List<int> hashScriptPubkeys = [];
    List<int> hashSequences = [];
    List<int> hashOutputs = [];
    if (!anyoneCanPay) {
      for (final txin in newTx.inputs) {
        final txidBytes = BytesUtils.fromHexString(txin.txId).reversed.toList();
        hashPrevouts = [
          ...hashPrevouts,
          ...txidBytes,
          ...IntUtils.toBytes(txin.txIndex, length: 4, byteOrder: Endian.little)
        ];
      }
      hashPrevouts = QuickCrypto.sha256Hash(hashPrevouts);
      txForSign.add(hashPrevouts);

      for (final i in amounts) {
        final bytes = BigintUtils.toBytes(i, length: 8, order: Endian.little);
        hashAmounts = [...hashAmounts, ...bytes];
      }
      hashAmounts = QuickCrypto.sha256Hash(hashAmounts);
      txForSign.add(hashAmounts);

      for (final s in scriptPubKeys) {
        final scriptBytes = IntUtils.prependVarint(s.toBytes());
        hashScriptPubkeys = [...hashScriptPubkeys, ...scriptBytes];
      }
      hashScriptPubkeys = QuickCrypto.sha256Hash(hashScriptPubkeys);
      txForSign.add(hashScriptPubkeys);

      for (final txIn in newTx.inputs) {
        hashSequences = [...hashSequences, ...txIn.sequence];
      }
      hashSequences = QuickCrypto.sha256Hash(hashSequences);
      txForSign.add(hashSequences);
    }
    if (!(sighashNone || sighashSingle)) {
      for (final txOut in newTx.outputs) {
        final packedAmount =
            BigintUtils.toBytes(txOut.amount, length: 8, order: Endian.little);
        final scriptBytes =
            IntUtils.prependVarint(txOut.scriptPubKey.toBytes());
        hashOutputs = [...hashOutputs, ...packedAmount, ...scriptBytes];
      }
      hashOutputs = QuickCrypto.sha256Hash(hashOutputs);
      txForSign.add(hashOutputs);
    }

    int spendType = tapleafScript == null ? 0 : 2;
    if (annex != null) {
      spendType += 1;
    }
    txForSign.add([spendType]);

    if (anyoneCanPay) {
      final txin = newTx.inputs[txIndex];
      final txidBytes = BytesUtils.fromHexString(txin.txId).reversed.toList();
      final result = [
        ...txidBytes,
        ...IntUtils.toBytes(txin.txIndex, length: 4, byteOrder: Endian.little)
      ];
      txForSign.add(result);
      txForSign.add(BigintUtils.toBytes(amounts[txIndex],
          length: 8, order: Endian.little));
      final scriptBytes =
          IntUtils.prependVarint(scriptPubKeys[txIndex].toBytes());
      txForSign.add(scriptBytes);
      txForSign.add(txin.sequence);
    } else {
      final indexBytes =
          IntUtils.toBytes(txIndex, length: 4, byteOrder: Endian.little);
      txForSign.add(indexBytes);
    }
    if (annex != null) {
      final annexBytes = IntUtils.prependVarint(annex);
      txForSign.add(QuickCrypto.sha256Hash(annexBytes));
    }

    ///
    if (sighashSingle && txIndex < newTx.outputs.length) {
      final txOut = newTx.outputs[txIndex];
      final packedAmount =
          BigintUtils.toBytes(txOut.amount, length: 8, order: Endian.little);
      final scriptBytes = IntUtils.prependVarint(txOut.scriptPubKey.toBytes());
      final hashOut = [...packedAmount, ...scriptBytes];
      txForSign.add(QuickCrypto.sha256Hash(hashOut));
    }
    if (tapleafScript != null) {
      txForSign.add(tapleafScript.hash());
      txForSign.add([0]);
      txForSign.add(List<int>.filled(4, mask8));
    }
    final bytes = txForSign.toBytes();
    return TaprootUtils.tapSigTaggedHash(bytes);
  }

  /// converts result of to_bytes to hexadecimal string
  String toHex({bool allowWitness = true}) {
    final bytes = toBytes(allowWitness: allowWitness);
    return BytesUtils.toHexString(bytes);
  }

  /// converts result of to_bytes to hexadecimal string
  String serialize() {
    return toHex();
  }

  /// Calculates the tx size
  int getSize({bool allowWitness = true}) {
    return toBytes(allowWitness: allowWitness).length;
  }

  bool get hasWitness => witnesses.isNotEmpty;

  /// Calculates the tx segwit size
  int getVSize({bool allowWitness = true}) {
    if (!allowWitness || witnesses.isEmpty) return getSize();
    const markerSize = 2;
    int witSize = 0;
    List<int> data =
        witnesses.map((e) => e.toBytes()).expand((e) => e).toList();
    witSize = data.length;
    final size = getSize() - (markerSize + witSize);
    final vSize = size + (markerSize + witSize) / 4;
    return vSize.ceil();
  }

  /// Calculates txid and returns it
  String txId() {
    final bytes = toBytes(allowWitness: false);
    final reversedHash = QuickCrypto.sha256DoubleHash(bytes).reversed.toList();
    return BytesUtils.toHexString(reversedHash);
  }

  Map<String, dynamic> toJson() {
    return {
      'inputs': inputs.map((e) => e.toJson()).toList(),
      'outputs': outputs.map((e) => e.toJson()).toList(),
      'locktime': BytesUtils.toHexString(locktime),
      'version': BytesUtils.toHexString(version),
      'witnesses': witnesses.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return "BtcTransaction{inputs: ${inputs.join(", ")}, outputs: ${outputs.join(", ")}, locktime: ${BytesUtils.toHexString(locktime)}}, version: ${BytesUtils.toHexString(version)}, witnesses:${witnesses.join(",")} ";
  }
}
