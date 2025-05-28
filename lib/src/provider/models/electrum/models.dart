import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/cash_token/cash_token.dart';
import 'package:bitcoin_base/src/provider/api_provider.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

class ElectrumUtxo implements UTXO {
  factory ElectrumUtxo.fromJson(Map<String, dynamic> json) {
    return ElectrumUtxo._(
        height: IntUtils.parse(json['height']),
        txId: json['tx_hash'],
        vout: IntUtils.parse(json['tx_pos']),
        value: BigintUtils.parse(json['value']),
        token: json["token_data"] == null
            ? null
            : CashToken.fromJson(json['token_data']));
  }
  const ElectrumUtxo._(
      {required this.height,
      required this.txId,
      required this.vout,
      required this.value,
      this.token});
  final int height;
  final String txId;
  final int vout;
  final BigInt value;
  final CashToken? token;

  @override
  BitcoinUtxo toUtxo(BitcoinAddressType addressType) {
    return BitcoinUtxo(
        txHash: txId,
        value: value,
        vout: vout,
        scriptType: addressType,
        blockHeight: height,
        token: token);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "token_data": token?.toJson(),
      "height": height,
      "tx_hash": txId,
      "tx_pos": vout,
      "value": value.toString()
    };
  }
}

class ElectrumHeaderSubscribeResponse {
  final int block;
  final String hex;
  const ElectrumHeaderSubscribeResponse(
      {required this.block, required this.hex});
  factory ElectrumHeaderSubscribeResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumHeaderSubscribeResponse(
        block: IntUtils.parse(json["height"]), hex: json["hex"]);
  }
}

class ElectrumGetMerkleResponse {
  final int blockHeight;
  final int pos;
  final List<String> merkle;
  ElectrumGetMerkleResponse({
    required this.blockHeight,
    required this.pos,
    required List<String> merkle,
  }) : merkle = merkle.immutable;
  factory ElectrumGetMerkleResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumGetMerkleResponse(
      blockHeight: IntUtils.parse(json["block_height"]),
      pos: IntUtils.parse(json["pos"]),
      merkle: (json["merkle"] as List?)?.cast<String>() ?? [],
    );
  }
}

/// txid, hash, version, size, vsize, weight, locktime, vin, vout, hex, blockhash, confirmations, time, blocktime
/// txid, hash, version, size, vsize, weight, locktime, vin, vout, hex

class ElectrumVerbosTxResponse {
  final String txId;
  final String hash;
  final int version;
  final int size;
  final int? vsize;
  final int? weight;
  final int locktime;
  final String hex;
  final String? blockhash;
  final int? confirmations;
  final int? time;
  final int? blocktime;
  factory ElectrumVerbosTxResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumVerbosTxResponse(
        txId: json["txid"],
        hash: json["hash"],
        version: IntUtils.parse(json["version"]),
        size: IntUtils.parse(json["size"]),
        vsize: IntUtils.tryParse(json["vsize"]),
        weight: IntUtils.tryParse(json["weight"]),
        locktime: IntUtils.parse(json["locktime"]),
        hex: json["hex"],
        blockhash: json["blockhash"],
        confirmations: IntUtils.tryParse(json["confirmations"]),
        blocktime: IntUtils.tryParse(json["blocktime"]),
        time: IntUtils.tryParse(json["time"]));
  }
  const ElectrumVerbosTxResponse(
      {required this.txId,
      required this.hash,
      required this.version,
      required this.size,
      required this.vsize,
      required this.weight,
      required this.locktime,
      required this.hex,
      this.blockhash,
      this.confirmations,
      this.time,
      this.blocktime});
}
