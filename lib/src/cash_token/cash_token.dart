// MIT License
// Copyright (c) Jason Dreyzehner
// https://github.com/bitauth/libauth?tab=MIT-1-ov-file#readme
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';

/// The CashTokenCapability class represents different capabilities associated with a Cash Token.
class CashTokenCapability {
  /// Private constructor to create instances of CashTokenCapability with specific values.
  const CashTokenCapability._(this.value, this.name);

  final int value;
  final String name;

  /// (NFTs without a capability) cannot have their commitment modified when spent.
  static const CashTokenCapability noCapability =
      CashTokenCapability._(0x00, "none");

  /// Each Mutable token (NFTs with the mutable capability) allows the spending transaction
  /// to create one NFT of the same category, with any commitment and (optionally) the mutable capability.
  static const CashTokenCapability mutable =
      CashTokenCapability._(0x01, "mutable");

  /// Minting tokens (NFTs with the minting capability) allow the spending transaction to create any number of new NFTs of the same category,
  /// each with any commitment and (optionally) the minting or mutable capability.
  static const CashTokenCapability minting =
      CashTokenCapability._(0x02, "minting");

  ///
  static int _getCapability(int bitfield) {
    return bitfield & 0x0F;
  }

  static const List<CashTokenCapability> values = [
    noCapability,
    mutable,
    minting
  ];

  /// correct capality from bitfield
  static CashTokenCapability fromBitfield(int bitfield) {
    try {
      final int intCapability = _getCapability(bitfield);
      return values.firstWhere((element) => element.value == intCapability);
    } on StateError {
      throw const MessageException("Invalid CashToken NFT Capability");
    }
  }

  /// correct capality from name
  static CashTokenCapability fromName(String name) {
    try {
      return values.firstWhere((element) => element.name == name);
    } on StateError {
      throw const MessageException("Invalid CashToken NFT Capability Name");
    }
  }

  @override
  String toString() {
    return name;
  }
}

/// Constants and utility methods for working with Cash Tokens.
class CashTokenUtils {
  /// Prefix used to identify Cash Tokens.
  static const int cashTokenPrefix = 0xef;

  /// Length of the category bytes for a Cash Token.
  static const int idBytesLength = 32;

  /// Maximum allowed token amount, represented as a BigInt.
  static final BigInt maxTokenAmount = BigInt.two.pow(63) - BigInt.one;

  /// Bitfield flags indicating the presence of specific attributes.
  static const int _hasAmount = 0x10;
  static const int _hasNFT = 0x20;
  static const int _hasCommitmentLength = 0x40;

  /// Build a bitfield based on the presence of various attributes.
  ///
  /// [hasNFT]: Indicates whether the token has an NFT attribute.
  /// [hasAmount]: Indicates whether the token has an amount attribute.
  /// [hasCommitmentLength]: Indicates whether the token has a commitment length attribute.
  /// [capability]: The capability associated with the token.
  static int buildBitfield(
      {bool hasNFT = false,
      bool hasAmount = false,
      bool hasCommitmentLength = false,
      CashTokenCapability? capability}) {
    int capabilityInt = 0;
    if (hasNFT) {
      if (capability != null) {
        // throw const MessageException("Capability is necessary for NFTs.");
        capabilityInt = capability.value;
      }
    }
    final int nft = hasNFT ? _hasNFT : 0;
    int commitmentLength = 0;
    if (hasNFT && hasCommitmentLength) {
      commitmentLength = hasCommitmentLength ? _hasCommitmentLength : 0;
    }

    final int amount = hasAmount ? _hasAmount : 0;
    return nft | commitmentLength | amount | capabilityInt;
  }

  /// Encodes a BigInt into a variable-length integer representation commonly used in Bitcoin protocol.
  ///
  /// The encoding format depends on the magnitude of the provided BigInt:
  /// - If [i] is less than 253, a single byte representation is used.
  /// - If [i] is less than 0x10000, a 3-byte representation with a leading 0xfd byte is used.
  /// - If [i] is less than 0x100000000, a 5-byte representation with a leading 0xfe byte is used.
  /// - Otherwise, a 9-byte representation with a leading 0xff byte is used.
  ///
  /// [i]: The BigInt to be encoded.
  /// Returns a list of integers representing the encoded variable-length integer.
  static List<int> _encodeVarintBigInt(BigInt i) {
    if (i < BigInt.from(253)) {
      return [i.toInt()];
    } else if (i < BigInt.from(0x10000)) {
      final bytes = List<int>.filled(3, 0);
      bytes[0] = 0xfd;
      writeUint16LE(i.toInt(), bytes, 1);
      return bytes;
    } else if (i < BigInt.from(0x100000000)) {
      final bytes = List<int>.filled(5, 0);
      bytes[0] = 0xfe;
      writeUint32LE(i.toInt(), bytes, 1);
      return bytes;
    } else {
      final bytes = List<int>.filled(9, 0);
      bytes[0] = 0xff;
      writeUint32LE(i.toInt(), bytes, 1);
      return [0xff, ...BigintUtils.toBytes(i, length: 8, order: Endian.little)];
    }
  }

  static Tuple<BigInt, int> _decodeVarintBigInt(List<int> byteint) {
    int ni = byteint[0];
    int size = 0;

    if (ni < 253) {
      return Tuple(BigInt.from(ni), 1);
    }

    if (ni == 253) {
      size = 2;
    } else if (ni == 254) {
      size = 4;
    } else {
      size = 8;
    }
    BigInt value = BigintUtils.fromBytes(byteint.sublist(1, 1 + size),
        byteOrder: Endian.little);
    return Tuple(value, size + 1);
  }

  /// Checks if the given bitfield indicates the presence of commitment length.
  /// Returns true if the commitment length is present, otherwise false.
  static bool hasCommitmentLength(int bitfield) {
    return (bitfield & _hasCommitmentLength) != 0;
  }

  /// Checks if the given bitfield indicates the presence of an amount.
  /// Returns true if the amount is present, otherwise false.
  static bool hasAmount(int bitfield) {
    return (bitfield & _hasAmount) != 0;
  }

  /// Checks if the given bitfield indicates the presence of an NFT (Non-Fungible Token).
  /// Returns true if an NFT is present, otherwise false.
  static bool hasNFT(int bitfield) {
    return (bitfield & _hasNFT) != 0;
  }

  /// Validates the integrity of a bitfield representing Cash Token attributes.
  ///
  /// A bitfield is considered valid if:
  /// - The high nibble is not 0x80 or 0x00.
  /// - The lower 4 bits do not exceed the value 2.
  /// - At least one of NFT or amount attributes is present.
  /// - If NFT is not present, the lower 4 bits are 0 or the commitment length is not present.
  ///
  /// [bitfield]: The bitfield to be validated.
  /// Returns true if the bitfield is valid, otherwise false.
  static bool isValidBitfield(int bitfield) {
    final int highNibble = bitfield & 0xF0;
    if (highNibble >= 0x80 || highNibble == 0x00) {
      return false;
    }
    if (bitfield & 0x0F > 2) {
      return false;
    }
    if (!hasNFT(bitfield) && !hasAmount(bitfield)) {
      return false;
    }
    if (!hasNFT(bitfield) && (bitfield & 0x0F) != 0) {
      return false;
    }
    if (!hasNFT(bitfield) && hasCommitmentLength(bitfield)) {
      return false;
    }
    return true;
  }
}

class CashToken {
  factory CashToken.fromJson(Map<String, dynamic> json) {
    final String category = json["category"];
    final BigInt amount = BigintUtils.tryParse(json["amount"]) ?? BigInt.zero;
    CashTokenCapability? capability;
    List<int>? commitment;
    if (json.containsKey("nft")) {
      capability = CashTokenCapability.fromName(json["nft"]["capability"]);
      commitment = ((json["nft"]["commitment"] ?? "") as String).isEmpty
          ? null
          : BytesUtils.fromHexString(json["nft"]["commitment"]);
    }
    int bitfield = CashTokenUtils.buildBitfield(
        hasNFT: capability != null,
        capability: capability ?? CashTokenCapability.noCapability,
        hasAmount: amount > BigInt.zero,
        hasCommitmentLength: commitment != null);
    return CashToken(
        category: category,
        bitfield: bitfield,
        amount: amount,
        commitment: commitment);
  }

  /// The 32-byte ID of the token category to which the token(s) in this output belong. This field is omitted if no tokens are present.
  final String category;

  /// The number of fungible tokens held in this output (an integer between 1 and 9223372036854775807). This field is omitted if no fungible tokens are present
  final BigInt amount;

  /// The commitment contents of the NFT held in this output (0 to 40 bytes). This field is omitted if no NFT is present.
  final List<int> commitment;
  final int bitfield;
  CashToken.noValidate(
      {required this.category,
      required this.amount,
      required List<int> commitment,
      required this.bitfield})
      : commitment = List<int>.unmodifiable(commitment);
  factory CashToken(
      {required String category,
      BigInt? amount,
      List<int>? commitment,
      required int bitfield}) {
    if (!CashTokenUtils.isValidBitfield(bitfield)) {
      throw const MessageException("Invalid bitfield");
    }
    if (CashTokenUtils.hasAmount(bitfield) && amount == null) {
      throw const MessageException(
          "Invalid cash token: the bitfield indicates an amount, but the amount is null.");
    }
    if (amount != null) {
      if (amount < BigInt.zero || amount > CashTokenUtils.maxTokenAmount) {
        throw const MessageException(
            "Invalid amount. Amount must be between zero and 99.");
      }
    }
    if (!StringUtils.isHexBytes(category)) {
      throw const MessageException("Invalid category hexadecimal bytes.");
    }
    final toBytes = BytesUtils.fromHexString(category);
    if (toBytes.length != CashTokenUtils.idBytesLength) {
      throw const MessageException(
          "Invalid category. The category should consist of 32 bytes.");
    }
    if (CashTokenUtils.hasCommitmentLength(bitfield) &&
        (commitment == null || commitment.isEmpty)) {
      throw const MessageException(
          "Invalid cash token: the bitfield indicates an commitment, but the commitment is null or empty.");
    }
    return CashToken.noValidate(
        category: category,
        amount: amount ?? BigInt.zero,
        commitment: commitment ?? const [],
        bitfield: bitfield);
  }
  static Tuple<CashToken?, int> fromRaw(List<int> scriptBytes) {
    if (scriptBytes.isEmpty ||
        scriptBytes[0] != CashTokenUtils.cashTokenPrefix) {
      return const Tuple(null, 0);
    }
    int cursor = 1;
    List<int> id =
        scriptBytes.sublist(cursor, cursor + CashTokenUtils.idBytesLength);

    cursor += CashTokenUtils.idBytesLength;
    final int bitfield = scriptBytes[cursor];
    cursor += 1;
    List<int> commitment = [];
    if (CashTokenUtils.hasCommitmentLength(bitfield)) {
      final vi = IntUtils.decodeVarint(
          scriptBytes.sublist(cursor, scriptBytes.length));
      cursor += vi.item2;
      commitment = scriptBytes.sublist(cursor, cursor + vi.item1);
      cursor += vi.item1;
    }
    BigInt amount = BigInt.zero;
    if (CashTokenUtils.hasAmount(bitfield)) {
      final vi = CashTokenUtils._decodeVarintBigInt(
          scriptBytes.sublist(cursor, scriptBytes.length));
      amount = vi.item1;
      cursor += vi.item2;
    }
    if (!CashTokenUtils.isValidBitfield(bitfield) ||
        amount < BigInt.zero ||
        amount > CashTokenUtils.maxTokenAmount ||
        CashTokenUtils.hasCommitmentLength(bitfield) && commitment.isEmpty) {
      throw const MessageException('Invalid cash token');
    }
    return Tuple(
        CashToken(
            category: BytesUtils.toHexString(id.reversed.toList()),
            amount: amount,
            commitment: commitment,
            bitfield: bitfield),
        cursor);
  }

  /// Converts the [CashToken] instance into a byte representation following the Cash Token serialization format.
  ///
  /// Returns a list of integers representing the serialized byte representation of the [CashToken].
  List<int> toBytes() {
    DynamicByteTracker bytes = DynamicByteTracker();
    bytes.add([CashTokenUtils.cashTokenPrefix]);
    bytes.add(BytesUtils.fromHexString(category).reversed.toList());
    bytes.add([bitfield]);
    if (hasCommitment) {
      final commitmentLengthBytes =
          CashTokenUtils._encodeVarintBigInt(BigInt.from(commitment.length));
      bytes.add(commitmentLengthBytes);
      bytes.add(commitment);
    }
    if (hasAmount) {
      final commitmentLengthBytes = CashTokenUtils._encodeVarintBigInt(amount);
      bytes.add(commitmentLengthBytes);
    }
    return bytes.toBytes();
  }

  String toHex() {
    return BytesUtils.toHexString(toBytes());
  }

  /// Creates a new instance of [CashToken] by copying the existing instance and updating specified fields.
  ///
  /// [category]: The new category value for the copied [CashToken].
  /// [amount]: The new amount value for the copied [CashToken].
  /// [commitment]: The new commitment value for the copied [CashToken].
  /// [bitfield]: The new bitfield value for the copied [CashToken].
  /// Returns a new [CashToken] instance with updated values.
  CashToken copyWith({
    String? category,
    BigInt? amount,
    List<int>? commitment,
    int? bitfield,
  }) {
    return CashToken(
      category: category ?? this.category,
      amount: amount ?? this.amount,
      commitment: commitment ?? this.commitment,
      bitfield: bitfield ?? this.bitfield,
    );
  }

  /// boolean indicating whether the Cash Token has an associated amount attribute.
  late final bool hasAmount = CashTokenUtils.hasAmount(bitfield);

  /// boolean indicating whether the Cash Token is an NFT (Non-Fungible Token).
  late final bool hasNFT = CashTokenUtils.hasNFT(bitfield);

  /// boolean indicating whether the Cash Token has an associated commitment length.
  late final bool hasCommitment =
      !hasNFT ? false : CashTokenUtils.hasCommitmentLength(bitfield);

  /// CashTokenCapability object representing the capability of the Cash Token.
  /// Initialized only if the Cash Token is an NFT.
  late final CashTokenCapability? capability =
      hasNFT ? CashTokenCapability.fromBitfield(bitfield) : null;

  /// hexadecimal representation of the commitment associated with the Cash Token.
  /// Initialized only if the Cash Token has a commitment length.
  late final String? commitmentInHex =
      hasCommitment ? BytesUtils.toHexString(commitment) : null;

  @override
  String toString() {
    return "CashToken{bitfield: $bitfield, commitment: $commitmentInHex, amount: $amount, category: $category}";
  }
}
