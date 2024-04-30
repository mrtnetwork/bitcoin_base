enum BitcoinFeeRateType { low, medium, high }

class BitcoinFeeRate {
  BitcoinFeeRate(
      {required this.high,
      required this.medium,
      required this.low,
      this.economyFee,
      this.hourFee});

  /// High fee rate in satoshis per kilobyte
  final BigInt high;

  /// Medium fee rate in satoshis per kilobyte
  final BigInt medium;

  /// low fee rate in satoshis per kilobyte
  final BigInt low;

  /// only mnenpool api
  final BigInt? economyFee;

  /// only mnenpool api
  final BigInt? hourFee;

  BigInt _feeRatrete(BitcoinFeeRateType feeRateType) {
    switch (feeRateType) {
      case BitcoinFeeRateType.low:
        return low;
      case BitcoinFeeRateType.medium:
        return medium;
      default:
        return high;
    }
  }

  /// GetEstimate calculates the estimated fee in satoshis for a given transaction size
  /// and fee rate (in satoshis per kilobyte) using the formula:
  //
  /// EstimatedFee = (TransactionSize * FeeRate) / 1024
  //
  /// Parameters:
  /// - trSize: An integer representing the transaction size in bytes.
  /// - feeRate: A BigInt representing the fee rate in satoshis per kilobyte.
  //
  /// Returns:
  /// - BigInt: A BigInt containing the estimated fee in satoshis.
  BigInt getEstimate(int trSize,
      {BigInt? customFeeRatePerKb,
      BitcoinFeeRateType feeRateType = BitcoinFeeRateType.medium}) {
    BigInt feeRate = customFeeRatePerKb ?? _feeRatrete(feeRateType);
    final trSizeBigInt = BigInt.from(trSize);
    return (trSizeBigInt * feeRate) ~/ BigInt.from(1000);
  }

  @override
  String toString() {
    return 'high: ${high.toString()} medium: ${medium.toString()} low: ${low.toString()}, economyFee: $economyFee hourFee: $hourFee';
  }

  /// NewBitcoinFeeRateFromMempool creates a BitcoinFeeRate structure from JSON data retrieved
  /// from a mempool API response. The function parses the JSON map and extracts fee rate
  /// information for high, medium, and low fee levels.
  factory BitcoinFeeRate.fromMempool(Map<String, dynamic> json) {
    return BitcoinFeeRate(
      high: _parseMempoolFees(json['fastestFee']),
      medium: _parseMempoolFees(json['halfHourFee']),
      low: _parseMempoolFees(json['minimumFee']),
      economyFee: json['economyFee'] == null
          ? null
          : _parseMempoolFees(json['economyFee']),
      hourFee:
          json['hourFee'] == null ? null : _parseMempoolFees(json['hourFee']),
    );
  }

  /// NewBitcoinFeeRateFromBlockCypher creates a BitcoinFeeRate structure from JSON data retrieved
  /// from a BlockCypher API response. The function parses the JSON map and extracts fee rate
  /// information for high, medium, and low fee levels.
  factory BitcoinFeeRate.fromBlockCypher(Map<String, dynamic> json) {
    return BitcoinFeeRate(
        high: BigInt.from((json['high_fee_per_kb'] as int)),
        medium: BigInt.from((json['medium_fee_per_kb'] as int)),
        low: BigInt.from((json['low_fee_per_kb'] as int)));
  }
}

/// ParseMempoolFees takes a data dynamic and converts it to a BigInt representing
/// mempool fees in satoshis per kilobyte (sat/KB). The function performs the conversion
/// based on the type of the input data, which can be either a double (floating-point
/// fee rate) or an int (integer fee rate in satoshis per byte).
BigInt _parseMempoolFees(dynamic data) {
  const kb = 1024;

  if (data is double) {
    return BigInt.from((data * kb).toInt());
  } else if (data is int) {
    return BigInt.from((data * kb));
  } else {
    throw StateError(
        "cannot parse mempool fees excepted double, string got ${data.runtimeType}");
  }
}
