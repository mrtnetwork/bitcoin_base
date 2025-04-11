import 'package:blockchain_utils/helper/extensions/extensions.dart';

enum BitcoinOpcode {
  op0("OP_0", 0x00),
  opFalse("OP_FALSE", 0x00),
  opPushData1("OP_PUSHDATA1", 0x4c),
  opPushData2("OP_PUSHDATA2", 0x4d),
  opPushData4("OP_PUSHDATA4", 0x4e),
  op1Negate("OP_1NEGATE", 0x4f),
  op1("OP_1", 0x51),
  opTrue("OP_TRUE", 0x51),
  op2("OP_2", 0x52),
  op3("OP_3", 0x53),
  op4("OP_4", 0x54),
  op5("OP_5", 0x55),
  op6("OP_6", 0x56),
  op7("OP_7", 0x57),
  op8("OP_8", 0x58),
  op9("OP_9", 0x59),
  op10("OP_10", 0x5a),
  op11("OP_11", 0x5b),
  op12("OP_12", 0x5c),
  op13("OP_13", 0x5d),
  op14("OP_14", 0x5e),
  op15("OP_15", 0x5f),
  op16("OP_16", 0x60),

  // Flow control
  opNop("OP_NOP", 0x61),
  opIf("OP_IF", 0x63),
  opNotIf("OP_NOTIF", 0x64),
  opElse("OP_ELSE", 0x67),
  opEndIf("OP_ENDIF", 0x68),
  opVerify("OP_VERIFY", 0x69),
  opReturn("OP_RETURN", 0x6a),

  // Stack operations
  opToAltStack("OP_TOALTSTACK", 0x6b),
  opFromAltStack("OP_FROMALTSTACK", 0x6c),
  opIfDup("OP_IFDUP", 0x73),
  opDepth("OP_DEPTH", 0x74),
  opDrop("OP_DROP", 0x75),
  opDup("OP_DUP", 0x76),
  opNip("OP_NIP", 0x77),
  opOver("OP_OVER", 0x78),
  opPick("OP_PICK", 0x79),
  opRoll("OP_ROLL", 0x7a),
  opRot("OP_ROT", 0x7b),
  opSwap("OP_SWAP", 0x7c),
  opTuck("OP_TUCK", 0x7d),
  op2Drop("OP_2DROP", 0x6d),
  op2Dup("OP_2DUP", 0x6e),
  op3Dup("OP_3DUP", 0x6f),
  op2Over("OP_2OVER", 0x70),
  op2Rot("OP_2ROT", 0x71),
  op2Swap("OP_2SWAP", 0x72),
  opSize("OP_SIZE", 0x82),
  opEqual("OP_EQUAL", 0x87),
  opEqualVerify("OP_EQUALVERIFY", 0x88),

  // Arithmetic
  op1Add("OP_1ADD", 0x8b),
  op1Sub("OP_1SUB", 0x8c),
  opNegate("OP_NEGATE", 0x8f),
  opAbs("OP_ABS", 0x90),
  opNot("OP_NOT", 0x91),
  op0NotEqual("OP_0NOTEQUAL", 0x92),
  opAdd("OP_ADD", 0x93),
  opSub("OP_SUB", 0x94),
  opBoolAnd("OP_BOOLAND", 0x9a),
  opBoolOr("OP_BOOLOR", 0x9b),
  opNumEqual("OP_NUMEQUAL", 0x9c),
  opNumEqualVerify("OP_NUMEQUALVERIFY", 0x9d),
  opNumNotEqual("OP_NUMNOTEQUAL", 0x9e),
  opLessThan("OP_LESSTHAN", 0x9f),
  opGreaterThan("OP_GREATERTHAN", 0xa0),
  opLessThanOrEqual("OP_LESSTHANOREQUAL", 0xa1),
  opGreaterThanOrEqual("OP_GREATERTHANOREQUAL", 0xa2),
  opMin("OP_MIN", 0xa3),
  opMax("OP_MAX", 0xa4),
  opWithin("OP_WITHIN", 0xa5),

  // Crypto
  opRipemd160("OP_RIPEMD160", 0xa6),
  opSha1("OP_SHA1", 0xa7),
  opSha256("OP_SHA256", 0xa8),
  opHash160("OP_HASH160", 0xa9),
  opHash256("OP_HASH256", 0xaa),
  opCodeSeparator("OP_CODESEPARATOR", 0xab),
  opCheckSig("OP_CHECKSIG", 0xac),
  opCheckSigVerify("OP_CHECKSIGVERIFY", 0xad),
  opCheckMultiSig("OP_CHECKMULTISIG", 0xae),
  opCheckMultiSigVerify("OP_CHECKMULTISIGVERIFY", 0xaf),
  opCheckSigAdd("OP_CHECKSIGADD", 0xba),
  opCheckLockTimeVerify("OP_CHECKLOCKTIMEVERIFY", 0xb1),
  opCheckSequenceVerify("OP_CHECKSEQUENCEVERIFY", 0xb2);

  final String name;
  final int value;

  const BitcoinOpcode(this.name, this.value);

  static BitcoinOpcode? findByName(String name) {
    return values.firstWhereNullable((e) => e.name == name);
  }

  static BitcoinOpcode? findByValue(int value) {
    return values.firstWhereNullable((e) => e.value == value);
  }

  bool get isOpPushData =>
      this == BitcoinOpcode.opPushData1 ||
      this == BitcoinOpcode.opPushData2 ||
      this == BitcoinOpcode.opPushData4;
}

/// ignore_for_file: constant_identifier_names, equal_keys_in_map, non_constant_identifier_names
/// Constants and identifiers used in the Bitcoin-related code.
// ignore_for_file: constant_identifier_names, non_constant_identifier_names, equal_keys_in_map
class BitcoinOpCodeConst {
  static const int opPushData1 = 0x4c;
  static const int opPushData2 = 0x4d;
  static const int opPushData4 = 0x4e;
  static bool isOpPushData(int byte) {
    return byte == BitcoinOpCodeConst.opPushData1 ||
        byte == BitcoinOpCodeConst.opPushData2 ||
        byte == BitcoinOpCodeConst.opPushData4;
  }

  static const int sighashSingle = 0x03;
  static const int sighashAnyoneCanPay = 0x80;
  static const int sighashAll = 0x01;
  static const int sighashForked = 0x40;
  static const int sighashTest = 0x00000041;
  static const int sighashNone = 0x02;
  static const int sighashDefault = 0x00;

  static const int sighashAllAnyOneCanPay = 0x81;
  static const int sighashNoneAnyOneCanPay = 0x82;
  static const int sighashSingleAnyOneCanPay = 0x83;

  /// Transaction lock types
  static const int typeAbsoluteTimelock = 0x101;
  static const int typeRelativeTimelock = 0x201;
  static const int typeReplaceByFee = 0x301;

  /// Default values and sequences
  static const List<int> defaultTxLocktime = [0x00, 0x00, 0x00, 0x00];
  static const List<int> defaultTxSequence = [0xff, 0xff, 0xff, 0xff];
  static const List<int> emptyTxSequence = [0x00, 0x00, 0x00, 0x00];

  static const List<int> absoluteTimelockSequence = [0xfe, 0xff, 0xff, 0xff];
  static const List<int> replaceByFeeSequence = [0x01, 0x00, 0x00, 0x00];

  /// Script version and Bitcoin-related identifiers
  static const int leafVersionTapscript = 0xc0;
  static const List<int> defaultTxVersion = [0x02, 0x00, 0x00, 0x00];
  static const int satoshisPerBitcoin = 100000000;
  static BigInt negativeSatoshi = BigInt.from(-1);

  static const int sequenceLengthInBytes = 4;
  static const int locktimeLengthInBytes = 4;
  static const int versionLengthInBytes = 4;
  static const int outputIndexBytesLength = 4;
  static const int sighashByteLength = 4;
  static const String opReturn = "OP_RETURN";
  static const String opTrue = "OP_TRUE";
  static const String opCheckMultiSig = "OP_CHECKMULTISIG";
  static const String opCheckMultiSigVerify = "OP_CHECKMULTISIGVERIFY";
  static const String opCheckSigAdd = "OP_CHECKSIGADD";

  static const int minInputLocktime = 500000000;
  static const int defaultTxVersionNumber = 2;
  static const int sighashBytesLength = 1;
}
