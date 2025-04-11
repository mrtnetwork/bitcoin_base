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

Future<void> _sendDashTestNet(String digets) async {
  final params = {"rawtx": digets};
  final cl = http.Client();
  final res = await cl.post(
      Uri.parse("https://testnet-insight.dashevo.org/insight-api/tx/send"),
      body: jsonEncode(params),
      headers: {"Content-Type": "application/json"});
}

void _spendFromTwoP2shAndOneP2PKH() async {
  /// Define network
  const network = DashNetwork.testnet;

  /// Define a seed using a hex string
  final seed = BytesUtils.fromHexString(
      "50b112c15987f0f1aa58430b6e1364cb4ac216a96b4a1e5030d63f62c3e13f0e9d5cfa97eb28584d112a7eddf53a0ca9f3ea58183f42c28f861162225bdab836");

  /// Create a Bip32 key from the seed
  final bip32 = Bip32Slip10Secp256k1.fromSeed(seed);

  /// Generate child keys from the master key
  final childKey1 = bip32.childKey(Bip32KeyIndex(1));

  /// Convert child key public keys to ECPublic objects
  final childKey1PublicKey = ECPublic.fromBytes(childKey1.publicKey.compressed);

  /// Define another private key from wif
  final ECPrivate examplePrivateKey = ECPrivate.fromWif(
      'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
      netVersion: BitcoinNetwork.testnet.wifNetVer);
  final examplePublicKey2 = examplePrivateKey.getPublic();

  /// Calculate the change value for the transaction
  final change = _changeValue(

      /// sum of utxos
      BtcUtils.toSatoshi("3.00868475"),
      [
        /// Transaction fee
        BtcUtils.toSatoshi("0.00001"),
        BtcUtils.toSatoshi("2"),
      ]);

  /// outputs
  /// make sure pass network to address for validate, before sending create transaction

  /// Create a P2shAddress instance from the specified Dash address and network
  final out1 = P2shAddress.fromAddress(
      address: "92zk9KpCW7qNtWVspFGYBtvuNk85gynddH", network: network);

  /// Create a P2shAddress instance from the specified Dash address and network
  final out2 = P2shAddress.fromAddress(
      address: "8oz6iBBbm9jzJb9b12TZrgjgEpURp357Zh", network: network);

  /// Create a P2pkhAddress instance from the specified Dash address and network
  final out3 = P2pkhAddress.fromAddress(
      address: "yYmCkTAZcjcTmWMY6z7izSjDasauxXvubm", network: network);

  final b = BitcoinTransactionBuilder(

      /// outputs
      outPuts: [
        /// Define a BitcoinOutput with the P2shAddress and a value of 1.0 DASH
        BitcoinOutput(address: out1, value: BtcUtils.toSatoshi("1")),

        /// Define a BitcoinOutput with the P2shAddress and a value of 1.0 DASH
        BitcoinOutput(address: out2, value: BtcUtils.toSatoshi("1")),

        /// Define a BitcoinOutput with the P2pkhAddress and a value equal to the 'change' variable
        BitcoinOutput(address: out3, value: change),
      ],

      /// Set the transaction fee to 0.00001 DASH
      fee: BtcUtils.toSatoshi("0.00001"),

      /// Specify the network for the litcoin transaction
      network: network,

      /// Define a list of Unspent Transaction Outputs (UTXOs) for the Bitcoin transaction
      utxos: [
        UtxoWithAddress(

            /// Create a UTXO using a BitcoinUtxo with specific details
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "5ffb1ab349d4c844da4c7995658edfba8bf5aa28aa1c57d69f5dcc17a49a019e",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("3.00868475"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 2,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: examplePublicKey2.toAddress().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey2.toHex(),
                address: examplePublicKey2.toAddress())),
      ]);

  /// Build the transaction by invoking the buildTransaction method on the BitcoinTransactionBuilder
  final tr = b.buildTransaction((trDigest, utxo, publicKey, sighash) {
    /// For each input in the transaction, locate the corresponding private key
    /// and sign the transaction digest to construct the unlocking script.
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
  /// https://testnet-insight.dashevo.org/insight/tx/65e21f67d58272b9baf582e81b3ba25dfaa8129dfcbe90e3d7d4a42f25cea372
  await _sendDashTestNet(tr.serialize());
}

void _spendP2SH() async {
  /// Define network
  const network = DashNetwork.testnet;

  /// Define a seed using a hex string
  final seed = BytesUtils.fromHexString(
      "50b112c15987f0f1aa58430b6e1364cb4ac216a96b4a1e5030d63f62c3e13f0e9d5cfa97eb28584d112a7eddf53a0ca9f3ea58183f42c28f861162225bdab836");

  /// Create a Bip32 key from the seed
  final bip32 = Bip32Slip10Secp256k1.fromSeed(seed);

  /// Generate child keys from the master key
  final childKey1 = bip32.childKey(Bip32KeyIndex(1));

  /// Convert child key private keys to ECPrivate objects
  final childKey1PrivateKey = ECPrivate.fromBytes(childKey1.privateKey.raw);

  /// Convert child key public keys to ECPublic objects
  final childKey1PublicKey = ECPublic.fromBytes(childKey1.publicKey.compressed);

  /// Calculate the change value for the transaction
  final change = _changeValue(

      /// sum of utxos
      BtcUtils.toSatoshi("1"),
      [
        BtcUtils.toSatoshi("0.00001"),
      ]);

  /// outputs
  /// make sure pass network to address for validate, before sending create transaction

  /// Create a P2pkhAddress instance from the specified DASH address and network
  final out1 = P2pkhAddress.fromAddress(
      address: "yYmCkTAZcjcTmWMY6z7izSjDasauxXvubm", network: network);

  final b = BitcoinTransactionBuilder(

      /// outputs
      outPuts: [
        BitcoinOutput(address: out1, value: change),
      ],

      /// Set the transaction fee to 0.00001 DASH
      fee: BtcUtils.toSatoshi("0.00001"),

      /// Specify the network for the litcoin transaction
      network: network,

      /// Define a list of Unspent Transaction Outputs (UTXOs) for the Bitcoin transaction
      utxos: [
        UtxoWithAddress(

            /// Create a UTXO using a BitcoinUtxo with specific details
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "65e21f67d58272b9baf582e81b3ba25dfaa8129dfcbe90e3d7d4a42f25cea372",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("1"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 1,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: childKey1PublicKey.toP2pkhInP2sh().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: childKey1PublicKey.toHex(),
                address: childKey1PublicKey.toP2pkhInP2sh())),
      ]);

  /// Build the transaction by invoking the buildTransaction method on the BitcoinTransactionBuilder
  final tr = b.buildTransaction((trDigest, utxo, publicKey, sighash) {
    /// For each input in the transaction, locate the corresponding private key
    /// and sign the transaction digest to construct the unlocking script.
    if (publicKey == childKey1PublicKey.toHex()) {
      return childKey1PrivateKey.signECDSA(trDigest, sighash: sighash);
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
  /// https://testnet-insight.dashevo.org/insight/address/yYmCkTAZcjcTmWMY6z7izSjDasauxXvubm
  await _sendDashTestNet(tr.serialize());
}
