import 'package:bitcoin_base/src/bip39/bip39.dart';
import 'package:bitcoin_base/src/bitcoin/address/core.dart';
import 'package:bitcoin_base/src/hd_wallet/hd_wallet.dart';
import 'package:bitcoin_base/src/models/network.dart';

void main() {
  const NetworkInfo network = NetworkInfo.TESTNET;
  final mn = BIP39.generateMnemonic();

  /// accsess to private and public keys
  final masterWallet = HdWallet.fromMnemonic(mn);
  HdWallet.fromXPrivateKey(masterWallet.toXpriveKey());

  /// sign legacy and segwit transaction
  //masterWallet.privateKey.signInput(txDigest);

  /// sign taproot transaction
  //masterWallet.privateKey.signTapRoot(txDigest);

  /// sign message
  //masterWallet.privateKey.signMessage(txDigest);

  /// tprv8ZgxMBicQKsPdEtasyf3Qc1vAycp7pVSf6oAcnN4XAeYuntXsUargabb3Rcdo78YKzAxARfVLah4nfkUfYDrWodRWA9YEstwSrV5ZNvApvt
  masterWallet.toXpriveKey(network: network, semantic: AddressType.p2pkh);

  /// accsess to publicKey
  /// tpubD6NzVbkrYhZ4WhvNmdKdp1g2k18kH9gMEQPwuJQMwSSwkH9JVsQSs5DTDZKeJTiTvLinuTwdL4zf6CJAWE79VwhxHn9tDcq33Xj7BgLKZEH
  final xPublic = masterWallet.toXpublicKey(network: network);
  final publicMasterWallet = HdWallet.fromXpublicKey(xPublic);

  /// derive new path from master wallet
  HdWallet.drivePath(masterWallet, "m/44'/0'/0'/0/0/0");

  /// derive new path from public wallet
  final publicWallet = HdWallet.drivePath(publicMasterWallet, "m/0/1");

  final publicKey = publicWallet.publicKey;

  /// return public key
  publicKey.toHex(compressed: true);

  /// p2pkh address for testnet network
  /// mxukNgWdBF1ibtpCpnNnPR5Zz2FPjvyuCf
  publicKey.toAddress().toAddress(network);

  /// p2sh(p2pk) address for testnet network
  /// 2NE2r3EK7fFYZREaNFVLyEw2UcEUEGjVgF2
  publicKey.toP2pkInP2sh().toAddress(network);

  /// p2sh(p2pkh) address for testnet network
  /// 2MyaJKV4g1R5pWA4LC16pqVqDFtGrn134nP
  publicKey.toP2pkhInP2sh().toAddress(network);

  /// p2sh(p2wpkh) address for testnet network
  /// 82VHvngNBzjXsb5ZUqHD5hgXKdUdstLsA
  final e = publicKey.toP2wpkhInP2sh().toAddress(network);
  print("e $e");

  /// p2sh(p2wsh) address for testnet network 1-1 multisig segwit script
  /// JuynVHdGZY362FodskamvvWSP9Jj58KgA
  final x = publicKey.toP2wshInP2sh().toAddress(network);
  print("x $x");

  /// p2wpkh address
  /// tb1qhmyuz38dy22qlspdnwl6khsycvjpeallzwwcp7
  publicKey.toSegwitAddress().toAddress(network);

  /// p2wsh address 1-1 multisig segwit script
  /// tb1qax8ahkqhm2cvappkdqupjp7w07ervya3rllpechnez6j7hzu7hqq963clk
  publicKey.toP2wshAddress().toAddress(network);

  /// p2tr address
  /// tb1p6hwljzyudccfd3d9ckrh5wqmx786kenmu0caud0ru6e3k2yc5rdq76sw7y
  publicKey.toTaprootAddress().toAddress(network);
}
