import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

class Bip68Const {
  static const int disableFlag = 1 << 31;
  static const int typeFlag = 1 << 22;
  static const int valueMask = BinaryOps.mask16;
}

class Bip68Sequence {
  static int encodeBlocks(int blocks, {bool disable = false}) {
    if (blocks.isNegative || blocks > BinaryOps.mask16) {
      throw DartBitcoinPluginException(
        "Invalid BIP68 block value: $blocks. "
        "Block-based relative locktime must be between 0 and 65535.",
      );
    }
    int seq = blocks & Bip68Const.valueMask;

    if (disable) {
      seq |= Bip68Const.disableFlag;
    }
    return seq;
  }

  static List<int> encodeBlocksBytes(int blocks, {bool disable = false}) {
    return encodeBlocks(blocks, disable: disable).toU32LeBytes();
  }

  static int encodeTime(int seconds, {bool disable = false}) {
    int units = (seconds / 512).floor();
    if (seconds < 0) {
      throw DartBitcoinPluginException(
        "Invalid BIP68 time value: $seconds. "
        "Relative locktime cannot be negative.",
      );
    }

    if (units > Bip68Const.valueMask) {
      throw DartBitcoinPluginException(
        "Invalid BIP68 time value: $seconds seconds. "
        "Maximum allowed is ${Bip68Const.valueMask * 512} seconds "
        "(65535 units of 512 seconds).",
      );
    }
    int seq = units & Bip68Const.valueMask;
    seq |= Bip68Const.typeFlag;
    if (disable) {
      seq |= Bip68Const.disableFlag;
    }

    return seq;
  }

  static Bip68Decoded decode(int sequence) =>
      Bip68Decoded.fromSequence(sequence);
}

class Bip68Decoded {
  final int raw;
  final bool isFinal;
  final bool disabled;
  final bool isTimeBased;

  final int value;

  final int? seconds;
  final int? blocks;
  factory Bip68Decoded.fromSequence(int sequence) {
    if (sequence < 0 || sequence > BinaryOps.mask32) {
      throw DartBitcoinPluginException(
        "Invalid sequence value: $sequence. "
        "Sequence must be a valid unsigned 32-bit integer.",
      );
    }
    bool isFinal = sequence == BinaryOps.mask32;
    bool disabled = (sequence & Bip68Const.disableFlag) != 0;
    bool isTimeBased = (sequence & Bip68Const.typeFlag) != 0;

    int value = sequence & Bip68Const.valueMask;

    return Bip68Decoded(
      raw: sequence,
      isFinal: isFinal,
      disabled: disabled,
      isTimeBased: isTimeBased,
      value: value,
      seconds: isTimeBased ? value * 512 : null,
      blocks: isTimeBased ? null : value,
    );
  }

  Bip68Decoded({
    required this.raw,
    required this.isFinal,
    required this.disabled,
    required this.isTimeBased,
    required this.value,
    required this.seconds,
    required this.blocks,
  });

  @override
  @override
  String toString() {
    if (isFinal) return "Final (no relative timelock)";

    if (disabled) {
      return isTimeBased
          ? "Relative timelock disabled (time-based, raw=$value)"
          : "Relative timelock disabled (block-based, raw=$value)";
    }

    if (isTimeBased) {
      return "Relative time lock: $value units (~${seconds}s)";
    } else {
      return "Relative block lock: $value blocks";
    }
  }
}
