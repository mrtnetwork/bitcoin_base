import 'dart:typed_data';
import 'package:bitcoin_base/src/bitcoin/constant/constant.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';
import 'package:bitcoin_base/src/formating/bytes_tracker.dart';
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
      {required this.inputs,
      required this.outputs,
      List<TxWitnessInput> w = const [],
      this.hasSegwit = false,
      Uint8List? lock,
      Uint8List? v})
      : locktime = lock ?? Uint8List.fromList(DEFAULT_TX_LOCKTIME),
        version = v ?? Uint8List.fromList(DEFAULT_TX_VERSION) {
    witnesses.addAll(w);
  }
  final List<TxInput> inputs;
  final List<TxOutput> outputs;
  final Uint8List locktime;
  late final Uint8List version;
  final bool hasSegwit;
  final List<TxWitnessInput> witnesses = [];

  /// creates a copy of the object (classmethod)
  static BtcTransaction copy(BtcTransaction tx) {
    return BtcTransaction(
        hasSegwit: tx.hasSegwit,
        inputs: tx.inputs.map((e) => e.copy()).toList(),
        outputs: tx.outputs.map((e) => e.copy()).toList(),
        w: tx.witnesses.map((e) => e.copy()).toList(),
        lock: tx.locktime,
        v: tx.version);
  }

  /// Instantiates a Transaction from serialized raw hexadacimal data (classmethod)
  static BtcTransaction fromRaw(String raw) {
    final rawtx = hexToBytes(raw);
    int cursor = 4;
    Uint8List? flag;
    bool hasSegwit = false;
    if (rawtx[4] == 0) {
      flag = Uint8List.fromList(rawtx.sublist(5, 6));
      if (flag[0] == 1) {
        hasSegwit = true;
      }
      cursor += 2;
    }
    final vi = viToInt(rawtx.sublist(cursor, cursor + 9));
    cursor += vi.$2;

    List<TxInput> inputs = [];
    for (int index = 0; index < vi.$1; index++) {
      final inp =
          TxInput.fromRaw(raw: raw, hasSegwit: hasSegwit, cursor: cursor);
      inputs.add(inp.$1);
      cursor = inp.$2;
    }

    List<TxOutput> outputs = [];
    final viOut = viToInt(rawtx.sublist(cursor, cursor + 9));
    cursor += viOut.$2;
    for (int index = 0; index < viOut.$1; index++) {
      final inp =
          TxOutput.fromRaw(raw: raw, hasSegwit: hasSegwit, cursor: cursor);
      outputs.add(inp.$1);
      cursor = inp.$2;
    }
    List<TxWitnessInput> witnesses = [];
    if (hasSegwit) {
      for (int n = 0; n < inputs.length; n++) {
        final wVi = viToInt(rawtx.sublist(cursor, cursor + 9));
        cursor += wVi.$2;
        List<String> witnessesTmp = [];
        for (int n = 0; n < wVi.$1; n++) {
          Uint8List witness = Uint8List(0);
          final wtVi = viToInt(rawtx.sublist(cursor, cursor + 9));
          if (wtVi.$1 != 0) {
            witness =
                rawtx.sublist(cursor + wtVi.$2, cursor + wtVi.$1 + wtVi.$2);
          }
          cursor += wtVi.$1 + wtVi.$2;
          witnessesTmp.add(bytesToHex(witness));
        }
        witnesses.add(TxWitnessInput(stack: witnessesTmp));
      }
    }
    return BtcTransaction(
        inputs: inputs, outputs: outputs, w: witnesses, hasSegwit: hasSegwit);
  }

  /// returns the transaction input's digest that is to be signed according.
  ///
  /// [txInIndex] The index of the input that we wish to sign
  /// [script] The scriptPubKey of the UTXO that we want to spend
  /// [sighash] The type of the signature hash to be created
  Uint8List getTransactionDigest(
      {required int txInIndex,
      required Script script,
      int sighash = SIGHASH_ALL}) {
    final tx = copy(this);
    for (final i in tx.inputs) {
      i.scriptSig = const Script(script: []);
    }
    tx.inputs[txInIndex].scriptSig = script;
    if ((sighash & 0x1f) == SIGHASH_NONE) {
      tx.outputs.clear();
      for (int i = 0; i < tx.inputs.length; i++) {
        if (i != txInIndex) {
          tx.inputs[i].sequence = Uint8List.fromList(EMPTY_TX_SEQUENCE);
        }
      }
    } else if ((sighash & 0x1f) == SIGHASH_SINGLE) {
      if (txInIndex >= tx.outputs.length) {
        throw ArgumentError(
            "Transaction index is greater than theavailable outputs");
      }
      final txout = tx.outputs[txInIndex];
      tx.outputs.clear();
      for (int i = 0; i < txInIndex; i++) {
        tx.outputs.add(TxOutput(
            amount: BigInt.from(NEGATIVE_SATOSHI),
            scriptPubKey: const Script(script: [])));
      }
      tx.outputs.add(txout);
      for (int i = 0; i < tx.inputs.length; i++) {
        if (i != txInIndex) {
          tx.inputs[i].sequence = Uint8List.fromList(EMPTY_TX_SEQUENCE);
        }
      }
    }
    if ((sighash & SIGHASH_ANYONECANPAY) != 0) {
      final inp = tx.inputs[txInIndex];
      tx.inputs.clear();
      tx.inputs.add(inp);
    }
    Uint8List txForSign = tx.toBytes(segwit: false);

    Uint8List packedData = packInt32LE(sighash);

    txForSign = Uint8List.fromList([...txForSign, ...packedData]);
    return doubleHash(txForSign);
    // final txForSign =
  }

  /// Serializes Transaction to bytes
  Uint8List toBytes({bool segwit = false}) {
    DynamicByteTracker data = DynamicByteTracker();
    data.add(version);
    if (segwit) {
      data.add([0x00, 0x01]);
    }
    final txInCountBytes = encodeVarint(inputs.length);
    final txOutCountBytes = encodeVarint(outputs.length);

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
        final witnessesCountBytes = Uint8List.fromList([wit.stack.length]);
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
  Uint8List getTransactionSegwitDigit(
      {required int txInIndex,
      required Script script,
      int sighash = SIGHASH_ALL,
      required BigInt amount}) {
    final tx = copy(this);
    Uint8List hashPrevouts = Uint8List(32);
    Uint8List hashSequence = Uint8List(32);
    Uint8List hashOutputs = Uint8List(32);
    int basicSigHashType = sighash & 0x1F;
    bool anyoneCanPay = (sighash & 0xF0) == SIGHASH_ANYONECANPAY;
    bool signAll = (basicSigHashType != SIGHASH_SINGLE) &&
        (basicSigHashType != SIGHASH_NONE);
    if (!anyoneCanPay) {
      hashPrevouts = Uint8List(0);
      for (final txin in tx.inputs) {
        Uint8List txidBytes =
            Uint8List.fromList(hexToBytes(txin.txId).reversed.toList());
        Uint8List txoutIndexBytes = packUint32LE(txin.txIndex);

        hashPrevouts = Uint8List.fromList(
            [...hashPrevouts, ...txidBytes, ...txoutIndexBytes]);
      }
      hashPrevouts = doubleHash(hashPrevouts);
    }

    if (!anyoneCanPay && signAll) {
      hashSequence = Uint8List(0);
      for (final i in tx.inputs) {
        hashSequence = Uint8List.fromList([...hashSequence, ...i.sequence]);
      }
      hashSequence = doubleHash(hashSequence);
    }
    if (signAll) {
      hashOutputs = Uint8List(0);
      for (final i in tx.outputs) {
        Uint8List amountBytes = packBigIntToLittleEndian(i.amount);
        Uint8List scriptBytes = i.scriptPubKey.toBytes();
        hashOutputs = Uint8List.fromList([
          ...hashOutputs,
          ...amountBytes,
          scriptBytes.length,
          ...scriptBytes
        ]);
      }
      hashOutputs = doubleHash(hashOutputs);
    } else if (basicSigHashType == SIGHASH_SINGLE &&
        txInIndex < tx.outputs.length) {
      final out = tx.outputs[txInIndex];
      Uint8List packedAmount = packBigIntToLittleEndian(out.amount);
      final scriptBytes = out.scriptPubKey.toBytes();
      Uint8List lenScriptBytes = Uint8List.fromList([scriptBytes.length]);
      hashOutputs = Uint8List.fromList(
          [...packedAmount, ...lenScriptBytes, ...scriptBytes]);
      hashOutputs = doubleHash(hashOutputs);
    }

    DynamicByteTracker txForSigning = DynamicByteTracker();
    txForSigning.add(version);
    txForSigning.add(hashPrevouts);
    txForSigning.add(hashSequence);
    final txIn = inputs[txInIndex];

    Uint8List txidBytes =
        Uint8List.fromList(hexToBytes(txIn.txId).reversed.toList());
    Uint8List txoutIndexBytes = packUint32LE(txIn.txIndex);
    txForSigning.add(Uint8List.fromList([...txidBytes, ...txoutIndexBytes]));
    txForSigning.add(Uint8List.fromList([script.toBytes().length]));
    txForSigning.add(script.toBytes());
    Uint8List packedAmount = packBigIntToLittleEndian(amount);
    txForSigning.add(packedAmount);
    txForSigning.add(txIn.sequence);
    txForSigning.add(hashOutputs);
    txForSigning.add(locktime);
    Uint8List packedSighash = packInt32LE(sighash);
    txForSigning.add(packedSighash);
    return doubleHash(txForSigning.toBytes());
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
  Uint8List getTransactionTaprootDigset(
      {required int txIndex,
      required List<Script> scriptPubKeys,
      required List<BigInt> amounts,
      int extFlags = 0,
      Script script = const Script(script: []),
      int leafVar = LEAF_VERSION_TAPSCRIPT,
      int sighash = TAPROOT_SIGHASH_ALL}) {
    final newTx = copy(this);
    bool sighashNone = (sighash & 0x03) == SIGHASH_NONE;
    bool sighashSingle = (sighash & 0x03) == SIGHASH_SINGLE;
    bool anyoneCanPay = (sighash & 0x80) == SIGHASH_ANYONECANPAY;
    DynamicByteTracker txForSign = DynamicByteTracker();
    txForSign.add([0]);
    txForSign.add(Uint16List.fromList([sighash]));
    txForSign.add(version);
    txForSign.add(locktime);
    Uint8List hashPrevouts = Uint8List(0);
    Uint8List hashAmounts = Uint8List(0);
    Uint8List hashScriptPubkeys = Uint8List(0);
    Uint8List hashSequences = Uint8List(0);
    Uint8List hashOutputs = Uint8List(0);
    if (!anyoneCanPay) {
      for (final txin in newTx.inputs) {
        Uint8List txidBytes =
            Uint8List.fromList(hexToBytes(txin.txId).reversed.toList());

        Uint8List txoutIndexBytes = packUint32LE(txin.txIndex);
        hashPrevouts = Uint8List.fromList(
            [...hashPrevouts, ...txidBytes, ...txoutIndexBytes]);
      }
      hashPrevouts = singleHash(hashPrevouts);
      txForSign.add(hashPrevouts);

      for (final i in amounts) {
        Uint8List bytes = packBigIntToLittleEndian(i);

        hashAmounts = Uint8List.fromList([...hashAmounts, ...bytes]);
      }
      hashAmounts = singleHash(hashAmounts);
      txForSign.add(hashAmounts);

      for (final s in scriptPubKeys) {
        final h = s.toHex(); // must checked
        int scriptLen = h.length ~/ 2;
        Uint8List scriptBytes = hexToBytes(h);
        Uint8List lenBytes = Uint8List.fromList([scriptLen]);
        hashScriptPubkeys = Uint8List.fromList(
            [...hashScriptPubkeys, ...lenBytes, ...scriptBytes]);
      }
      hashScriptPubkeys = singleHash(hashScriptPubkeys);
      txForSign.add(hashScriptPubkeys);

      for (final txIn in newTx.inputs) {
        hashSequences =
            Uint8List.fromList([...hashSequences, ...txIn.sequence]);
      }
      hashSequences = singleHash(hashSequences);
      txForSign.add(hashSequences);
    }
    if (!(sighashNone || sighashSingle)) {
      for (final txOut in newTx.outputs) {
        Uint8List packedAmount = packBigIntToLittleEndian(txOut.amount);
        Uint8List scriptBytes = txOut.scriptPubKey.toBytes();
        final lenScriptBytes = Uint8List.fromList([scriptBytes.length]);
        hashOutputs = Uint8List.fromList([
          ...hashOutputs,
          ...packedAmount,
          ...lenScriptBytes,
          ...scriptBytes
        ]);
      }
      hashOutputs = singleHash(hashOutputs);
      txForSign.add(hashOutputs);
    }

    final int spendType = extFlags * 2 + 0;
    txForSign.add(Uint8List.fromList([spendType]));

    if (anyoneCanPay) {
      final txin = newTx.inputs[txIndex];
      Uint8List txidBytes =
          Uint8List.fromList(hexToBytes(txin.txId).reversed.toList());
      Uint8List txoutIndexBytes = packUint32LE(txin.txIndex);
      Uint8List result = Uint8List.fromList([...txidBytes, ...txoutIndexBytes]);
      txForSign.add(result);
      txForSign.add(packBigIntToLittleEndian(amounts[txIndex]));
      final sPubKey = scriptPubKeys[txIndex].toHex();
      final sLength = sPubKey.length ~/ 2;
      txForSign.add(Uint16List.fromList([sLength]));
      txForSign.add(hexToBytes(sPubKey));
      txForSign.add(txin.sequence);
    } else {
      int index = txIndex;
      ByteData byteData = ByteData(4);
      for (int i = 0; i < 4; i++) {
        byteData.setUint8(i, index & 0xFF);
        index >>= 8;
      }
      Uint8List bytes = byteData.buffer.asUint8List();
      txForSign.add(bytes);
    }
    if (sighashSingle) {
      final txOut = newTx.outputs[txIndex];

      Uint8List packedAmount = packBigIntToLittleEndian(txOut.amount);
      final sBytes = txOut.scriptPubKey.toBytes();
      Uint8List lenScriptBytes = Uint8List.fromList([sBytes.length]);

      final hashOut =
          Uint8List.fromList([...packedAmount, ...lenScriptBytes, ...sBytes]);
      txForSign.add(singleHash(hashOut));
    }
    if (extFlags == 1) {
      leafVar = LEAF_VERSION_TAPSCRIPT;
      final leafVarBytes = Uint8List.fromList([
        ...Uint8List.fromList([leafVar]),
        ...prependVarint(script.toBytes())
      ]);
      txForSign.add(taggedHash(leafVarBytes, "TapLeaf"));
      txForSign.add(Uint16List.fromList([0]));
      txForSign.add(Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]));
    }
    return taggedHash(txForSign.toBytes(), "TapSighash");
  }

  /// converts result of to_bytes to hexadecimal string
  String toHex() {
    final bytes = toBytes(segwit: hasSegwit);
    return bytesToHex(bytes);
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
    int markerSize = 2;
    int witSize = 0;
    Uint8List data = Uint8List(0);
    for (final w in witnesses) {
      final countBytes = Uint8List.fromList([w.stack.length]);
      data = Uint8List.fromList([...data, ...countBytes, ...w.toBytes()]);
    }
    witSize = data.length;
    int size = getSize() - (markerSize + witSize);
    double vSize = size + (markerSize + witSize) / 4;
    return vSize.ceil();
  }

  /// Calculates txid and returns it
  String txId() {
    final bytes = toBytes(segwit: false);
    final h = doubleHash(bytes).reversed.toList();
    return bytesToHex(h);
  }
}
