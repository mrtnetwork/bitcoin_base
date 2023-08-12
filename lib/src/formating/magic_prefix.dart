import 'dart:convert';
import 'dart:typed_data';

import 'package:bitcoin/src/crypto/crypto.dart';
import 'package:bitcoin/src/formating/bytes_num_formating.dart';
import 'package:bitcoin/src/models/network.dart';

Uint8List _magicPrefix(String message,
    {NetworkInfo network = NetworkInfo.BITCOIN}) {
  final size = encodeVarint(message.length);
  final bytes = utf8.encode(message);
  return Uint8List.fromList(
      [...utf8.encode(network.messagePrefix), ...size, ...bytes]);
}

Uint8List magicMessage(String message,
    {NetworkInfo network = NetworkInfo.BITCOIN}) {
  final magic = _magicPrefix(message, network: network);
  return singleHash(magic);
}
