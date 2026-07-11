import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/cash_token/cash_token.dart';
import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/json/json.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class ElectrumUtxo implements UTXO {
  factory ElectrumUtxo.fromJson(Map<String, dynamic> json) {
    return ElectrumUtxo._(
      height: IntUtils.parse(json['height']),
      txId: json['tx_hash'],
      vout: IntUtils.parse(json['tx_pos']),
      value: BigintUtils.parse(json['value']),
      token:
          json["token_data"] == null
              ? null
              : CashToken.fromJson(json['token_data']),
    );
  }
  ElectrumUtxo._({
    required this.height,
    required String txId,
    required this.vout,
    required this.value,
    this.token,
  }) : txId = StringUtils.normalizeHex(txId);
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
      token: token,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "token_data": token?.toJson(),
      "height": height,
      "tx_hash": txId,
      "tx_pos": vout,
      "value": value.toString(),
    };
  }
}

class ElectrumHeaderSubscribeResponse {
  final int block;
  final String hex;
  const ElectrumHeaderSubscribeResponse({
    required this.block,
    required this.hex,
  });
  factory ElectrumHeaderSubscribeResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumHeaderSubscribeResponse(
      block: IntUtils.parse(json["height"]),
      hex: json["hex"],
    );
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

class ElectrumVerbosTxResponse {
  final String txId;
  final String? hash;
  final int? version;
  final int? size;
  final int? vsize;
  final int? weight;
  final int? locktime;
  final String? hex;
  final String? blockhash;
  final int? confirmations;
  final int? time;
  final int? blocktime;
  final bool isCoinbase;
  factory ElectrumVerbosTxResponse.fromJson(Map<String, dynamic> json) {
    final inputs = json.valueAsList<List<Map<String, dynamic>>>("vin");
    return ElectrumVerbosTxResponse(
      txId: json.valueAs("txid"),
      hash: json.valueAs("hash"),
      version: json.valueAsInt("version"),
      size: json.valueAsInt("size"),
      vsize: json.valueAsInt("vsize"),
      weight: json.valueAsInt("weight"),
      locktime: json.valueAsInt("locktime"),
      hex: json.valueAs("hex"),
      blockhash: json.valueAs("blockhash"),
      confirmations: json.valueAsInt("confirmations"),
      blocktime: json.valueAsInt("blocktime"),
      time: json.valueAsInt("time"),
      isCoinbase: inputs.length == 1 && inputs[0].hasValue("coinbase"),
    );
  }
  ElectrumVerbosTxResponse({
    required String txId,
    required this.isCoinbase,
    this.hash,
    this.version,
    this.size,
    this.vsize,
    this.weight,
    this.locktime,
    this.hex,
    this.blockhash,
    this.confirmations,
    this.time,
    this.blocktime,
  }) : txId = StringUtils.normalizeHex(txId);
}
