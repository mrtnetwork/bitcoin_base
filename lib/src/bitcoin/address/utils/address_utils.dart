part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

/// Utility class for working with Bitcoin addresses and related operations.
class _BitcoinAddressUtils {
  /// Length of a script hash in bytes.
  static const int scriptHashLenght = QuickCrypto.sha256DigestSize;

  /// Length of a hash160 digest in bytes.
  static const int hash160DigestLength = QuickCrypto.hash160DigestSize;

  /// Segregated Witness version 0.
  static const int segwitV0 = 0;

  /// Segregated Witness version 1.
  static const int segwitV1 = 1;

  /// Decodes a legacy Bitcoin address and returns a tuple containing the script bytes and version.
  ///
  /// [address]: The legacy Bitcoin address to be decoded.
  /// Returns a tuple with script bytes and version if decoding is successful, otherwise null.
  static Tuple<List<int>, List<int>>? decodeLagacyAddress(
      {required String address}) {
    try {
      /// Decode the base58-encoded address.
      final decode = List<int>.unmodifiable(Base58Decoder.decode(address));

      /// Extract script bytes excluding version and checksum.
      final scriptBytes =
          decode.sublist(1, decode.length - Base58Const.checksumByteLen);

      /// Ensure the script bytes have the expected length.
      if (scriptBytes.length != hash160DigestLength) {
        return null;
      }

      /// Extract version, data, and checksum.
      final version = <int>[decode[0]];
      final data =
          decode.sublist(0, decode.length - Base58Const.checksumByteLen);
      final checksum =
          decode.sublist(decode.length - Base58Const.checksumByteLen);

      /// Verify the checksum.
      final hash = QuickCrypto.sha256DoubleHash(data)
          .sublist(0, Base58Const.checksumByteLen);
      if (!BytesUtils.bytesEqual(checksum, hash)) {
        return null;
      }

      /// Return the decoded script bytes and version.
      return Tuple(scriptBytes, version);
    } catch (e) {
      return null;
    }
  }

  /// Converts a given Bitcoin address to a legacy address based on the specified [networks].
  ///
  /// [address]: The Bitcoin address to be converted to a legacy address.
  /// [networks]: The network parameters to determine the address type.
  /// Returns a [LegacyAddress] instance representing the converted legacy address, or null if conversion is not successful.
  static LegacyAddress? toLegacy(String address, BasedUtxoNetwork networks) {
    final decode = decodeLagacyAddress(address: address);
    if (decode == null) {
      return null;
    }
    final decodedHex = BytesUtils.toHexString(decode.item1);
    if (BytesUtils.bytesEqual(decode.item2, networks.p2pkhNetVer)) {
      return P2pkhAddress.fromHash160(addrHash: decodedHex);
    } else if (BytesUtils.bytesEqual(decode.item2, networks.p2shNetVer)) {
      return P2shAddress.fromHash160(addrHash: decodedHex);
    }
    return null;
  }

  /// Converts a Segregated Witness (SegWit) address to its witness program representation
  /// with a specified version and network parameters.
  ///
  /// [address]: The SegWit address to be converted.
  /// [network]: The network parameters containing the human-readable part (HRP) for SegWit addresses.
  /// [version]: The specified witness version for the SegWit address.
  /// Returns a hexadecimal representation of the witness program.
  ///
  /// Throws a [MessageException] if the witness version does not match the specified version.
  static String toSegwitProgramWithVersionAndNetwork(
      {required String address,
      required BasedUtxoNetwork network,
      required int version}) {
    final convert = SegwitBech32Decoder.decode(network.p2wpkhHrp, address);
    final witnessVersion = convert.item1;
    if (witnessVersion != version) {
      throw const DartBitcoinPluginException('Invalid segwit version');
    }
    return BytesUtils.toHexString(convert.item2);
  }

  /// Converts a Segregated Witness (SegWit) address to a SegwitAddress instance
  /// based on the specified network parameters.
  ///
  /// [address]: The SegWit address to be converted.
  /// [network]: The network parameters containing the human-readable part (HRP) for SegWit addresses.
  ///
  /// Returns a SegwitAddress instance representing the converted SegWit address,
  /// or null if the conversion is not successful.
  static SegwitAddress? toSegwitAddress(
      String address, BasedUtxoNetwork network) {
    try {
      final convert = SegwitBech32Decoder.decode(network.p2wpkhHrp, address);
      final witnessVersion = convert.item1;
      final decodedBytesHex = BytesUtils.toHexString(convert.item2);
      if (witnessVersion == segwitV1) {
        return P2trAddress.fromProgram(program: decodedBytesHex);
      } else if (witnessVersion == segwitV0) {
        if (convert.item2.length == hash160DigestLength) {
          return P2wpkhAddress.fromProgram(program: decodedBytesHex);
        } else if (convert.item2.length == scriptHashLenght) {
          return P2wshAddress.fromProgram(program: decodedBytesHex);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validates a Bitcoin base address against the supported address types of the specified network.
  ///
  /// [address]: The Bitcoin base address to be validated.
  /// [network]: The network parameters containing the supported address types.
  ///
  /// Returns the validated Bitcoin base address if it belongs to a supported type for the given network.
  ///
  /// Throws a [MessageException] if the address type is not supported by the specified network.
  static BitcoinBaseAddress validateAddress(
      BitcoinBaseAddress address, BasedUtxoNetwork network) {
    if (network.supportedAddress.contains(address.type)) {
      return address;
    }
    throw DartBitcoinPluginException(
        '${network.value} does not support ${address.type.value} address');
  }

  /// Decodes a Bitcoin address and returns a corresponding BitcoinBaseAddress instance
  /// based on the specified network parameters.
  ///
  /// [address]: The Bitcoin address to be decoded.
  /// [network]: The network parameters containing supported address types.
  ///
  /// Returns a BitcoinBaseAddress instance representing the decoded address.
  ///
  /// Throws a [MessageException] if the address is invalid or not supported by the network.
  static BitcoinBaseAddress decodeAddress(
      String address, BasedUtxoNetwork network) {
    BitcoinBaseAddress? baseAddress;
    if (network.supportedAddress.contains(SegwitAddressType.p2wpkh)) {
      baseAddress = toSegwitAddress(address, network);
    }
    baseAddress ??= toLegacy(address, network);
    if (baseAddress == null) {
      throw const DartBitcoinPluginException('Invalid Bitcoin address.');
    }
    return validateAddress(baseAddress, network);
  }

  /// Validates a Bitcoin address program represented as a hexadecimal string.
  ///
  /// [hash160]: The hash160 value in hexadecimal format to be validated.
  /// [addressType]: The Bitcoin address type indicating the expected hash length.
  ///
  /// Returns the validated hash160 value if its length matches the expected length for the specified address type.
  ///
  /// Throws a [MessageException] if the hash160 value is invalid or has an incorrect length.
  static String validateAddressProgram(
      String hash160, BitcoinAddressType addressType) {
    try {
      final toBytes = BytesUtils.fromHexString(hash160);
      if (toBytes.length == addressType.hashLength) {
        return StringUtils.strip0x(hash160.toLowerCase());
      }
    } catch (_) {}
    throw const DartBitcoinPluginException(
        'Invalid Bitcoin address program length (program length should be 32 or 20 bytes)');
  }

  /// Decodes a Bitcoin Cash (BCH) address and returns a corresponding LegacyAddress instance
  /// based on the specified Bitcoin Cash network parameters.
  ///
  /// [address]: The Bitcoin Cash address to be decoded.
  /// [network]: The Bitcoin Cash network parameters.
  /// [validateNetworkHRP]: Flag indicating whether to validate the human-readable part (HRP) of the address.
  ///
  /// Returns a LegacyAddress instance representing the decoded BCH address if successful,
  /// or null if the decoding process fails.
  static LegacyAddress? decodeBchAddress(
      String address, BitcoinCashNetwork network,
      {bool validateNetworkHRP = false}) {
    try {
      final hrp = validateNetworkHRP
          ? network.networkHRP
          : address.substring(0, address.indexOf(':'));
      final decode = BchBech32Decoder.decode(hrp, address);
      final scriptBytes = decode.item2;
      final version = decode.item1;
      return _validateBchScriptBytes(
          network: network, scriptBytes: scriptBytes, version: version);
    } catch (_) {
      return null;
    }
  }

  /// Validates Bitcoin Cash (BCH) script bytes and version to determine the appropriate LegacyAddress type.
  ///
  /// [scriptBytes]: The script bytes obtained from decoding the BCH address.
  /// [version]: The version bytes obtained from decoding the BCH address.
  /// [network]: The Bitcoin Cash network parameters for address type validation.
  ///
  /// Returns a LegacyAddress instance representing the validated BCH address if successful,
  /// or null if the validation process fails.
  static LegacyAddress? _validateBchScriptBytes(
      {required List<int> scriptBytes,
      required List<int> version,
      required BitcoinCashNetwork network}) {
    final scriptHex = BytesUtils.toHexString(scriptBytes);
    final scriptLength = scriptBytes.length;
    if (scriptLength != hash160DigestLength &&
        scriptLength != scriptHashLenght) {
      return null;
    }
    if (scriptLength == hash160DigestLength) {
      final legacyP2pk = BytesUtils.bytesEqual(network.p2pkhNetVer, version);

      if (BytesUtils.bytesEqual(network.p2pkhNetVer, version) ||
          BytesUtils.bytesEqual(network.p2pkhWtNetVer, version)) {
        return P2pkhAddress.fromHash160(
            addrHash: scriptHex,
            type:
                legacyP2pk ? P2pkhAddressType.p2pkh : P2pkhAddressType.p2pkhwt);
      }
      final legacyP2sh = BytesUtils.bytesEqual(network.p2shNetVer, version);
      if (BytesUtils.bytesEqual(network.p2shNetVer, version) ||
          BytesUtils.bytesEqual(network.p2shwt20NetVer, version)) {
        return P2shAddress.fromHash160(
            addrHash: scriptHex,
            type: legacyP2sh
                ? P2shAddressType.p2pkhInP2sh
                : P2shAddressType.p2pkhInP2shwt);
      }
    } else {
      final legacyP2sh = BytesUtils.bytesEqual(network.p2sh32NetVer, version);
      if (BytesUtils.bytesEqual(network.p2sh32NetVer, version) ||
          BytesUtils.bytesEqual(network.p2shwt32NetVer, version)) {
        return P2shAddress.fromHash160(
            addrHash: scriptHex,
            type: legacyP2sh
                ? P2shAddressType.p2pkhInP2sh32
                : P2shAddressType.p2pkhInP2sh32wt);
      }
    }
    return null;
  }

  /// Decodes a Bitcoin legacy address, validates its type, and returns the address program
  /// based on the specified network and address type.
  ///
  /// [address]: The Bitcoin legacy address to be decoded.
  /// [type]: The expected Bitcoin address type.
  /// [network]: The network parameters containing supported address types.
  ///
  /// Returns the address program in hexadecimal format if successful, or null if decoding or validation fails.
  ///
  /// Throws a [MessageException] if the specified network does not support the given address type.
  static String? decodeLagacyAddressWithNetworkAndType(
      {required String address,
      required BitcoinAddressType type,
      required BasedUtxoNetwork network}) {
    if (!network.supportedAddress.contains(type)) {
      throw DartBitcoinPluginException(
          '${network.value} does not support ${type.value} address type');
    }
    if (network is BitcoinCashNetwork) {
      final decode = _BitcoinAddressUtils.decodeBchAddress(address, network);
      if (decode != null) {
        if (decode.type == type) {
          return decode.addressProgram;
        }
      }
      return null;
    }
    final decode = _BitcoinAddressUtils.decodeLagacyAddress(address: address);
    if (decode == null) return null;
    final version = decode.item2;
    final addrBytes = decode.item1;
    final scriptHex = BytesUtils.toHexString(addrBytes);
    switch (type) {
      case P2pkhAddressType.p2pkh:
        if (BytesUtils.bytesEqual(version, network.p2pkhNetVer)) {
          return scriptHex;
        }
        return null;
      case P2shAddressType.p2pkhInP2sh:
      case P2shAddressType.p2pkInP2sh:
      case P2shAddressType.p2wshInP2sh:
      case P2shAddressType.p2wpkhInP2sh:
        if (BytesUtils.bytesEqual(version, network.p2shNetVer)) {
          return scriptHex;
        }
        return null;
      default:
    }
    return scriptHex;
  }

  /// Converts a Segregated Witness (SegWit) script to its SHA-256 hash.
  ///
  /// [script]: The SegWit script to be hashed.
  ///
  /// Returns the hexadecimal representation of the SHA-256 hash of the SegWit script.
  static String segwitScriptToSHA256(Script script) {
    final toBytes = script.toBytes();
    final toHash = QuickCrypto.sha256Hash(toBytes);
    return BytesUtils.toHexString(toHash);
  }

  /// Converts a Segregated Witness (SegWit) address program to its corresponding SegWit address.
  ///
  /// [addressProgram]: The address program in hexadecimal format.
  /// [network]: The network parameters containing the human-readable part (HRP) for SegWit addresses.
  /// [segwitVersion]: The SegWit version associated with the address program.
  ///
  /// Returns the SegWit address for the specified program.
  static String segwitToAddress(
      {required String addressProgram,
      required BasedUtxoNetwork network,
      required int segwitVersion}) {
    final programBytes = BytesUtils.fromHexString(addressProgram);
    return SegwitBech32Encoder.encode(
        network.p2wpkhHrp, segwitVersion, programBytes);
  }

  /// Converts a Bitcoin legacy address program to its corresponding Bitcoin Cash (BCH) address.
  ///
  /// [network]: The Bitcoin Cash network parameters containing the human-readable part (HRP).
  /// [addressProgram]: The address program in hexadecimal format.
  /// [type]: The expected Bitcoin address type.
  ///
  /// Returns the Bitcoin Cash address for the specified legacy address program.
  static String legacyToBchAddress(
      {required BitcoinCashNetwork network,
      required String addressProgram,
      required BitcoinAddressType type}) {
    final programBytes = BytesUtils.fromHexString(addressProgram);
    final netVersion = _getBchNetVersion(
        network: network, type: type, secriptLength: programBytes.length);

    return BchBech32Encoder.encode(
        network.networkHRP, netVersion, programBytes);
  }

  /// Helper method to obtain the Bitcoin Cash network version bytes based on the address type and script length.
  ///
  /// [network]: The Bitcoin Cash network parameters.
  /// [type]: The expected Bitcoin address type.
  /// [secriptLength]: The length of the script associated with the address.
  ///
  /// Returns the network version bytes for the specified address type and script length.
  static List<int> _getBchNetVersion(
      {required BitcoinCashNetwork network,
      required BitcoinAddressType type,
      int secriptLength = hash160DigestLength}) {
    final isToken = type.value.contains('WT');
    if (!type.isP2sh) {
      if (!isToken) return network.p2pkhNetVer;
      return network.p2pkhWtNetVer;
    } else {
      if (!isToken) {
        if (secriptLength == hash160DigestLength) {
          return network.p2shNetVer;
        }
        return network.p2sh32NetVer;
      }
      if (secriptLength == hash160DigestLength) {
        return network.p2shwt20NetVer;
      }
      return network.p2shwt32NetVer;
    }
  }

  /// Converts a Bitcoin legacy address program to its corresponding address for the specified network and type.
  ///
  /// [network]: The Bitcoin network parameters.
  /// [addressProgram]: The address program in hexadecimal format.
  /// [type]: The expected Bitcoin address type.
  /// [useLegacyBCH]: Flag indicating whether to use legacy encoding for Bitcoin Cash addresses.
  ///
  /// Returns the legacy Base58-encoded address for the specified legacy address program.
  /// If the network is Bitcoin Cash, the method delegates to [legacyToBchAddress] for BCH address encoding.
  /// Otherwise, it constructs the legacy Base58-encoded address based on the provided parameters.
  static String legacyToAddress(
      {required BasedUtxoNetwork network,
      required String addressProgram,
      required BitcoinAddressType type}) {
    if (network is BitcoinCashNetwork) {
      return legacyToBchAddress(
          addressProgram: addressProgram, network: network, type: type);
    }
    var programBytes = BytesUtils.fromHexString(addressProgram);
    switch (type) {
      case P2shAddressType.p2wpkhInP2sh:
      case P2shAddressType.p2wshInP2sh:
      case P2shAddressType.p2pkhInP2sh:
      case P2shAddressType.p2pkInP2sh:
        programBytes = [...network.p2shNetVer, ...programBytes];
        break;
      case P2pkhAddressType.p2pkh:
      case PubKeyAddressType.p2pk:
        programBytes = [...network.p2pkhNetVer, ...programBytes];
        break;
      default:
    }

    return Base58Encoder.checkEncode(programBytes);
  }

  /// Converts a public key in hexadecimal format to its corresponding RIPEMD-160 hash (hash160).
  ///
  /// [publicKey]: The public key in hexadecimal format.
  ///
  /// Returns the RIPEMD-160 hash of the public key as a hexadecimal string.
  static String pubkeyToHash160(String publicKey) {
    final bytes = BytesUtils.fromHexString(publicKey);
    final ripemd160Hash = QuickCrypto.hash160(bytes);
    return BytesUtils.toHexString(ripemd160Hash);
  }

  /// Converts a Bitcoin script to its corresponding RIPEMD-160 hash (hash160).
  ///
  /// [s]: The Bitcoin script.
  ///
  /// Returns the RIPEMD-160 hash of the script as a hexadecimal string.
  static String scriptToHash160(Script s) {
    final toBytes = s.toBytes();
    final h160 = QuickCrypto.hash160(toBytes);
    return BytesUtils.toHexString(h160);
  }

  /// Returns the hexadecimal representation of the reversed SHA-256 hash160 of the script's
  static String pubKeyHash(Script scriptPubKey) {
    return BytesUtils.toHexString(List<int>.from(
        QuickCrypto.sha256Hash(scriptPubKey.toBytes()).reversed));
  }
}
