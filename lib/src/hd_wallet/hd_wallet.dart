import 'dart:convert';
import 'dart:typed_data';
import 'package:bitcoin_base/src/bip39/bip39.dart';
import 'package:bitcoin_base/src/bitcoin/address/core.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/crypto/ec/ec_encryption.dart' as ec;
import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/base58/base58.dart' as bs;

class HdWallet {
  static const String _bitcoinKey = "Bitcoin seed";
  HdWallet._fromPrivateKey(
      {required ECPrivate privateKey,
      required Uint8List chainCode,
      int depth = 0,
      int index = 0,
      Uint8List? fingerPrint})
      : _fingerPrint = fingerPrint ?? Uint8List(4),
        _chainCode = chainCode,
        _private = privateKey,
        _ecPublic = privateKey.getPublic(),
        _fromXpub = false,
        _depth = depth,
        _index = index;
  HdWallet._fromPublicKey(
      {required ECPublic public,
      required Uint8List chainCode,
      int depth = 0,
      int index = 0,
      Uint8List? fingerPrint})
      : _fingerPrint = fingerPrint ?? Uint8List(4),
        _chainCode = chainCode,
        _ecPublic = public,
        _fromXpub = true,
        _depth = depth,
        _index = index;

  int _depth = 0;
  int get depth => _depth;

  int _index = 0;
  int get index => _index;

  final Uint8List _fingerPrint;
  Uint8List get fingerPrint => _fingerPrint;

  late final bool isRoot = bytesListEqual(_fingerPrint, Uint8List(4));

  late final ECPrivate _private;
  ECPrivate get privateKey => _fromXpub
      ? throw ArgumentError("connot access private from publicKey wallet")
      : _private;

  late final ECPublic _ecPublic;
  ECPublic get publicKey => _ecPublic;
  final bool _fromXpub;
  bool get isPublicKeyWallet => _fromXpub;

  factory HdWallet.fromMnemonic(String mnemonic,
      {String passphrase = "", String key = _bitcoinKey}) {
    final seed = BIP39.toSeed(mnemonic, passphrase: passphrase);
    if (seed.length < 16) {
      throw ArgumentError("Seed should be at least 128 bits");
    }
    if (seed.length > 64) {
      throw ArgumentError("Seed should be at most 512 bits");
    }
    final hash = hmacSHA512(utf8.encode(key) as Uint8List, seed);
    final private = ECPrivate.fromBytes(hash.sublist(0, 32));
    final chainCode = hash.sublist(32);
    final wallet =
        HdWallet._fromPrivateKey(privateKey: private, chainCode: chainCode);
    return wallet;
  }

  final Uint8List _chainCode;

  static const _highBit = 0x80000000;
  static const _maxUint31 = 2147483647;
  static const _maxUint32 = 4294967295;

  String chainCode() {
    return bytesToHex(_chainCode);
  }

  HdWallet _addDrive(int index) {
    if (index > _maxUint32 || index < 0) throw ArgumentError("Expected UInt32");
    final isHardened = index >= _highBit;
    Uint8List data = Uint8List(37);

    if (isHardened) {
      if (_fromXpub) {
        throw ArgumentError("cannot use hardened path in public wallet");
      }
      data[0] = 0x00;
      data.setRange(1, 33, (_private).toBytes());
      data.buffer.asByteData().setUint32(33, index);
    } else {
      data.setRange(0, 33, publicKey.toCompressedBytes());
      data.buffer.asByteData().setUint32(33, index);
    }
    final masterKey = hmacSHA512(_chainCode, data);
    final key = masterKey.sublist(0, 32);
    final chain = masterKey.sublist(32);
    if (!ec.isPrivate(key)) {
      return _addDrive(index + 1);
    }
    final childDeph = depth + 1;
    final childIndex = index;
    final finger = hash160(publicKey.toCompressedBytes()).sublist(0, 4);
    if (_fromXpub) {
      final newPoint = ec.pointAddScalar(_ecPublic.toBytes(), key, true);
      if (newPoint == null) {
        return _addDrive(index + 1);
      }
      return HdWallet._fromPublicKey(
          public: ECPublic.fromBytes(newPoint),
          chainCode: chain,
          depth: childDeph,
          index: childIndex,
          fingerPrint: finger);
    }
    final newPrivate = ec.generateTweek((_private).toBytes(), key);
    return HdWallet._fromPrivateKey(
        privateKey: ECPrivate.fromBytes(newPrivate!),
        chainCode: chain,
        depth: childDeph,
        index: childIndex,
        fingerPrint: finger);
  }

  static bool isValidPath(String path) {
    final regex = RegExp(r"^(m\/)?(\d+'?\/)*\d+'?$");
    return regex.hasMatch(path);
  }

  static (bool, Uint8List) isRootKey(String xPrivateKey, NetworkInfo network,
      {bool isPublicKey = false}) {
    final dec = bs.base58.decodeCheck(xPrivateKey);
    if (dec.length != 78) {
      throw ArgumentError("invalid xPrivateKey");
    }
    final semantic = dec.sublist(0, 4);
    final version = isPublicKey
        ? NetworkInfo.networkFromXPublicPrefix(semantic)
        : NetworkInfo.networkFromXPrivePrefix(semantic);
    if (version == null) {
      throw ArgumentError("invalid network");
    }
    final networkPrefix = isPublicKey
        ? network.extendPublic[version]!
        : network.extendPrivate[version]!;
    final prefix = hexToBytes("${networkPrefix}000000000000000000");
    return (bytesListEqual(prefix, dec.sublist(0, prefix.length)), dec);
  }

  factory HdWallet.fromXPrivateKey(String xPrivateKey,
      {bool? foreRootKey, NetworkInfo network = NetworkInfo.BITCOIN}) {
    final check = isRootKey(xPrivateKey, network);
    if (foreRootKey != null) {
      if (check.$1 != foreRootKey) {
        throw ArgumentError(
            "is not valid ${foreRootKey ? "rootXPrivateKey" : "xPrivateKey"}");
      }
    }
    final decode = _decodeXKeys(check.$2);
    final chain = decode[4];
    final private = ECPrivate.fromBytes(decode[5]);
    final index = intFromBytes(decode[3], Endian.big);
    final deph = intFromBytes(decode[1], Endian.big);
    return HdWallet._fromPrivateKey(
        privateKey: private,
        chainCode: chain,
        depth: deph,
        fingerPrint: decode[2],
        index: index);
  }

  static List<Uint8List> _decodeXKeys(Uint8List xKey, {bool isPublic = false}) {
    return [
      xKey.sublist(0, 4),
      xKey.sublist(4, 5),
      xKey.sublist(5, 9),
      xKey.sublist(9, 13),
      xKey.sublist(13, 45),
      xKey.sublist(isPublic ? 45 : 46)
    ];
  }

  /// return xpub as base58
  String toXpublicKey(
      {AddressType semantic = AddressType.p2pkh,
      NetworkInfo network = NetworkInfo.BITCOIN}) {
    final version = hexToBytes(network.extendPublic[semantic]!);
    final depthBytes = Uint8List.fromList([depth]);
    final fingerPrintBytes = _fingerPrint;
    final indexBytes = packUint32BE(index);
    final data = publicKey.toCompressedBytes();
    final result = Uint8List.fromList([
      ...version,
      ...depthBytes,
      ...fingerPrintBytes,
      ...indexBytes,
      ..._chainCode,
      ...data
    ]);
    final check = bs.base58.encodeCheck(result);
    return check;
  }

  /// return root or not root public wallet from xPublicKey
  factory HdWallet.fromXpublicKey(String xPublicKey,
      {bool? forceRootKey, NetworkInfo network = NetworkInfo.BITCOIN}) {
    final check = isRootKey(xPublicKey, network, isPublicKey: true);
    if (forceRootKey != null) {
      if (check.$1 != forceRootKey) {
        throw ArgumentError(
            "is not valid ${forceRootKey ? "rootPublicKey" : "publicKey"}");
      }
    }
    final decode = _decodeXKeys(check.$2, isPublic: true);
    final chain = decode[4];
    final publicKey = ECPublic.fromBytes(decode[5]);
    final index = intFromBytes(decode[3], Endian.big);
    final deph = intFromBytes(decode[1], Endian.big);
    return HdWallet._fromPublicKey(
        public: publicKey,
        chainCode: chain,
        depth: deph,
        fingerPrint: decode[2],
        index: index);
  }

  String toXpriveKey(
      {AddressType semantic = AddressType.p2pkh,
      NetworkInfo network = NetworkInfo.BITCOIN}) {
    if (_fromXpub) {
      throw ArgumentError("connot access private from publicKey wallet");
    }
    final version = hexToBytes(network.extendPrivate[semantic]!);
    final depthBytes = Uint8List.fromList([depth]);
    final fingerPrintBytes = _fingerPrint;
    final indexBytes = packUint32BE(index);
    final data = Uint8List.fromList([0, ..._private.toBytes()]);
    final result = Uint8List.fromList([
      ...version,
      ...depthBytes,
      ...fingerPrintBytes,
      ...indexBytes,
      ..._chainCode,
      ...data
    ]);
    final check = bs.base58.encodeCheck(result);
    return check;
  }

  static HdWallet drivePath(HdWallet masterWallet, String path) {
    if (!isValidPath(path)) throw ArgumentError("invalid BIP32 Path");
    List<String> splitPath = path.split("/");
    if (splitPath[0] == "m") {
      splitPath = splitPath.sublist(1);
    }
    return splitPath.fold(masterWallet, (HdWallet prevHd, String indexStr) {
      int index;
      if (indexStr.substring(indexStr.length - 1) == "'") {
        index = int.parse(indexStr.substring(0, indexStr.length - 1));
        if (index > _maxUint31 || index < 0) {
          throw ArgumentError("Wrong index");
        }
        final newDrive = prevHd._addDrive(index + _highBit);
        return newDrive;
      } else {
        index = int.parse(indexStr);
        final newDrive = prevHd._addDrive(index);
        return newDrive;
      }
    });
  }
}
