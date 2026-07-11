enum MempoolRequestMethods {
  transaction("/tx/:transaction_id"),
  transactions("/address/:address/txs"),
  blockHeight("/block-height/:number"),
  latestBlockHeight("/blocks/tip/height"),
  feeRecommended("/v1/fees/recommended"),
  rawTransaction("/tx/:transaction_id/hex"),
  addressUtxos("/address/:address/utxo"),
  sendTransact("/tx");

  const MempoolRequestMethods(this.url);
  final String url;
}
