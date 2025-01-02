/// ELECTRUM Protocol Methods
class ElectrumRequestMethods {
  const ElectrumRequestMethods._(this.method);
  final String method;

  /// Return a list of peer servers. Despite the name this is not a subscription and the server must send no notifications.
  static const ElectrumRequestMethods serverPeersSubscribe =
      ElectrumRequestMethods._('server.peers.subscribe');

  /// Return a server donation address.
  static const ElectrumRequestMethods serverDontionAddress =
      ElectrumRequestMethods._('server.donation_address');

  /// A newly-started server uses this call to get itself into other servers’ peers lists. It should not be used by wallet clients.
  static const ElectrumRequestMethods serverAddPeer =
      ElectrumRequestMethods._('server.add_peer');

  /// Subscribe to a script hash.
  static const ElectrumRequestMethods scriptHashSubscribe =
      ElectrumRequestMethods._('blockchain.scripthash.subscribe');

  /// Unsubscribe from a script hash, preventing future notifications if its status changes.
  static const ElectrumRequestMethods scriptHashUnSubscribe =
      ElectrumRequestMethods._('blockchain.scripthash.unsubscribe');

  /// Return an ordered list of UTXOs sent to a script hash.
  static const ElectrumRequestMethods listunspent =
      ElectrumRequestMethods._('blockchain.scripthash.listunspent');

  /// Return the confirmed and unconfirmed balances of a script hash.
  static const ElectrumRequestMethods getBalance =
      ElectrumRequestMethods._('blockchain.scripthash.get_balance');

  /// Return a raw transaction.
  static const ElectrumRequestMethods getTransaction =
      ElectrumRequestMethods._('blockchain.transaction.get');

  /// Return the merkle branch to a confirmed transaction given its hash and height.
  static const ElectrumRequestMethods getMerkle =
      ElectrumRequestMethods._('blockchain.transaction.get_merkle');

  /// Return a transaction hash and optionally a merkle proof, given a block height and a position in the block.
  static const ElectrumRequestMethods idFromPos =
      ElectrumRequestMethods._('blockchain.transaction.id_from_pos');

  /// Return a histogram of the fee rates paid by transactions in the memory pool, weighted by transaction size.
  static const ElectrumRequestMethods getFeeHistogram =
      ElectrumRequestMethods._('mempool.get_fee_histogram');

  /// Return the block header at the given height.
  static const ElectrumRequestMethods blockHeader =
      ElectrumRequestMethods._('blockchain.block.header');

  /// Return a concatenated chunk of block headers from the main chain.
  static const ElectrumRequestMethods blockHeaders =
      ElectrumRequestMethods._('blockchain.block.headers');

  /// Return the estimated transaction fee per kilobyte for a transaction to be confirmed within a certain number of blocks.
  static const ElectrumRequestMethods estimateFee =
      ElectrumRequestMethods._('blockchain.estimatefee');

  /// Return the confirmed and unconfirmed history of a script hash.
  static const ElectrumRequestMethods getHistory =
      ElectrumRequestMethods._('blockchain.scripthash.get_history');

  /// Return the unconfirmed transactions of a script hash.
  static const ElectrumRequestMethods getMempool =
      ElectrumRequestMethods._('blockchain.scripthash.get_mempool');

  /// Broadcast a transaction to the network.
  static const ElectrumRequestMethods broadCast =
      ElectrumRequestMethods._('blockchain.transaction.broadcast');

  /// Return a banner to be shown in the Electrum console.
  static const ElectrumRequestMethods serverBanner =
      ElectrumRequestMethods._('server.banner');

  /// Return a list of features and services supported by the server.
  static const ElectrumRequestMethods serverFeatures =
      ElectrumRequestMethods._('server.features');

  /// Ping the server to ensure it is responding, and to keep the session alive. The server may disconnect clients that have sent no requests for roughly 10 minutes.
  static const ElectrumRequestMethods ping =
      ElectrumRequestMethods._('server.ping');

  /// Identify the client to the server and negotiate the protocol version. Only the first server.version() message is accepted.
  static const ElectrumRequestMethods version =
      ElectrumRequestMethods._('server.version');

  /// Subscribe to receive block headers when a new block is found.
  static const ElectrumRequestMethods headersSubscribe =
      ElectrumRequestMethods._('blockchain.headers.subscribe');

  /// Return the minimum fee a low-priority transaction must pay in order to be accepted to the daemon’s memory pool.
  static const ElectrumRequestMethods relayFee =
      ElectrumRequestMethods._('blockchain.relayfee');

  /// Pass through the masternode announce message to be broadcast by the daemon.
  static const ElectrumRequestMethods masternodeAnnounceBroadcast =
      ElectrumRequestMethods._('masternode.announce.broadcast');

  /// Returns the status of masternode.
  static const ElectrumRequestMethods masternodeSubscribe =
      ElectrumRequestMethods._('masternode.subscribe');

  /// Returns the list of masternodes.
  static const ElectrumRequestMethods masternodeList =
      ElectrumRequestMethods._('masternode.list');

  /// Returns a diff between two deterministic masternode lists. The result also contains proof data.
  static const ElectrumRequestMethods protxDiff =
      ElectrumRequestMethods._('protx.diff');

  /// Returns detailed information about a deterministic masternode.
  static const ElectrumRequestMethods protxInfo =
      ElectrumRequestMethods._('protx.info');

  /// Returns a name resolution proof, suitable for low-latency (single round-trip) resolution.
  static const ElectrumRequestMethods getValueProof =
      ElectrumRequestMethods._('blockchain.name.get_value_proof');
  @override
  String toString() {
    return method;
  }
}
