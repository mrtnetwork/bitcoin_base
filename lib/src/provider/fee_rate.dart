class BitcoinFeeRate {
  BitcoinFeeRate._(
      {required this.high, required this.medium, required this.low});
  BigInt high; // High fee rate in satoshis per byte
  BigInt medium; // Medium fee rate in satoshis per byte
  BigInt low; // Low fee rate in satoshis per byte

  // GetEstimate calculates the estimated fee in satoshis for a given transaction size
  // and fee rate (in satoshis per kilobyte) using the formula:
  //
  // EstimatedFee = (TransactionSize * FeeRate) / 1024
  //
  // Parameters:
  // - trSize: An integer representing the transaction size in bytes.
  // - feeRate: A BigInt representing the fee rate in satoshis per kilobyte.
  //
  // Returns:
  // - BigInt: A BigInt containing the estimated fee in satoshis.
  BigInt getEstimate(int trSize, {BigInt? feeRate}) {
    final trSizeBigInt = BigInt.from(trSize);
    return (trSizeBigInt * (feeRate ?? medium)) ~/ BigInt.from(1024);
  }

  @override
  String toString() {
    return 'high: ${high.toString()} medium: ${medium.toString()} low: ${low.toString()}';
  }

// NewBitcoinFeeRateFromMempool creates a BitcoinFeeRate structure from JSON data retrieved
// from a mempool API response. The function parses the JSON map and extracts fee rate
// information for high, medium, and low fee levels.
  factory BitcoinFeeRate.fromMempool(Map<String, dynamic> json) {
    return BitcoinFeeRate._(
        high: parseMempoolFees(json['fastestFee'])!,
        medium: parseMempoolFees(json['halfHourFee'])!,
        low: parseMempoolFees(json['minimumFee'])!);
  }
// NewBitcoinFeeRateFromBlockCypher creates a BitcoinFeeRate structure from JSON data retrieved
// from a BlockCypher API response. The function parses the JSON map and extracts fee rate
// information for high, medium, and low fee levels.
  factory BitcoinFeeRate.fromBlockCypher(Map<String, dynamic> json) {
    return BitcoinFeeRate._(
        high: BigInt.from((json['high_fee_per_kb'] as int)),
        medium: BigInt.from((json['medium_fee_per_kb'] as int)),
        low: BigInt.from((json['low_fee_per_kb'] as int)));
  }
}

// ParseMempoolFees takes a data dynamic and converts it to a BigInt representing
// mempool fees in satoshis per kilobyte (sat/KB). The function performs the conversion
// based on the type of the input data, which can be either a double (floating-point
// fee rate) or an int (integer fee rate in satoshis per byte).
BigInt? parseMempoolFees(dynamic data) {
  const kb = 1024;

  if (data is double) {
    return BigInt.from((data * kb).toInt());
  } else if (data is int) {
    return BigInt.from((data * kb));
  } else {
    return null;
  }
}
