import 'package:bitcoin_base/src/bitcoin/script/transaction.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/psbt/types/types/global.dart';
import 'package:bitcoin_base/src/psbt/types/types/inputs.dart';
import 'package:bitcoin_base/src/psbt/types/types/outputs.dart';
import 'package:bitcoin_base/src/psbt/reader/byte_reader.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

const List<int> _magic = [0x70, 0x73, 0x62, 0x74];
const int _seperator = 0x00;

enum PsbtVersion {
  v0("V0", 0),
  v2("V2", 2);

  bool get isV2 => this == v2;

  final int version;
  const PsbtVersion(this.name, this.version);
  final String name;
}

class PsbtKey {
  final int type;
  final List<int>? extraData;

  PsbtKey(int type, {List<int>? extraData})
      : extraData = extraData?.asImmutableBytes,
        type = type.asUint8;
  factory PsbtKey._deserialize(List<int> bytes) {
    if (bytes.isEmpty) {
      throw DartBitcoinPluginException("Invalid PSBT key bytes length.");
    }
    final keyData = bytes.sublist(1);
    return PsbtKey(bytes[0], extraData: keyData.isEmpty ? null : keyData);
  }

  List<int> serialize() {
    List<int> bytes = [type, ...extraData ?? []];

    return [...IntUtils.encodeVarint(bytes.length), ...bytes];
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is PsbtKey &&
        other.type == type &&
        BytesUtils.bytesEqual(extraData, other.extraData)) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([extraData, type]);
}

class PsbtValue {
  final List<int> data;
  PsbtValue(List<int> data) : data = data.asImmutableBytes;
  List<int> serialize() {
    return [...IntUtils.encodeVarint(data.length), ...data];
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is PsbtValue && BytesUtils.bytesEqual(data, other.data)) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode => HashCodeGenerator.generateBytesHashCode(data);
}

/// Represents a PSBT key-value pair
class PsbtKeyPair {
  final PsbtKey key;
  final PsbtValue value;
  const PsbtKeyPair({required this.key, required this.value});
  factory PsbtKeyPair.deserialize(PsbtByteReader reader) {
    final keyLength = reader.readLength();
    final keyData = reader.read(keyLength);
    final key = PsbtKey._deserialize(keyData);
    final valueLength = reader.readLength();
    final value = PsbtValue(reader.read(valueLength));
    final keyPair = PsbtKeyPair(key: key, value: value);
    return keyPair;
  }
  List<int> serialize() {
    return [...key.serialize(), ...value.serialize()];
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is PsbtKeyPair && key == other.key && value == other.value) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([key, value]);
}

/// Represents a full PSBT (Partially Signed Bitcoin Transaction)
class Psbt {
  final PsbtGlobal global;
  final PsbtInput input;
  final PsbtOutput output;
  PsbtVersion get version => global.version;

  const Psbt._({
    required this.global,
    required this.input,
    required this.output,
  });
  factory Psbt({
    required PsbtGlobal global,
    required PsbtInput input,
    required PsbtOutput output,
  }) {
    final version = global.version;
    if (input.version != version) {
      throw DartBitcoinPluginException(
          "Missmatch version between PSBT global and input");
    }
    if (output.version != version) {
      throw DartBitcoinPluginException(
          "Missmatch version between PSBT global and output");
    }
    return Psbt._(global: global, input: input, output: output);
  }
  factory Psbt.fromHex(String hexBytes) {
    final decode = BytesUtils.tryFromHexString(hexBytes);
    if (decode == null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT hex: Decoding failed or malformed input.");
    }
    return Psbt.deserialize(decode);
  }

  factory Psbt.fromBase64(String base64) {
    final decode = StringUtils.tryEncode(base64, type: StringEncoding.base64);
    if (decode == null) {
      throw DartBitcoinPluginException(
          "Invalid PSBT base64: Decoding failed or malformed input.");
    }
    return Psbt.deserialize(decode);
  }

  /// Deserializes a PSBT
  factory Psbt.deserialize(List<int> bytes) {
    try {
      final reader = PsbtByteReader(bytes);
      if (reader.length < 5 || !BytesUtils.bytesEqual(reader.read(4), _magic)) {
        throw DartBitcoinPluginException("Invalid PSBT magic bytes.");
      }
      reader.skip(1);
      List<PsbtKeyPair> global = [];
      while (reader.at() != _seperator) {
        final pair = PsbtKeyPair.deserialize(reader);
        global.add(pair);
      }
      PsbtVersion psbtVersion = PsbtVersion.v0;
      final psbtVersionKeyType = global.firstWhereNullable(
          (e) => e.key.type == PsbtGlobalTypes.psbtVersion.flag);
      if (psbtVersionKeyType != null) {
        final v = PsbtGlobalPSBTVersionNumber.deserialize(psbtVersionKeyType);
        psbtVersion = v.version;
      }
      int inputLength;
      int outputLength;

      switch (psbtVersion) {
        case PsbtVersion.v0:
          final unsignedTx = global.firstWhere(
              (element) => element.key.type == PsbtGlobalTypes.unsignedTx.flag,
              orElse: () => throw DartBitcoinPluginException(
                  "PSBTv0 Global unsigned tx required."));
          final btcTransaction =
              BtcTransaction.deserialize(unsignedTx.value.data);
          assert(BytesUtils.bytesEqual(
              unsignedTx.value.data, btcTransaction.toBytes()));
          inputLength = btcTransaction.inputs.length;
          outputLength = btcTransaction.outputs.length;
          break;
        case PsbtVersion.v2:
          final inputCount = global.firstWhere(
              (e) => e.key.type == PsbtGlobalTypes.inputCount.flag,
              orElse: () => throw DartBitcoinPluginException(
                    "Invalid PSBT global: Missing required field ${PsbtGlobalTypes.inputCount.psbtName} for PSBT version ${psbtVersion.name}.",
                  ));
          final outputCount = global.firstWhere(
              (e) => e.key.type == PsbtGlobalTypes.outputCount.flag,
              orElse: () => throw DartBitcoinPluginException(
                    "Invalid PSBT global: Missing required field ${PsbtGlobalTypes.outputCount.psbtName} for PSBT version ${psbtVersion.name}.",
                  ));
          inputLength = PsbtGlobalInputCount.deserialize(inputCount).count;
          outputLength = PsbtGlobalOutputCount.deserialize(outputCount).count;
          break;
      }

      reader.skip(1);
      List<List<PsbtKeyPair>> inputs = [];
      for (int i = 0; i < inputLength; i++) {
        List<PsbtKeyPair> input = [];
        while (reader.at() != _seperator) {
          final pair = PsbtKeyPair.deserialize(reader);
          input.add(pair);
        }
        reader.skip(1);
        inputs.add(input);
      }

      List<List<PsbtKeyPair>> outputs = [];
      for (int i = 0; i < outputLength; i++) {
        List<PsbtKeyPair> output = [];
        while (reader.at() != _seperator) {
          final pair = PsbtKeyPair.deserialize(reader);
          output.add(pair);
        }
        reader.skip(1);
        outputs.add(output);
      }

      return Psbt(
          global:
              PsbtGlobal.fromKeyPairs(version: psbtVersion, keypairs: global),
          input: PsbtInput.fromKeyPairs(keypairs: inputs, version: psbtVersion),
          output:
              PsbtOutput.fromKeyPairs(keypairs: outputs, version: psbtVersion));
    } on DartBitcoinPluginException {
      rethrow;
    } catch (e) {
      throw DartBitcoinPluginException(
          "PSBT deserialization failed: Unable to parse the PSBT structure.",
          details: {"error": e.toString()});
    }
  }

  Psbt clone() {
    return Psbt._(
        global: global.clone(), input: input.clone(), output: output.clone());
  }

  String toHex() {
    return BytesUtils.toHexString(serialize());
  }

  String toBase64() {
    return StringUtils.decode(serialize(), type: StringEncoding.base64);
  }

  /// Serializes the full PSBT
  List<int> serialize() {
    List<int> bytes = [..._magic, 0xff];
    final globalKeyPairs = global.toKeyPairs();
    final inputKeyPairs = input.toKeyPairs();
    final outputKeyPairs = output.toKeyPairs();
    final globalKeys = globalKeyPairs.map((e) => e.key).toSet();
    if (globalKeys.length != globalKeyPairs.length) {
      throw DartBitcoinPluginException("Duplicate global entries found.");
    }
    final dupInputs = inputKeyPairs
        .any((e) => e.map((e) => e.key).toSet().length != e.length);
    if (dupInputs) {
      throw DartBitcoinPluginException("Duplicate inputs entries found.");
    }
    final dupOutputs = outputKeyPairs
        .any((e) => e.map((e) => e.key).toSet().length != e.length);
    if (dupOutputs) {
      throw DartBitcoinPluginException("Duplicate output entries found.");
    }
    for (final i in globalKeyPairs) {
      bytes.addAll(i.serialize());
    }
    bytes.add(_seperator);
    for (final i in inputKeyPairs) {
      if (i.isEmpty) {
        bytes.add(_seperator);
        continue;
      }
      for (final e in i) {
        bytes.addAll(e.serialize());
      }
      bytes.add(_seperator);
    }

    for (final i in outputKeyPairs) {
      if (i.isEmpty) {
        bytes.add(_seperator);
        continue;
      }
      for (final e in i) {
        bytes.addAll(e.serialize());
      }
      bytes.add(_seperator);
    }
    return bytes;
  }

  Map<String, dynamic> toJson() {
    return {
      "global": global.toJson(),
      "input": input.toJson(),
      "output": output.toJson()
    };
  }
}
