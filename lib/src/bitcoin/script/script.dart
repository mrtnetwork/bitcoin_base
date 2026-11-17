import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class Script {
  static Script get empty => Script();
  Script._({required List<dynamic> script})
    : script = script.immutable,
      _scriptBytes = _toBytes(script).asImmutableBytes;
  factory Script.fromJson(Map<String, dynamic> json) {
    return Script(script: json["script"]);
  }
  factory Script({List<dynamic> script = const []}) {
    for (final i in script) {
      if (i is! String && i is! int && i is! BaseBitcoinOpcode) {
        throw BuError(
          DefaultErrorType.invalidArgument,
          "A valid script is a composition of opcodes, hexadecimal strings, and integers arranged in a structured list.",
        );
      }
    }
    List<dynamic> scripts = [];
    for (final token in script) {
      if (token is BaseBitcoinOpcode) {
        if (token.isOpPushData) continue;
        scripts.add(token.name);
        continue;
      }
      final opcode = BaseBitcoinOpcode.findByName(token.toString());
      if (opcode != null) {
        scripts.add(opcode.name);
      } else if (token is int && token >= 0 && token <= 16) {
        scripts.add('OP_$token');
      } else {
        if (token is int) {
          final opcode = BitcoinOpcode.findByValue(token);
          if (opcode?.isOpPushData ?? false) continue;
          scripts.add(token);
        } else {
          final tokenBytes = BytesUtils.tryFromHexString(token);
          if (tokenBytes == null) {
            throw BuError(
              DefaultErrorType.invalidArgument,
              "A valid script is a composition of opcodes, hexadecimal strings, and integers arranged in a structured list.",
            );
          }
          scripts.add(StringUtils.strip0x((token as String).toLowerCase()));
        }
      }
    }

    return Script._(script: scripts);
  }
  final List<dynamic> script;
  final BuBytes _scriptBytes;

  factory Script.deserialize({required List<int> bytes}) {
    final List<String> commands = [];
    int index = 0;
    while (index < bytes.length) {
      final byte = bytes[index];
      final opcode = BaseBitcoinOpcode.findByValue(byte);
      if (opcode != null) {
        if (!opcode.isOpPushData) {
          commands.add(opcode.name);
        }

        /// skip op
        index = index + 1;
        if (opcode == BitcoinOpcode.opPushData1) {
          if (index >= bytes.length) {
            throw BuError(
              DefaultErrorType.invalidArgument,
              "Invalid script: truncated OP_PUSHDATA1 length.",
            );
          }
          // get len
          final bytesToRead = bytes[index];
          // skip len
          index = index + 1;
          if (index + bytesToRead > bytes.length) {
            throw BuError(
              DefaultErrorType.invalidArgument,
              "Invalid script: truncated OP_PUSHDATA1 data.",
            );
          }

          commands.add(
            BytesUtils.toHexString(bytes.sublist(index, index + bytesToRead)),
          );

          /// add length
          index = index + bytesToRead;
        } else if (opcode == BitcoinOpcode.opPushData2) {
          if (index + 2 > bytes.length) {
            throw BuError(
              DefaultErrorType.invalidArgument,
              "Invalid script: truncated OP_PUSHDATA2 length.",
            );
          }

          /// get len
          final bytesToRead = BinaryOps.readUint16LE(bytes, index);
          index = index + 2;
          if (index + bytesToRead > bytes.length) {
            throw BuError(
              DefaultErrorType.invalidArgument,
              "Invalid script: truncated OP_PUSHDATA2 data.",
            );
          }

          commands.add(
            BytesUtils.toHexString(bytes.sublist(index, index + bytesToRead)),
          );

          index = index + bytesToRead;
        } else if (opcode == BitcoinOpcode.opPushData4) {
          if (index + 4 > bytes.length) {
            throw BuError(
              DefaultErrorType.invalidArgument,
              "Invalid script: truncated OP_PUSHDATA4 length.",
            );
          }
          final bytesToRead = BinaryOps.readUint32LE(bytes, index);

          index = index + 4;
          if (index + bytesToRead > bytes.length) {
            throw BuError(
              DefaultErrorType.invalidArgument,
              "Invalid script: truncated OP_PUSHDATA4 data.",
            );
          }
          commands.add(
            BytesUtils.toHexString(bytes.sublist(index, index + bytesToRead)),
          );
          index = index + bytesToRead;
        }
      } else {
        final int prefix = bytes[index];
        final int headerLen =
            prefix < 253 ? 1 : (prefix == 253 ? 3 : (prefix == 254 ? 5 : 9));
        if (index + headerLen > bytes.length) {
          throw BuError(
            DefaultErrorType.invalidArgument,
            "Invalid script: truncated pushdata length.",
          );
        }
        final viAndSize = IntUtils.decodeVarint(bytes.sublist(index));
        final dataSize = viAndSize.$1;
        final size = viAndSize.$2;
        if (index + size + dataSize > bytes.length) {
          throw BuError(
            DefaultErrorType.invalidArgument,
            "Invalid script: truncated pushdata.",
          );
        }
        commands.add(
          BytesUtils.toHexString(
            bytes.sublist(index + size, index + size + dataSize),
          ),
        );
        index = index + dataSize + size;
      }
    }
    return Script(script: commands);
  }

  static BuBytes _toBytes(List<dynamic> script) {
    if (script.isEmpty) return BuBytes.empty();
    final scriptBytes = BuBytes.empty();
    for (final token in script) {
      final opcode = BaseBitcoinOpcode.findByName(token.toString());
      if (opcode != null) {
        scriptBytes.add(opcode.value);
      } else {
        if (token is int) {
          scriptBytes.addAll(BitcoinScriptUtils.pushInteger(token));
        } else {
          final tokenBytes = BytesUtils.tryFromHexString(token);
          if (tokenBytes == null) {
            throw BuError(
              DefaultErrorType.invalidArgument,
              "A valid script is a composition of opcodes, hexadecimal strings, and integers arranged in a structured list.",
            );
          }
          scriptBytes.addAll(BitcoinScriptUtils.opPushData(tokenBytes));
        }
      }
    }

    return scriptBytes;
  }

  BuBytes toBytes() {
    return _scriptBytes.clone();
  }

  String toHex() {
    return BytesUtils.toHexString(toBytes());
  }

  Map<String, dynamic> toJson() {
    return {"script": script};
  }

  @override
  String toString() {
    return script.toString();
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is Script) {
      return BytesUtils.bytesEqual(_scriptBytes, other._scriptBytes);
    }
    return false;
  }

  @override
  int get hashCode => HashCodeGenerator.generateBytesHashCode(_scriptBytes);
}
