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

Future<void> _brodcastTrasaction(String digets) async {
  final params = {
    "jsonrpc": "2.0",
    "API_key": "27c54568-c97c-49a6-8667-993f8de2d4d8",
    "method": "sendrawtransaction",
    "params": [digets]
  };
  final cl = http.Client();
  final res = await cl.post(
      Uri.parse("https://go.getblock.io/2359f3004aef4fbba3a1c70f62f660d8"),
      body: jsonEncode(params),
      headers: {"Content-Type": "application/json"});
}

void _spendFrom2P2SHAnd2P2PKHAddress() async {
  /// Define network
  const network = BitcoinCashNetwork.testnet;

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

  /// Define another private key using WIF
  final ECPrivate examplePrivateKey = ECPrivate.fromWif(
      'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
      netVersion: BitcoinNetwork.testnet.wifNetVer);
  final examplePublicKey2 = examplePrivateKey.getPublic();

  final msig2 = MultiSignatureAddress(threshold: 3, signers: [
    MultiSignatureSigner(publicKey: examplePublicKey.toHex(), weight: 1),
    MultiSignatureSigner(publicKey: childKey1PublicKey.toHex(), weight: 2),
  ]);

  /// outputs
  /// make sure pass network to address for validate, before sending create transaction

  /// Create a P2shAddress instance from the specified BCH address and network
  final out1 = P2shAddress.fromAddress(
      address: "bchtest:pz2mcmtv8ect77a0fjqhl2cwcqswmvfq3qsxe5rq9r",
      network: network);

  /// Create a P2shAddress instance from the specified BCH address and network
  final out2 = P2shAddress.fromAddress(
      address: "bchtest:pp5w24ym8f7h8aspam24hk5msvz6yr9djvlguqda4e",
      network: network);

  /// Create a P2pkhAddress instance from the specified BCH address and network
  final out3 = P2pkhAddress.fromAddress(
      address: "bchtest:qr8kl5t2rajthcryx9wdcmfn4t4634dvev5ly5ewas",
      network: network);

  /// Create a P2shAddress instance from the specified BCH address and network
  final out4 = P2pkhAddress.fromAddress(
      address: "bchtest:pq7w6zt4vcv33yg54y3xfemm3k5d0ahceqmdanzcmz",
      network: network);

  /// Calculate the change value for the transaction
  final change = _changeValue(

      /// sum of utxos
      BtcUtils.toSatoshi("0.101"),
      [
        BtcUtils.toSatoshi("0.03"),

        /// Transaction fee
        BtcUtils.toSatoshi("0.00003"),
      ]);

  final b = ForkedTransactionBuilder(
      outPuts: [
        /// Define a BitcoinOutput with the P2shAddress and a value of 0.01 BCH
        BitcoinOutput(address: out1, value: BtcUtils.toSatoshi("0.01")),

        /// Define a BitcoinOutput with the P2shAddress and a value of 0.01 BCH
        BitcoinOutput(address: out2, value: BtcUtils.toSatoshi("0.01")),

        /// Define a BitcoinOutput with the P2pkhAddress and a value of 0.01 BCH
        BitcoinOutput(address: out3, value: BtcUtils.toSatoshi("0.01")),

        /// Define a BitcoinOutput with the P2shAddress and a value equal to the 'change' variable
        BitcoinOutput(address: out4, value: change),
      ],

      /// Set the transaction fee to 0.00003 BCH
      fee: BtcUtils.toSatoshi("0.00003"),

      /// Specify the network for the litcoin transaction
      network: network,

      /// Define a list of Unspent Transaction Outputs (UTXOs) for the Bitcoin transaction
      utxos: [
        UtxoWithAddress(

            /// Create a UTXO using a BitcoinUtxo with specific details
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "fffd7bd09acdf87d383bb60d698f170fc4c3e74ebf50700e3724ae9a566d1b9b",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("0.101"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 0,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: examplePublicKey2.toAddress().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey2.toHex(),
                address: examplePublicKey2.toAddress())),
      ]);

  /// Build the transaction by invoking the buildTransaction method on the ForkedTransactionBuilder
  final tr = b.buildTransaction((trDigest, utxo, publicKey, int sighash) {
    /// For each input in the transaction, locate the corresponding private key
    /// and sign the transaction digest to construct the unlocking script.
    if (publicKey == childKey1PublicKey.toHex()) {
      return childKey1PrivateKey.signInput(trDigest, sigHash: sighash);
    }
    if (publicKey == examplePublicKey.toHex()) {
      return childKey2PrivateKey.signInput(trDigest, sigHash: sighash);
    }
    if (publicKey == examplePublicKey2.toHex()) {
      return examplePrivateKey.signInput(trDigest, sigHash: sighash);
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
  /// https://tbch.loping.net/tx/ece972a6d5d1b07062ed5aaab786b528b04a3cf675affdda8cb79ec805c53ce2
  await _brodcastTrasaction(tr.serialize());
}

void _spendFrom2P2SHAnd1P2PKHAddress() async {
  /// Define network
  const network = BitcoinCashNetwork.testnet;

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

  /// Define another private key from WIF
  final ECPrivate examplePrivateKey = ECPrivate.fromWif(
      'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
      netVersion: BitcoinNetwork.testnet.wifNetVer);
  final examplePublicKey2 = examplePrivateKey.getPublic();

  /// Create a MultiSignatureAddress with two signers and a threshold of 3
  /// script = [OP_3, ch2PubPublicKey, ch1PubPublicKey,ch1PubPublicKey, OP_3, OP_CHECKMULTISIG]
  final msig2 = MultiSignatureAddress(threshold: 3, signers: [
    MultiSignatureSigner(publicKey: examplePublicKey.toHex(), weight: 1),
    MultiSignatureSigner(publicKey: childKey1PublicKey.toHex(), weight: 2),
  ]);

  /// Calculate the change value for the transaction
  final change = _changeValue(

      /// sum of utxos
      BtcUtils.toSatoshi("0.10097"),
      [
        BtcUtils.toSatoshi("0.02"),

        /// Transaction fee
        BtcUtils.toSatoshi("0.00003"),
      ]);

  /// outputs
  /// make sure pass network to address for validate, before sending create transaction

  /// Create a P2pkhAddress instance from the specified BCH address and network
  final out1 = P2pkhAddress.fromAddress(
      address: "bchtest:qr7nx7knh7q7ppkedf5wr7xk5zj3p7xzfgapvt5csc",
      network: network);

  /// Create a P2shAddress instance from the specified BCH address and network
  final out2 = P2shAddress.fromAddress(
      address: "bchtest:pz4xpuvkmtuz9k9rksdv5lnu5q6jqvc8hus60get4a",
      network: network);

  /// Create a P2shAddress instance from the specified BCH address and network
  final out3 = P2shAddress.fromAddress(
      address: "bchtest:prs0e39dpv0j2ysj00cec4t4x2k4833dsvmxeq8fr0",
      network: network);

  /// Calculate the change value for the transaction
  final b = ForkedTransactionBuilder(

      /// outputs
      outPuts: [
        /// Define a BitcoinOutput with the P2pkhAddress and a value of 0.01 BCH
        BitcoinOutput(address: out1, value: BtcUtils.toSatoshi("0.01")),

        /// Define a BitcoinOutput with the P2shAddress and a value of 0.01 BCH
        BitcoinOutput(address: out2, value: BtcUtils.toSatoshi("0.01")),

        /// Define a BitcoinOutput with the P2shAddress and a value equal to the 'change' variable
        BitcoinOutput(address: out3, value: change),
      ],

      /// Set the transaction fee to 0.00003 BCH
      fee: BtcUtils.toSatoshi("0.00003"),

      /// Specify the network for the BCH transaction
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
                  "ece972a6d5d1b07062ed5aaab786b528b04a3cf675affdda8cb79ec805c53ce2",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("0.01"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 0,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: childKey1PublicKey.toP2pkInP2sh().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: childKey1PublicKey.toHex(),
                address: childKey1PublicKey.toP2pkInP2sh())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "ece972a6d5d1b07062ed5aaab786b528b04a3cf675affdda8cb79ec805c53ce2",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("0.01"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 1,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: childKey1PublicKey.toP2pkhInP2sh().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: childKey1PublicKey.toHex(),
                address: childKey1PublicKey.toP2pkhInP2sh())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "ece972a6d5d1b07062ed5aaab786b528b04a3cf675affdda8cb79ec805c53ce2",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("0.01"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 2,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: examplePublicKey.toAddress().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey.toHex(),
                address: examplePublicKey.toAddress())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "ece972a6d5d1b07062ed5aaab786b528b04a3cf675affdda8cb79ec805c53ce2",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("0.07097"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 3,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: msig2.toP2shAddress().type,
            ),

            /// Include owner details with the multiSigAddress and address associated with the UTXO
            ownerDetails: UtxoAddressDetails.multiSigAddress(
                multiSigAddress: msig2, address: msig2.toP2shAddress())),
      ]);
  final tr = b.buildTransaction((trDigest, utxo, publicKey, int sighash) {
    if (publicKey == childKey1PublicKey.toHex()) {
      return childKey1PrivateKey.signInput(trDigest, sigHash: sighash);
    }
    if (publicKey == examplePublicKey.toHex()) {
      return childKey2PrivateKey.signInput(trDigest, sigHash: sighash);
    }
    if (publicKey == examplePublicKey2.toHex()) {
      return examplePrivateKey.signInput(trDigest, sigHash: sighash);
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
  /// https://tbch.loping.net/tx/205881575bf503903f7a572dacd944bebc77a2b4ca6fae81bb6b1a89b3af7be9
  await _brodcastTrasaction(tr.serialize());
}
