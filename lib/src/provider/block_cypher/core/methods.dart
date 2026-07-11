enum BlockCypherRequestMethods {
  transaction("/txs/:transaction_id"),
  transactions("/addrs/:address/full"),
  blockHeight("/blocks/:number"),

  latestBlockHeight("/"),
  feeRecommended("/"),
  rawTransaction("/txs/:transaction_id"),
  addressUtxos("/addrs/:address"),
  sendTransact("/txs/push");

  const BlockCypherRequestMethods(this.url);
  final String url;
}
