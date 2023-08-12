class NetworkInfo {
  final String messagePrefix;
  final String bech32;
  final int p2pkhPrefix;
  final int p2shPrefix;
  final int wif;
  // ignore: constant_identifier_names
  static const BITCOIN = NetworkInfo(
      messagePrefix: '\x18Bitcoin Signed Message:\n',
      bech32: 'bc',
      p2pkhPrefix: 0x00,
      p2shPrefix: 0x05,
      wif: 0x80);

  // ignore: constant_identifier_names
  static const TESTNET = NetworkInfo(
      messagePrefix: '\x18Bitcoin Signed Message:\n',
      bech32: 'tb',
      p2pkhPrefix: 0x6f,
      p2shPrefix: 0xc4,
      wif: 0xef);
  static NetworkInfo networkFromWif(String wif) {
    final w = int.parse(wif, radix: 16);
    if (TESTNET.wif == w) {
      return TESTNET;
    } else if (BITCOIN.wif == w) {
      return BITCOIN;
    }
    throw ArgumentError(
        "wif perefix $wif not supported, only bitcoin or testnet accepted");
  }

  const NetworkInfo(
      {required this.messagePrefix,
      required this.bech32,
      required this.p2pkhPrefix,
      required this.p2shPrefix,
      required this.wif});
}
