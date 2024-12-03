// ignore_for_file: unused_local_variable, unused_element

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/services_examples/explorer_service/explorer_service.dart';

/// Calculates the change value based on the sum of all provided values.
///
/// This function takes the total sum (`sum`) and a list of individual values (`all`).
/// It calculates the sum of all values in the list and subtracts it from the total sum,
/// returning the change value.
///
/// Throws an `ArgumentError` if the resulting change value is negative, indicating invalid values.
///
/// Parameters:
/// - `sum`: The total sum of values.
/// - `all`: List of individual values.
///
/// Returns:
/// - The change value.
BigInt _changeValue(BigInt sum, List<BigInt> all) {
  final sumAll = all.fold<BigInt>(
      BigInt.zero, (previousValue, element) => previousValue + element);

  final remind = sum - sumAll;
  if (remind < BigInt.zero) {
    throw ArgumentError("invalid values");
  }
  return remind;
}

void main() {
  _spendFrom10DifferentTypeToP2pkh();
}

void _spendFromP2pkhTo10DifferentType() async {
  /// Define network
  const network = BitcoinNetwork.testnet;

  /// Define http provider and api provider
  final service = BitcoinApiService();
  final api = ApiProvider.fromBlocCypher(network, service);

  /// Define a seed using a hex string
  final seed = BytesUtils.fromHexString(
      "50b112c15987f0f1aa58430b6e1364cb4ac216a96b4a1e5030d63f62c3e13f0e9d5cfa97eb28584d112a7eddf53a0ca9f3ea58183f42c28f861162225bdab836");

  /// Create a Bip32 key from the seed
  final bip32 = Bip32Slip10Secp256k1.fromSeed(seed);

  final childKey = bip32.childKey(Bip32KeyIndex(3));

  final examplePublicKey = ECPublic.fromBytes(childKey.publicKey.compressed);

  /// Define another private key from wif
  final ECPrivate examplePrivateKey = ECPrivate.fromWif(
      'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
      netVersion: BitcoinNetwork.testnet.wifNetVer);

  /// access to public key
  final examplePublicKey2 = examplePrivateKey.getPublic();

  /// Define transaction outputs
  final out1 = P2pkhAddress.fromAddress(
      address: "msxiCJXD2WB43wK2PpTUvoqQLF7ZP98qqM", network: network);
  final out2 = P2trAddress.fromAddress(
      address: "tb1plq65drqavf93wf63d8g7d8ypuzaargd5h9d35u05ktrcwxq4a6ss0gpvrt",
      network: network);
  final out3 = P2wpkhAddress.fromAddress(
      address: "tb1q3zqgu9j368wgk8u5f9vtmkdwq8geetdxry690d", network: network);
  final out4 = P2pkAddress(publicKey: examplePublicKey.publicKey.toHex());
  final out5 = P2shAddress.fromAddress(
      address: "2N5hVdETdJMwLDxxttfqeWgMuny6K4SYGSc", network: network);
  final out6 = P2shAddress.fromAddress(
      address: "2NDAUpeUB1kGAQET8SojF8seXNrk3uudtCb", network: network);
  final out7 = P2shAddress.fromAddress(
      address: "2NE9CYdxju2iEAfR4FMdKPUcZbnKcfCiLhM", network: network);
  final out8 = P2shAddress.fromAddress(
      address: "2MwGRf8wNJsaYKdigqPwikPpg9JAT2faaPB", network: network);
  final out9 = P2wshAddress.fromAddress(
      address: "tb1qes3upam2nv3rc6s38tqgk0cqh6dlycvk6cjydyvpx9zlumh4h4lsjq26p8",
      network: network);
  final out10 = P2shAddress.fromAddress(
      address: "2N2aRKjTQ3uzgUSLWFQAUDvKLnKCiBfCSAh", network: network);

  /// Calculate the change value for the transaction
  final change = _changeValue(

      /// sum of utxos
      BigInt.from(1062830),
      [
        /// transaction fee
        BtcUtils.toSatoshi("0.00005"),
        BtcUtils.toSatoshi("0.009"),
      ]);

  final builder = BitcoinTransactionBuilder(

      /// outputs and values
      outPuts: [
        BitcoinOutput(address: out1, value: BtcUtils.toSatoshi("0.001")),
        BitcoinOutput(address: out2, value: BtcUtils.toSatoshi("0.001")),
        BitcoinOutput(address: out3, value: BtcUtils.toSatoshi("0.001")),
        BitcoinOutput(address: out4, value: BtcUtils.toSatoshi("0.001")),
        BitcoinOutput(address: out5, value: BtcUtils.toSatoshi("0.001")),
        BitcoinOutput(address: out6, value: BtcUtils.toSatoshi("0.001")),
        BitcoinOutput(address: out7, value: BtcUtils.toSatoshi("0.001")),
        BitcoinOutput(address: out8, value: BtcUtils.toSatoshi("0.001")),
        BitcoinOutput(address: out9, value: BtcUtils.toSatoshi("0.001")),
        BitcoinOutput(address: out10, value: change),
      ],

      /// Transaction fee
      fee: BtcUtils.toSatoshi("0.00005"),

      /// transaction network
      network: network,

      /// replace-by-fee
      enableRBF: true,

      /// memo
      memo: "https://github.com/mrtnetwork",

      /// Define a list of Unspent Transaction Outputs (UTXOs) for the Bitcoin transaction
      utxos: [
        /// Create a UTXO using a BitcoinUtxo with specific details
        UtxoWithAddress(

            /// Create a UTXO using a BitcoinUtxo with specific details
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "b06f4ed0b49a5092a9ea206553ddc5fc469be694d0d28c95598c653e66cdeb5e",

              /// Value represents the amount of the UTXO in satoshis.
              value: BigInt.from(250000),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 3,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: examplePublicKey2.toAddress().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey2.toHex(),
                address: examplePublicKey2.toAddress())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash:
                  "6ff0bdb2966f62f5e202c924e1cab1368b0258833e48986cc0a70fbca624ba93",
              value: BigInt.from(812830),
              vout: 0,
              scriptType: examplePublicKey2.toAddress().type,
            ),
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey2.toHex(),
                address: examplePublicKey2.toAddress())),
      ]);

  /// Build the transaction by invoking the buildTransaction method on the BitcoinTransactionBuilder
  final tr = builder.buildTransaction((trDigest, utxo, publicKey, sighash) {
    /// For each input in the transaction, locate the corresponding private key
    /// and sign the transaction digest to construct the unlocking script.

    if (publicKey == examplePublicKey2.toHex()) {
      if (utxo.utxo.isP2tr) {
        return examplePrivateKey.signTapRoot(trDigest);
      }
      return examplePrivateKey.signInput(trDigest, sigHash: sighash);
    }

    throw UnimplementedError();
  });

  /// Get the transaction ID
  final txId = tr.txId();

  /// Calculate the size of the transaction in bytes.
  /// You can determine the transaction fee by multiplying the transaction size
  /// Formula: transaction fee = (transaction size in bytes * fee rate in bytes)
  final size = tr.hasSegwit ? tr.getVSize() : tr.getSize();

  /// broadcast transaction
  /// https://mempool.space/testnet/tx/05411dce1a1c9e3f44b54413bdf71e7ab3eff1e2f94818a3568c39814c27b258
  await api.sendRawTransaction(tr.serialize());

  /// In the [_spendFrom10DifferentTypeToP2pkh] example, our objective is to spend 10 entries from this transaction.
}

void _spendFrom10DifferentTypeToP2pkh() async {
  /// Define network
  const network = BitcoinNetwork.testnet;

  /// Define http provider and api provider
  final service = BitcoinApiService();
  final api = ApiProvider.fromBlocCypher(network, service);

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

  /// define another private key from wif
  final ECPrivate examplePrivateKey = ECPrivate.fromWif(
      'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
      netVersion: BitcoinNetwork.testnet.wifNetVer);

  /// access to public key
  final examplePublicKey2 = examplePrivateKey.getPublic();

  /// Define multisig address 2-of-2 for spending
  final msig = MultiSignatureAddress(threshold: 2, signers: [
    MultiSignatureSigner(publicKey: examplePublicKey.toHex(), weight: 1),
    MultiSignatureSigner(publicKey: childKey1PublicKey.toHex(), weight: 1),
  ]);

  /// Define multisig address 3-of-3 for spending
  final msig2 = MultiSignatureAddress(threshold: 3, signers: [
    MultiSignatureSigner(publicKey: examplePublicKey.toHex(), weight: 1),
    MultiSignatureSigner(publicKey: childKey1PublicKey.toHex(), weight: 2),
  ]);

  /// Calculate the change value for the transaction
  final change = _changeValue(

      /// sum of utxos
      BtcUtils.toSatoshi("0.009") + BtcUtils.toSatoshi("0.0015783"),
      [
        /// Transaction fee
        BtcUtils.toSatoshi("0.00005"),
      ]);

  /// outputs
  /// make sure pass network to address for validate, before sending create transaction
  final out1 = P2pkhAddress.fromAddress(
      address: "n4bkvTyU1dVdzsrhWBqBw8fEMbHjJvtmJR", network: network);

  final builder = BitcoinTransactionBuilder(

      /// outputs
      outPuts: [BitcoinOutput(address: out1, value: change)],

      /// Set the transaction fee
      fee: BtcUtils.toSatoshi("0.00005"),
      network: network,
      enableRBF: true,

      /// Add a memo to the transaction, linking to the GitHub repository
      memo: "https://github.com/mrtnetwork",

      /// Define a list of Unspent Transaction Outputs (UTXOs) for the Bitcoin transaction.
      /// We are selecting 10 UTXOs for spending, and each UTXO has a different address type.
      /// These UTXOs are related to the previous example at the top of this page.
      utxos: [
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              /// Transaction hash uniquely identifies the referenced transaction
              txHash:
                  "05411dce1a1c9e3f44b54413bdf71e7ab3eff1e2f94818a3568c39814c27b258",

              /// Value represents the amount of the UTXO in satoshis.
              value: BtcUtils.toSatoshi("0.001"),

              /// Vout is the output index of the UTXO within the referenced transaction
              vout: 0,

              /// Script type indicates the type of script associated with the UTXO's address
              scriptType: childKey1PublicKey.toAddress().type,
            ),

            /// Include owner details with the public key and address associated with the UTXO
            ownerDetails: UtxoAddressDetails(
                publicKey: childKey1PublicKey.toHex(),
                address: childKey1PublicKey.toAddress())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash:
                  "05411dce1a1c9e3f44b54413bdf71e7ab3eff1e2f94818a3568c39814c27b258",
              value: BtcUtils.toSatoshi("0.001"),
              vout: 1,
              scriptType: childKey1PublicKey.toTaprootAddress().type,
            ),
            ownerDetails: UtxoAddressDetails(
                publicKey: childKey1PublicKey.toHex(),
                address: childKey1PublicKey.toTaprootAddress())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash:
                  "05411dce1a1c9e3f44b54413bdf71e7ab3eff1e2f94818a3568c39814c27b258",
              value: BtcUtils.toSatoshi("0.001"),
              vout: 2,
              scriptType: childKey1PublicKey.toSegwitAddress().type,
            ),
            ownerDetails: UtxoAddressDetails(
                publicKey: childKey1PublicKey.toHex(),
                address: childKey1PublicKey.toSegwitAddress())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash:
                  "05411dce1a1c9e3f44b54413bdf71e7ab3eff1e2f94818a3568c39814c27b258",
              value: BtcUtils.toSatoshi("0.001"),
              vout: 3,
              scriptType: examplePublicKey.toP2pkAddress().type,
            ),
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey.toHex(),
                address: examplePublicKey.toP2pkAddress())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash:
                  "05411dce1a1c9e3f44b54413bdf71e7ab3eff1e2f94818a3568c39814c27b258",
              value: BtcUtils.toSatoshi("0.001"),
              vout: 4,
              scriptType: examplePublicKey.toP2pkInP2sh().type,
            ),
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey.toHex(),
                address: examplePublicKey.toP2pkInP2sh())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash:
                  "05411dce1a1c9e3f44b54413bdf71e7ab3eff1e2f94818a3568c39814c27b258",
              value: BtcUtils.toSatoshi("0.001"),
              vout: 5,
              scriptType: examplePublicKey.toP2pkhInP2sh().type,
            ),
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey.toHex(),
                address: examplePublicKey.toP2pkhInP2sh())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash:
                  "05411dce1a1c9e3f44b54413bdf71e7ab3eff1e2f94818a3568c39814c27b258",
              value: BtcUtils.toSatoshi("0.001"),
              vout: 6,
              scriptType: examplePublicKey.toP2wpkhInP2sh().type,
              blockHeight: 0,
            ),
            ownerDetails: UtxoAddressDetails(
                publicKey: examplePublicKey.toHex(),
                address: examplePublicKey.toP2wpkhInP2sh())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash:
                  "05411dce1a1c9e3f44b54413bdf71e7ab3eff1e2f94818a3568c39814c27b258",
              value: BtcUtils.toSatoshi("0.001"),
              vout: 7,
              scriptType: msig.toP2shAddress().type,
              blockHeight: 0,
            ),

            /// For multisig addresses, we utilize `UtxoAddressDetails.multiSigAddress` to automatically manage each signer.
            ownerDetails: UtxoAddressDetails.multiSigAddress(
                multiSigAddress: msig, address: msig.toP2shAddress())),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash:
                  "05411dce1a1c9e3f44b54413bdf71e7ab3eff1e2f94818a3568c39814c27b258",
              value: BtcUtils.toSatoshi("0.001"),
              vout: 8,
              scriptType: msig.toP2wshAddress(network: network).type,
              blockHeight: 0,
            ),
            ownerDetails: UtxoAddressDetails.multiSigAddress(
                multiSigAddress: msig,
                address: msig.toP2wshAddress(network: network))),
        UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash:
                  "05411dce1a1c9e3f44b54413bdf71e7ab3eff1e2f94818a3568c39814c27b258",
              value: BtcUtils.toSatoshi("0.0015783"),
              vout: 9,
              scriptType: msig2.toP2wshInP2shAddress(network: network).type,
              blockHeight: 0,
            ),
            ownerDetails: UtxoAddressDetails.multiSigAddress(
                multiSigAddress: msig2,
                address: msig2.toP2wshInP2shAddress(network: network))),
      ]);

  /// Build the transaction by invoking the buildTransaction method on the BitcoinTransactionBuilder
  final tr = builder.buildTransaction((trDigest, utxo, publicKey, sighash) {
    /// For each input in the transaction, locate the corresponding private key
    /// and sign the transaction digest to construct the unlocking script.
    if (publicKey == childKey1PublicKey.toHex()) {
      if (utxo.utxo.isP2tr) {
        return childKey1PrivateKey.signTapRoot(trDigest, sighash: sighash);
      }
      return childKey1PrivateKey.signInput(trDigest, sigHash: sighash);
    }
    if (publicKey == examplePublicKey.toHex()) {
      if (utxo.utxo.isP2tr) {
        return childKey2PrivateKey.signTapRoot(trDigest, sighash: sighash);
      }
      return childKey2PrivateKey.signInput(trDigest, sigHash: sighash);
    }
    if (publicKey == examplePublicKey2.toHex()) {
      if (utxo.utxo.isP2tr) {
        return examplePrivateKey.signTapRoot(trDigest, sighash: sighash);
      }
      return examplePrivateKey.signInput(trDigest, sigHash: sighash);
    }

    throw UnimplementedError();
  });

  /// Get the transaction ID
  final txId = tr.txId();

  /// Calculate the size of the transaction in bytes.
  /// You can determine the transaction fee by multiplying the transaction size
  /// Formula: transaction fee = (transaction size in bytes * fee rate in bytes)
  final size = tr.hasSegwit ? tr.getVSize() : tr.getSize();

  /// broadcast transaction
  /// https://mempool.space/testnet/tx/3e697e0993a6882689ff9b66ff73cdf53e4a3029664ec4a516da2b291e1cd8a6
  await api.sendRawTransaction(tr.serialize());
}
