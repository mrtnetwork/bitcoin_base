// ignore_for_file: unused_element, unused_local_variable

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

Future<void> _broadcastTransaction(String digets) async {
  final params = {
    "jsonrpc": "2.0",
    "API_key": "27c54568-c97c-49a6-8667-993f8de2d4d8",
    "method": "sendrawtransaction",
    "params": [digets]
  };
  final cl = http.Client();
  final res = await cl.post(Uri.parse("https://ltc-testnet.nownodes.io"),
      body: jsonEncode(params), headers: {"Content-Type": "application/json"});
}

void main() {
  _spendLTCP2pkhAddress();
}

void _spendLTCP2pkhAddress() async {
  /// Define network
  const network = LitecoinNetwork.testnet;

  /// Define private key from wif
  final ECPrivate examplePrivateKey = ECPrivate.fromWif(
      'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
      netVersion: BitcoinNetwork.testnet.wifNetVer);

  /// public key of signer
  final pub = examplePrivateKey.getPublic();

  final change = _changeValue(

      /// sum of utxos
      BtcUtils.toSatoshi("0.000298"),
      [
        /// Transaction fee
        BtcUtils.toSatoshi("0.00001"),

        /// output 1
        BtcUtils.toSatoshi("0.0001"),

        /// outpu2
        BtcUtils.toSatoshi("0.0001")
      ]);

  /// outputs
  /// make sure pass network to address for validate, before sending create transaction

  /// Create a P2shAddress instance from the specified Litecoin address and network
  final out1 = P2shAddress.fromAddress(
      address: "QhVxfepyv8mKJrB6sTfLUB3zkAmSZnRsoZ", network: network);

  /// Create another P2shAddress instance from the same Litecoin address and network
  final out2 = P2shAddress.fromAddress(
      address: "QhVxfepyv8mKJrB6sTfLUB3zkAmSZnRsoZ", network: network);

  /// Create a third P2shAddress instance from a different Litecoin address but the same network
  final out3 = P2shAddress.fromAddress(
      address: "QQdBn9ocKyddTpUjTVyjq6G7HgcGuPuE5X", network: network);

  /// Calculate the change value for the transaction
  final builder = BitcoinTransactionBuilder(

      /// outputs
      outPuts: [
        /// Define a BitcoinOutput with the first P2shAddress and a value of 0.0001 LTC
        BitcoinOutput(address: out1, value: BtcUtils.toSatoshi("0.0001")),

        /// Define another BitcoinOutput with the second P2shAddress and a value of 0.0001 LTC
        BitcoinOutput(address: out2, value: BtcUtils.toSatoshi("0.0001")),

        /// Define a BitcoinOutput with the third P2shAddress and a value equal to the 'change' variable
        BitcoinOutput(address: out3, value: change),
      ],

      /// Set the transaction fee to 0.00001 LTC
      fee: BtcUtils.toSatoshi("0.00001"),

      /// Specify the network for the litcoin transaction
      network: network,

      /// Add a memo to the transaction, linking to the GitHub repository
      memo: "https://github.com/mrtnetwork",

      /// Define a list of Unspent Transaction Outputs (UTXOs) for the Bitcoin transaction
      utxos: [
        UtxoWithAddress(

            /// Create a UTXO using a BitcoinUtxo with specific details
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "f28d3ce9befa466533ba0f4c03fb2b561b809a41053a2ae76296be72c4f2c28d",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("0.000298"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 3,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: pub.toAddress().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: pub.toHex(), address: pub.toAddress())),
      ]);

  /// Build the transaction by invoking the buildTransaction method on the BitcoinTransactionBuilder
  final tr = builder.buildTransaction((trDigest, utxo, publicKey, sighash) {
    /// For each input in the transaction, locate the corresponding private key
    /// and sign the transaction digest to construct the unlocking script.
    if (publicKey == pub.toHex()) {
      /// sign the transaction input using specified sighash or default to SIGHASH_ALL
      return examplePrivateKey.signECDSA(trDigest, sighash: sighash);
    }

    throw UnimplementedError();
  });

  /// Get the transaction ID
  final txId = tr.txId();

  /// Calculate the size of the transaction in bytes.
  /// You can determine the transaction fee by multiplying the transaction size
  /// Formula: transaction fee = (transaction size in bytes * fee rate in bytes)
  final size = tr.hasWitness ? tr.getVSize() : tr.getSize();

  /// broadcast transaction
  await _broadcastTransaction(tr.serialize());
  // tx https://chain.so/tx/LTCTEST/cdb6281e8bd1062adad50dac8ca45248118f6b59f93d9f3ced963958948ca5a2
}

void _spendFrom2P2shAddressAndOneMultiSigP2shAddress() async {
  /// Define network
  const network = LitecoinNetwork.testnet;

  /// Define a seed using a hex string
  final seed = BytesUtils.fromHexString(
      "50b112c15987f0f1aa58430b6e1364cb4ac216a96b4a1e5030d63f62c3e13f0e9d5cfa97eb28584d112a7eddf53a0ca9f3ea58183f42c28f861162225bdab836");

  /// Create a Bip32 key from the seed
  final bip32 = Bip32Slip10Secp256k1.fromSeed(seed);

  /// Generate child keys from the master key
  final childKey1 = bip32.childKey(Bip32KeyIndex(1));
  final childKey = bip32.childKey(Bip32KeyIndex(3));

  /// Convert child key public keys to ECPublic objects
  final childKey1PrivateKey = ECPrivate.fromBytes(childKey1.privateKey.raw);
  final childKey1PublicKey = ECPublic.fromBytes(childKey1.publicKey.compressed);
  final childKey2PrivateKey = ECPrivate.fromBytes(childKey.privateKey.raw);
  final examplePublicKey = ECPublic.fromBytes(childKey.publicKey.compressed);
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

  /// outputs
  /// make sure pass network to address for validate, before sending create transaction

  /// Create a P2shAddress instance from the specified Litecoin address and network
  final out1 = P2shAddress.fromAddress(
      address: "QhVxfepyv8mKJrB6sTfLUB3zkAmSZnRsoZ", network: network);

  /// Calculate the change value for the transaction
  final change = _changeValue(

      /// sum of utxos
      BtcUtils.toSatoshi("0.000288"),
      [
        /// Transaction fee
        BtcUtils.toSatoshi("0.00001"),
      ]);

  final builder = BitcoinTransactionBuilder(

      /// outputs
      outPuts: [
        /// Define a BitcoinOutput with the third P2shAddress and a value equal to the 'change' variable
        BitcoinOutput(address: out1, value: change),
      ],

      /// Set the transaction fee to 0.00001 LTC
      fee: BtcUtils.toSatoshi("0.00001"),

      /// Specify the network for the litcoin transaction
      network: network,

      /// Add a memo to the transaction, linking to the GitHub repository
      memo: "https://github.com/mrtnetwork",

      /// Define a list of Unspent Transaction Outputs (UTXOs) for the Bitcoin transaction
      utxos: [
        UtxoWithAddress(

            /// Create a UTXO using a BitcoinUtxo with specific details
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "cdb6281e8bd1062adad50dac8ca45248118f6b59f93d9f3ced963958948ca5a2",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("0.0001"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 0,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: examplePublicKey.toP2wpkhInP2sh().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey.toHex(),
                address: examplePublicKey.toP2wpkhInP2sh())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash:
                  "cdb6281e8bd1062adad50dac8ca45248118f6b59f93d9f3ced963958948ca5a2",
              value: BtcUtils.toSatoshi("0.0001"),
              vout: 1,
              scriptType: examplePublicKey.toP2wpkhInP2sh().type,
            ),
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey.toHex(),
                address: examplePublicKey.toP2wpkhInP2sh())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash:
                  "cdb6281e8bd1062adad50dac8ca45248118f6b59f93d9f3ced963958948ca5a2",
              value: BtcUtils.toSatoshi("0.000088"),
              vout: 2,
              scriptType: msig.toP2shAddress().type,
            ),

            /// Include owner details with the multisigAddress instead publickey and address associated with the UTXO
            ownerDetails: UtxoAddressDetails.multiSigAddress(
                multiSigAddress: msig, address: msig.toP2shAddress())),
      ]);

  /// Build the transaction by invoking the buildTransaction method on the BitcoinTransactionBuilder instance (b)
  final tr = builder.buildTransaction((trDigest, utxo, publicKey, int sighash) {
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
  final size = tr.hasWitness ? tr.getVSize() : tr.getSize();

  /// broadcast transaction
  await _broadcastTransaction(tr.serialize());

  /// https://chain.so/tx/LTCTEST/f2d2a37b90dd7d51002fae6684ebbbea58430e5b59d7c96271c5d3ef58c72a9d
}

void _spendFromNestedSegwitP2WPKHInP2SH() async {
  /// Define network
  const network = LitecoinNetwork.testnet;

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

  /// Define other private key from wif
  final ECPrivate examplePrivateKey = ECPrivate.fromWif(
      'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
      netVersion: BitcoinNetwork.testnet.wifNetVer);
  final examplePublicKey2 = examplePrivateKey.getPublic();

  final change = _changeValue(
      BtcUtils.toSatoshi("0.000278"), [BtcUtils.toSatoshi("0.00001")]);

  /// outputs
  /// make sure pass network to address for validate, before sending create transaction

  /// Create a P2wpkhAddress instance from the specified Litecoin address and network
  final out1 = P2wpkhAddress.fromAddress(
      address: "tltc1qeahaz6slvja7qep3tnwx6va2aw5dttxtyqy6wr",
      network: network);

  final builder = BitcoinTransactionBuilder(

      /// outputs
      outPuts: [
        /// Define a BitcoinOutput with the third P2wpkhAddress and a value equal to the 'change' variable
        BitcoinOutput(address: out1, value: change),
      ],

      /// Set the transaction fee to 0.00001 LTC
      fee: BtcUtils.toSatoshi("0.00001"),

      /// Specify the network for the litcoin transaction
      network: network,

      /// Add a memo to the transaction, linking to the GitHub repository
      memo: "https://github.com/mrtnetwork",
      utxos: [
        UtxoWithAddress(

            /// Create a UTXO using a BitcoinUtxo with specific details
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "f2d2a37b90dd7d51002fae6684ebbbea58430e5b59d7c96271c5d3ef58c72a9d",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("0.000278"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 0,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: examplePublicKey.toP2wpkhInP2sh().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey.toHex(),
                address: examplePublicKey.toP2wpkhInP2sh())),
      ]);

  /// Build the transaction by invoking the buildTransaction method on the BitcoinTransactionBuilder instance (builder)
  final tr = builder.buildTransaction((trDigest, utxo, publicKey, sighash) {
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
  final size = tr.hasWitness ? tr.getVSize() : tr.getSize();

  /// broadcast transaction
  await _broadcastTransaction(tr.serialize());

  /// https://chain.so/tx/LTCTEST/a5ae31becf95c8a109cedec4cdde5b05edda14593876f97864e59fd1db970e6b
}

void _spendFromSegwitP2WPKHAddress() async {
  /// Define network
  const network = LitecoinNetwork.testnet;

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

  /// add another private key using wif
  final ECPrivate examplePrivateKey = ECPrivate.fromWif(
      'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
      netVersion: BitcoinNetwork.testnet.wifNetVer);
  final examplePublicKey2 = examplePrivateKey.getPublic();

  /// Calculate the change value for the transaction
  final change = _changeValue(

      /// sum of utxos
      BtcUtils.toSatoshi("0.000268"),
      [
        /// Transaction fee
        BtcUtils.toSatoshi("0.00001"),
      ]);

  /// outputs
  /// make sure pass network to address for validate, before sending create transaction

  /// Create a P2pkhAddress instance from the specified Litecoin address and network
  final input1 = P2pkhAddress.fromAddress(
      address: "msxiCJXD2WB43wK2PpTUvoqQLF7ZP98qqM", network: network);

  final builder = BitcoinTransactionBuilder(

      /// outputs
      outPuts: [
        /// Define a BitcoinOutput with the third P2pkhAddress and a value equal to the 'change' variable
        BitcoinOutput(address: input1, value: change),
      ],

      /// Set the transaction fee to 0.00001 LTC
      fee: BtcUtils.toSatoshi("0.00001"),

      /// Specify the network for the litcoin transaction
      network: network,

      /// Add a memo to the transaction, linking to the GitHub repository
      memo: "https://github.com/mrtnetwork",

      /// Define a list of Unspent Transaction Outputs (UTXOs) for the Bitcoin transaction
      utxos: [
        UtxoWithAddress(

            /// Create a UTXO using a BitcoinUtxo with specific details
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "a5ae31becf95c8a109cedec4cdde5b05edda14593876f97864e59fd1db970e6b",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("0.000268"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 0,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: examplePublicKey.toSegwitAddress().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey.toHex(),
                address: examplePublicKey.toSegwitAddress())),
      ]);

  /// Build the transaction by invoking the buildTransaction method on the BitcoinTransactionBuilder instance (builder)
  final tr = builder.buildTransaction((trDigest, utxo, publicKey, int sighash) {
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
  final size = tr.hasWitness ? tr.getVSize() : tr.getSize();

  /// broadcast transaction
  await _broadcastTransaction(tr.serialize());

  /// https://chain.so/tx/LTCTEST/f447c1a14e38329d6688fb37fc8838e2f76d8ffd69604d4a42721d21ed0dd6eb
}
