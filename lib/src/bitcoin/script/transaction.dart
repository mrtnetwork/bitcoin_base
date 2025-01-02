import 'dart:typed_data';
import 'package:bitcoin_base/src/cash_token/cash_token.dart';
import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
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
/// [hasSegwit] Specifies a tx that includes segwit inputs
/// [witnesses] The witness structure that corresponds to the inputs
class BtcTransaction {
  BtcTransaction(
      {required List<TxInput> inputs,
      required List<TxOutput> outputs,
      List<TxWitnessInput> witnesses = const [],
      this.hasSegwit = false,
      List<int>? lock,
      List<int>? version})
      : locktime = lock?.immutable ?? BitcoinOpCodeConst.DEFAULT_TX_LOCKTIME,
        version = version?.immutable ?? BitcoinOpCodeConst.DEFAULT_TX_VERSION,
        inputs = inputs.immutable,
        outputs = outputs.immutable,
        witnesses = witnesses.immutable;
  final List<TxInput> inputs;
  final List<TxOutput> outputs;
  final List<int> locktime;
  final List<int> version;
  final bool hasSegwit;
  final List<TxWitnessInput> witnesses;

  BtcTransaction copyWith({
    List<TxInput>? inputs,
    List<TxOutput>? outputs,
    List<TxWitnessInput>? witnesses,
    bool? hasSegwit,
    List<int>? lock,
    List<int>? version,
  }) {
    return BtcTransaction(
        inputs: inputs ?? this.inputs,
        outputs: outputs ?? this.outputs,
        witnesses: witnesses ?? this.witnesses,
        hasSegwit: hasSegwit ?? this.hasSegwit,
        lock: lock ?? locktime,
        version: version ?? this.version);
  }

  /// creates a copy of the object (classmethod)
  static BtcTransaction copy(BtcTransaction tx) {
    return BtcTransaction(
        hasSegwit: tx.hasSegwit,
        inputs: tx.inputs.map((e) => e.copy()).toList(),
        outputs: tx.outputs.map((e) => e.copy()).toList(),
        witnesses: tx.witnesses.map((e) => e.copy()).toList(),
        lock: tx.locktime,
        version: tx.version);
  }

  /// Instantiates a Transaction from serialized raw hexadacimal data (classmethod)
  static BtcTransaction fromRaw(String raw) {
    final rawtx = BytesUtils.fromHexString(raw);
    final version = rawtx.sublist(0, 4);
    var cursor = 4;
    List<int>? flag;
    var hasSegwit = false;
    if (rawtx[4] == 0) {
      flag = List<int>.from(rawtx.sublist(5, 6));
      if (flag[0] == 1) {
        hasSegwit = true;
      }
      cursor += 2;
    }
    final vi = IntUtils.decodeVarint(rawtx.sublist(cursor));
    cursor += vi.item2;
    final inputs = <TxInput>[];
    for (var index = 0; index < vi.item1; index++) {
      final inp = TxInput.deserialize(
          bytes: rawtx, hasSegwit: hasSegwit, cursor: cursor);
      inputs.add(inp.item1);
      cursor = inp.item2;
    }
    final outputs = <TxOutput>[];
    final viOut = IntUtils.decodeVarint(rawtx.sublist(cursor));
    cursor += viOut.item2;
    for (var index = 0; index < viOut.item1; index++) {
      final inp = TxOutput.deserialize(
          bytes: rawtx, hasSegwit: hasSegwit, cursor: cursor);
      outputs.add(inp.item1);
      cursor = inp.item2;
    }
    final witnesses = <TxWitnessInput>[];
    if (hasSegwit) {
      if (cursor + 4 < rawtx.length) {
        // in this case the tx contains wintness data.
        for (var n = 0; n < inputs.length; n++) {
          final wVi = IntUtils.decodeVarint(rawtx.sublist(cursor));
          cursor += wVi.item2;
          final witnessesTmp = <String>[];
          for (var n = 0; n < wVi.item1; n++) {
            var witness = <int>[];
            final wtVi = IntUtils.decodeVarint(rawtx.sublist(cursor));
            if (wtVi.item1 != 0) {
              witness = rawtx.sublist(
                  cursor + wtVi.item2, cursor + wtVi.item1 + wtVi.item2);
            }
            cursor += wtVi.item1 + wtVi.item2;
            witnessesTmp.add(BytesUtils.toHexString(witness));
          }

          witnesses.add(TxWitnessInput(stack: witnessesTmp));
        }
      }
    }
    List<int>? lock;
    if ((rawtx.length - cursor) >= 4) {
      lock = rawtx.sublist(cursor, cursor + 4);
    }
    return BtcTransaction(
        inputs: inputs,
        outputs: outputs,
        witnesses: witnesses,
        hasSegwit: hasSegwit,
        version: version,
        lock: lock);
  }

  /// returns the transaction input's digest that is to be signed according.
  ///
  /// [txInIndex] The index of the input that we wish to sign
  /// [script] The scriptPubKey of the UTXO that we want to spend
  /// [sighash] The type of the signature hash to be created
  List<int> getTransactionDigest(
      {required int txInIndex,
      required Script script,
      int sighash = BitcoinOpCodeConst.SIGHASH_ALL}) {
    var tx = copy(this);
    for (final i in tx.inputs) {
      i.scriptSig = Script(script: []);
    }
    tx.inputs[txInIndex].scriptSig = script;
    if ((sighash & 0x1f) == BitcoinOpCodeConst.SIGHASH_NONE) {
      tx = tx.copyWith(outputs: []);
      for (var i = 0; i < tx.inputs.length; i++) {
        if (i != txInIndex) {
          tx.inputs[i].sequence = BitcoinOpCodeConst.EMPTY_TX_SEQUENCE;
        }
      }
    } else if ((sighash & 0x1f) == BitcoinOpCodeConst.SIGHASH_SINGLE) {
      if (txInIndex >= tx.outputs.length) {
        throw const DartBitcoinPluginException(
            'Transaction index is greater than the available outputs');
      }

      final outputs = <TxOutput>[];
      for (var i = 0; i < txInIndex; i++) {
        outputs.add(TxOutput(
            amount: BigInt.from(BitcoinOpCodeConst.NEGATIVE_SATOSHI),
            scriptPubKey: Script(script: [])));
      }
      tx = tx.copyWith(outputs: [...outputs, tx.outputs[txInIndex]]);
      for (var i = 0; i < tx.inputs.length; i++) {
        if (i != txInIndex) {
          tx.inputs[i].sequence = BitcoinOpCodeConst.EMPTY_TX_SEQUENCE;
        }
      }
    }
    if ((sighash & BitcoinOpCodeConst.SIGHASH_ANYONECANPAY) != 0) {
      tx = tx.copyWith(inputs: [tx.inputs[txInIndex]]);
    }
    var txForSign = tx.toBytes(segwit: false);

    txForSign = [
      ...txForSign,
      ...IntUtils.toBytes(sighash, length: 4, byteOrder: Endian.little)
    ];
    return QuickCrypto.sha256DoubleHash(txForSign);
  }

  /// Serializes Transaction to bytes
  List<int> toBytes({bool segwit = false}) {
    final data = DynamicByteTracker();
    data.add(version);
    if (segwit) {
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
    if (segwit) {
      for (final wit in witnesses) {
        final witnessesCountBytes = List<int>.from([wit.stack.length]);
        data.add(witnessesCountBytes);
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
      int sighash = BitcoinOpCodeConst.SIGHASH_ALL,
      required BigInt amount,
      CashToken? token}) {
    final tx = copy(this);
    var hashPrevouts = List<int>.filled(32, 0);
    var hashSequence = List<int>.filled(32, 0);
    var hashOutputs = List<int>.filled(32, 0);
    final basicSigHashType = sighash & 0x1F;
    final anyoneCanPay =
        (sighash & 0xF0) == BitcoinOpCodeConst.SIGHASH_ANYONECANPAY;
    final signAll = (basicSigHashType != BitcoinOpCodeConst.SIGHASH_SINGLE) &&
        (basicSigHashType != BitcoinOpCodeConst.SIGHASH_NONE);
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
    } else if (basicSigHashType == BitcoinOpCodeConst.SIGHASH_SINGLE &&
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
  /// [extFlags] Extension mechanism, default is 0; 1 is for script spending (BIP342)
  /// [script] The script that we are spending (ext_flag=1)
  /// [leafVar] The script version, LEAF_VERSION_TAPSCRIPT for the default tapscript
  /// [sighash] The type of the signature hash to be created
  List<int> getTransactionTaprootDigset(
      {required int txIndex,
      required List<Script> scriptPubKeys,
      required List<BigInt> amounts,
      int extFlags = 0,
      Script? script,
      int leafVar = BitcoinOpCodeConst.LEAF_VERSION_TAPSCRIPT,
      int sighash = BitcoinOpCodeConst.TAPROOT_SIGHASH_ALL}) {
    final newTx = copy(this);
    final sighashNone = (sighash & 0x03) == BitcoinOpCodeConst.SIGHASH_NONE;
    final sighashSingle = (sighash & 0x03) == BitcoinOpCodeConst.SIGHASH_SINGLE;
    final anyoneCanPay =
        (sighash & 0x80) == BitcoinOpCodeConst.SIGHASH_ANYONECANPAY;
    final txForSign = DynamicByteTracker();
    txForSign.add([0]);
    txForSign.add([sighash]);
    txForSign.add(version);
    txForSign.add(locktime);
    var hashPrevouts = <int>[];
    var hashAmounts = <int>[];
    var hashScriptPubkeys = <int>[];
    var hashSequences = <int>[];
    var hashOutputs = <int>[];
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

    final spendType = extFlags * 2 + 0;
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
    if (sighashSingle) {
      final txOut = newTx.outputs[txIndex];
      final packedAmount =
          BigintUtils.toBytes(txOut.amount, length: 8, order: Endian.little);
      final scriptBytes = IntUtils.prependVarint(txOut.scriptPubKey.toBytes());
      final hashOut = [...packedAmount, ...scriptBytes];
      txForSign.add(QuickCrypto.sha256Hash(hashOut));
    }
    if (extFlags == 1) {
      final leafVarBytes = [
        leafVar,
        ...IntUtils.prependVarint(script?.toBytes() ?? <int>[])
      ];
      txForSign.add(taggedHash(leafVarBytes, 'TapLeaf'));
      txForSign.add([0]);
      txForSign.add(List<int>.filled(4, mask8));
    }
    final bytes = txForSign.toBytes();
    return taggedHash(bytes, 'TapSighash');
  }

  /// converts result of to_bytes to hexadecimal string
  String toHex() {
    final bytes = toBytes(segwit: hasSegwit);
    return BytesUtils.toHexString(bytes);
  }

  /// converts result of to_bytes to hexadecimal string
  String serialize() {
    return toHex();
  }

  /// Calculates the tx size
  int getSize() {
    return toBytes(segwit: hasSegwit).length;
  }

  /// Calculates the tx segwit size
  int getVSize() {
    if (!hasSegwit) return getSize();
    const markerSize = 2;
    var witSize = 0;
    var data = <int>[];
    for (final w in witnesses) {
      final countBytes = List<int>.from([w.stack.length]);
      data = List<int>.from([...data, ...countBytes, ...w.toBytes()]);
    }
    witSize = data.length;
    final size = getSize() - (markerSize + witSize);
    final vSize = size + (markerSize + witSize) / 4;
    return vSize.ceil();
  }

  /// Calculates txid and returns it
  String txId() {
    final bytes = toBytes(segwit: false);
    final reversedHash = QuickCrypto.sha256DoubleHash(bytes).reversed.toList();
    return BytesUtils.toHexString(reversedHash);
  }

  Map<String, dynamic> toJson() {
    return {
      'inputs': inputs.map((e) => e.toJson()).toList(),
      'outputs': outputs.map((e) => e.toJson()).toList(),
      'locktime': BytesUtils.toHexString(locktime),
      'version': BytesUtils.toHexString(version),
      'witnesses': witnesses.map((e) => e.toJson()).toList()
    };
  }

  @override
  String toString() {
    return "BtcTransaction{inputs: ${inputs.join(", ")}, outputs: ${outputs.join(", ")}, locktime: ${BytesUtils.toHexString(locktime)}}, version: ${BytesUtils.toHexString(version)}, hasSegwit: $hasSegwit, witnesses:${witnesses.join(",")} ";
  }
}
