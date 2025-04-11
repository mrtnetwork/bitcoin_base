// ignore_for_file: unused_local_variable, unused_element

import 'dart:convert';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:http/http.dart' as http;

BigInt _changeValue(BigInt sum, List<BigInt> all) {
  final sumAll = all.fold<BigInt>(
      BigInt.zero, (previousValue, element) => previousValue + element);

  final remind = sum - sumAll;
  if (remind < BigInt.zero) {
    throw ArgumentError("invalid values");
  }
  return remind;
}

Future<void> _sendDOGETestnet(String digets) async {
  final params = {
    "jsonrpc": "2.0",
    "API_key": "27c54568-c97c-49a6-8667-993f8de2d4d8",
    "method": "sendrawtransaction",
    "params": [digets]
  };
  final cl = http.Client();
  final res = await cl.post(Uri.parse("https://doge-testnet.nownodes.io"),
      body: jsonEncode(params), headers: {"Content-Type": "application/json"});
}

void _spendFrom3P2shAddress() async {
  /// Define network
  const network = DogecoinNetwork.testnet;

  /// Define a seed using a hex string
  final seed = BytesUtils.fromHexString(
      "50b112c15987f0f1aa58430b6e1364cb4ac216a96b4a1e5030d63f62c3e13f0e9d5cfa97eb28584d112a7eddf53a0ca9f3ea58183f42c28f861162225bdab836");

  /// Create a Bip32 key from the seed
  final bip32 = Bip32Slip10Secp256k1.fromSeed(seed);

  /// Generate child keys from the master key
  final childKey1 = bip32.childKey(Bip32KeyIndex(1));
  final childKey = bip32.childKey(Bip32KeyIndex(3));

  /// Convert child key private keys to ECPrivate objects
  final childKey1PrivateKey = ECPrivate.fromBytes(childKey1.privateKey.raw);
  final childKey2PrivateKey = ECPrivate.fromBytes(childKey.privateKey.raw);

  /// Convert child key public keys to ECPublic objects
  final childKey1PublicKey = ECPublic.fromBytes(childKey1.publicKey.compressed);
  final examplePublicKey = ECPublic.fromBytes(childKey.publicKey.compressed);

  /// Define another private key using wif
  final ECPrivate examplePrivateKey = ECPrivate.fromWif(
      'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
      netVersion: BitcoinNetwork.testnet.wifNetVer);
  final examplePublicKey2 = examplePrivateKey.getPublic();

  /// Calculate the change value for the transaction
  final change = _changeValue(

      /// sum of utxos
      BtcUtils.toSatoshi("10"),
      [
        BtcUtils.toSatoshi("2"),

        /// Transaction fee
        BtcUtils.toSatoshi("0.1"),
      ]);

  /// Create a P2shAddress instance from the specified DOGE address and network
  final out1 = P2shAddress.fromAddress(
      address: "2NDAUpeUB1kGAQET8SojF8seXNrk3uudtCb", network: network);

  /// Create a P2shAddress instance from the specified DOGE address and network
  final out2 = P2shAddress.fromAddress(
      address: "2N5hVdETdJMwLDxxttfqeWgMuny6K4SYGSc", network: network);

  /// Create a P2shAddress instance from the specified DOGE address and network
  final out3 = P2shAddress.fromAddress(
      address: "2MwGRf8wNJsaYKdigqPwikPpg9JAT2faaPB", network: network);

  final builder = BitcoinTransactionBuilder(

      /// outputs
      outPuts: [
        /// Define a BitcoinOutput with the P2shAddress and a value of 1 DOGE
        BitcoinOutput(address: out1, value: BtcUtils.toSatoshi("1")),

        /// Define another BitcoinOutput with the P2shAddress and a value of 1 DOGE
        BitcoinOutput(address: out2, value: BtcUtils.toSatoshi("1")),

        /// Define a BitcoinOutput with the P2shAddress and a value equal to the 'change' variable
        BitcoinOutput(address: out3, value: change),
      ],

      /// Set the transaction fee to 0.1 DOGE
      fee: BtcUtils.toSatoshi("0.1"),

      /// Specify the network for the DOGE transaction
      network: network,

      /// Define a list of Unspent Transaction Outputs (UTXOs) for the Bitcoin transaction
      utxos: [
        UtxoWithAddress(

            /// Create a UTXO using a BitcoinUtxo with specific details
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "984919f048558cee05a7341452fdd0f12f1d0b3968f4b7155d3b5e1e6be1d969",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("10"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 1,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: childKey1PublicKey.toAddress().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: childKey1PublicKey.toHex(),
                address: childKey1PublicKey.toAddress())),
      ]);
  final tr = builder.buildTransaction((trDigest, utxo, publicKey, sighash) {
    if (publicKey == childKey1PublicKey.toHex()) {
      return childKey1PrivateKey.signECDSA(trDigest, sighash: sighash);
    }
    if (publicKey == examplePublicKey.toHex()) {
      return childKey2PrivateKey.signECDSA(trDigest, sighash: sighash);
    }
    if (publicKey == examplePublicKey2.toHex()) {
      return examplePrivateKey.signECDSA(trDigest, sighash: sighash);
    }

    throw UnimplementedError();
  });

  /// Get the transaction ID
  final txId = tr.txId();

  /// Calculate the size of the transaction in bytes.
  /// You can determine the transaction fee by multiplying the transaction size
  /// Formula: transaction fee = (transaction size in bytes * fee rate in bytes)
  final size = tr.getSize();

  /// broadcast transaction
  /// https://sochain.com/tx/DOGETEST/641f23c3555229ba494d56138b06daf9cd0e00dccd4697a355e6ba48cf057ce0
  await _sendDOGETestnet(tr.serialize());
}

void _spendFromP2pkhAndP2sh() async {
  /// Define network
  const network = DogecoinNetwork.testnet;

  /// Define a seed using a hex string
  final seed = BytesUtils.fromHexString(
      "50b112c15987f0f1aa58430b6e1364cb4ac216a96b4a1e5030d63f62c3e13f0e9d5cfa97eb28584d112a7eddf53a0ca9f3ea58183f42c28f861162225bdab836");

  /// Create a Bip32 key from the seed
  final bip32 = Bip32Slip10Secp256k1.fromSeed(seed);

  /// Generate child keys from the master key
  final childKey1 = bip32.childKey(Bip32KeyIndex(1));
  final childKey = bip32.childKey(Bip32KeyIndex(3));

  /// Convert child key private keys to ECPrivate objects
  final childKey1PrivateKey = ECPrivate.fromBytes(childKey1.privateKey.raw);
  final childKey2PrivateKey = ECPrivate.fromBytes(childKey.privateKey.raw);

  /// Convert child key public keys to ECPublic objects
  final childKey1PublicKey = ECPublic.fromBytes(childKey1.publicKey.compressed);
  final examplePublicKey = ECPublic.fromBytes(childKey.publicKey.compressed);

  /// Define another private key with wif
  final ECPrivate examplePrivateKey = ECPrivate.fromWif(
      'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
      netVersion: BitcoinNetwork.testnet.wifNetVer);
  final examplePublicKey2 = examplePrivateKey.getPublic();

  /// Create a MultiSignatureAddress with two signers and a threshold of 2
  /// script = [OP_2, ch2PubPublicKey, ch1PubPublicKey, OP_2, OP_CHECKMULTISIG]
  final msig = MultiSignatureAddress(threshold: 2, signers: [
    MultiSignatureSigner(publicKey: examplePublicKey.toHex(), weight: 1),
    MultiSignatureSigner(publicKey: childKey1PublicKey.toHex(), weight: 1),
  ]);

  /// Calculate the change value for the transaction
  final change = _changeValue(

      /// sum of utxos
      BtcUtils.toSatoshi("2"),
      [
        BtcUtils.toSatoshi("1"),

        /// Transaction fee
        BtcUtils.toSatoshi("0.1"),
      ]);

  /// Create a P2pkhAddress instance from the specified DOGE address and network
  final out1 = P2pkhAddress.fromAddress(
      address: "no6z6ET6d9XondVKacbs6LUPWqKhNF6dKQ", network: network);

  /// Create another P2shAddress instance from the same DOGE address and network
  final out2 = P2shAddress.fromAddress(
      address: "2MwGRf8wNJsaYKdigqPwikPpg9JAT2faaPB", network: network);

  final b = BitcoinTransactionBuilder(

      /// outputs
      outPuts: [
        /// Define a BitcoinOutput with the P2pkhAddress and a value of 1.0 DOGE
        BitcoinOutput(address: out1, value: BtcUtils.toSatoshi("1")),

        /// Define a BitcoinOutput with the P2shAddress and a value equal to the 'change' variable
        BitcoinOutput(address: out2, value: change),
      ],

      /// Set the transaction fee to 0.1 DOGE
      fee: BtcUtils.toSatoshi("0.1"),

      /// Specify the network for the DOGE transaction
      network: network,

      /// Add a memo to the transaction
      memo: "MRTNETWORK.com",

      /// Define a list of Unspent Transaction Outputs (UTXOs) for the Bitcoin transaction
      utxos: [
        /// Create a UTXO using a BitcoinUtxo with specific details
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "641f23c3555229ba494d56138b06daf9cd0e00dccd4697a355e6ba48cf057ce0",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("1"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 0,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: examplePublicKey.toP2pkhInP2sh().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey.toHex(),
                address: examplePublicKey.toP2pkhInP2sh())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "641f23c3555229ba494d56138b06daf9cd0e00dccd4697a355e6ba48cf057ce0",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("1"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 1,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: examplePublicKey.toP2pkInP2sh().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey.toHex(),
                address: examplePublicKey.toP2pkInP2sh())),
      ]);

  /// Build the transaction by invoking the buildTransaction method on the BitcoinTransactionBuilder
  final tr = b.buildTransaction((trDigest, utxo, publicKey, sighash) {
    /// For each input in the transaction, locate the corresponding private key
    /// and sign the transaction digest to construct the unlocking script.
    if (publicKey == childKey1PublicKey.toHex()) {
      return childKey1PrivateKey.signECDSA(trDigest, sighash: sighash);
    }
    if (publicKey == examplePublicKey.toHex()) {
      return childKey2PrivateKey.signECDSA(trDigest, sighash: sighash);
    }
    if (publicKey == examplePublicKey2.toHex()) {
      return examplePrivateKey.signECDSA(trDigest, sighash: sighash);
    }

    throw UnimplementedError();
  });

  /// Get the transaction ID
  final txId = tr.txId();

  /// Calculate the size of the transaction in bytes.
  /// You can determine the transaction fee by multiplying the transaction size
  /// Formula: transaction fee = (transaction size in bytes * fee rate in bytes)
  final size = tr.getSize();

  /// broadcast transaction
  /// https://sochain.com/tx/DOGETEST/af740d12060b64b0ccf41a1a31aebb43b2a457410d5835a2d54152d2d79034e9
  await _sendDOGETestnet(tr.serialize());
}
