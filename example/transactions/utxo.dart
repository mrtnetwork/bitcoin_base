class UTXO {
  UTXO({required this.txId, required this.value, required this.vout});
  UTXO.fromJson(Map<String, dynamic> json)
      : txId = json["txid"],
        vout = json["vout"],
        value = BigInt.parse(json["value"]);
  final String txId;
  final int vout;
  final BigInt value;
}
