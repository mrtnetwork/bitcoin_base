import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/provider/models/utxo_details.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class MempoolPrevOut {
  final String scriptPubKey;
  final String scriptPubKeyAsm;
  final String scriptPubKeyType;
  final String scriptPubKeyAddress;
  final int value;

  MempoolPrevOut({
    required this.scriptPubKey,
    required this.scriptPubKeyAsm,
    required this.scriptPubKeyType,
    required this.scriptPubKeyAddress,
    required this.value,
  });

  factory MempoolPrevOut.fromJson(Map<String, dynamic> json) {
    return MempoolPrevOut(
      scriptPubKey: json['scriptpubkey'],
      scriptPubKeyAsm: json['scriptpubkey_asm'],
      scriptPubKeyType: json['scriptpubkey_type'],
      scriptPubKeyAddress: json['scriptpubkey_address'],
      value: json['value'],
    );
  }
}

class MempoolVin {
  final String txID;
  final int vout;
  final MempoolPrevOut prevOut;
  final String scriptSig;
  final String scriptSigAsm;
  final List<String> witness;
  final bool isCoinbase;
  final int sequence;

  MempoolVin({
    required this.txID,
    required this.vout,
    required this.prevOut,
    required this.scriptSig,
    required this.scriptSigAsm,
    required this.witness,
    required this.isCoinbase,
    required this.sequence,
  });

  factory MempoolVin.fromJson(Map<String, dynamic> json) {
    return MempoolVin(
      txID: json['txid'],
      vout: json['vout'],
      prevOut: MempoolPrevOut.fromJson(json['prevout']),
      scriptSig: json['scriptsig'],
      scriptSigAsm: json['scriptsig_asm'],
      witness: List<String>.from(json['witness'] ?? []),
      isCoinbase: json['is_coinbase'],
      sequence: json['sequence'],
    );
  }
}

class MempoolVout {
  final String scriptPubKey;
  final String scriptPubKeyAsm;
  final String scriptPubKeyType;
  final String? scriptPubKeyAddress;
  final int value;

  MempoolVout({
    required this.scriptPubKey,
    required this.scriptPubKeyAsm,
    required this.scriptPubKeyType,
    required this.scriptPubKeyAddress,
    required this.value,
  });

  factory MempoolVout.fromJson(Map<String, dynamic> json) {
    return MempoolVout(
      scriptPubKey: json['scriptpubkey'],
      scriptPubKeyAsm: json['scriptpubkey_asm'],
      scriptPubKeyType: json['scriptpubkey_type'],
      scriptPubKeyAddress: json['scriptpubkey_address'],
      value: json['value'],
    );
  }
}

class MempoolStatus {
  final bool confirmed;
  final int? blockHeight;
  final String? blockHash;
  final int? blockTime;

  MempoolStatus({
    required this.confirmed,
    required this.blockHeight,
    required this.blockHash,
    required this.blockTime,
  });

  factory MempoolStatus.fromJson(Map<String, dynamic> json) {
    return MempoolStatus(
      confirmed: json['confirmed'],
      blockHeight: json['block_height'],
      blockHash: json['block_hash'],
      blockTime: json['block_time'],
    );
  }
}

class MempoolTransaction {
  final String txID;
  final int version;
  final int locktime;
  final List<MempoolVin> vin;
  final List<MempoolVout> vout;
  final int size;
  final int weight;
  final int fee;
  final MempoolStatus status;

  MempoolTransaction({
    required this.txID,
    required this.version,
    required this.locktime,
    required this.vin,
    required this.vout,
    required this.size,
    required this.weight,
    required this.fee,
    required this.status,
  });

  factory MempoolTransaction.fromJson(Map<String, dynamic> json) {
    return MempoolTransaction(
      txID: json['txid'],
      version: json['version'],
      locktime: json['locktime'],
      vin: List<MempoolVin>.from(
          (json['vin'] as List).map((x) => MempoolVin.fromJson(x))),
      vout: List<MempoolVout>.from(
          (json['vout'] as List).map((x) => MempoolVout.fromJson(x))),
      size: json['size'],
      weight: json['weight'],
      fee: json['fee'],
      status: MempoolStatus.fromJson(json['status']),
    );
  }
}

class MempolUtxo implements UTXO {
  final String txid;
  final int vout;
  final MempoolStatus status;
  final BigInt value;

  MempolUtxo({
    required this.txid,
    required this.vout,
    required this.status,
    required this.value,
  });

  factory MempolUtxo.fromJson(Map<String, dynamic> json) {
    return MempolUtxo(
      txid: json['txid'],
      vout: json['vout'],
      status: MempoolStatus.fromJson(json['status']),
      value: BigintUtils.parse(json['value']),
    );
  }

  @override
  BitcoinUtxo toUtxo(BitcoinAddressType addressType) {
    return BitcoinUtxo(
        txHash: txid,
        value: value,
        vout: vout,
        scriptType: addressType,
        blockHeight: 1);
  }

  @override
  Map<String, dynamic> toJson() {
    return {"txid": txid, "vout": vout, "status": status, "value": value};
  }
}

extension MempoolUtxoExtentions on List<MempolUtxo> {
  List<UtxoWithAddress> toUtxoWithOwnerList(UtxoAddressDetails owner) {
    final utxos = map((e) => UtxoWithAddress(
          utxo: BitcoinUtxo(
            txHash: e.txid,
            value: e.value,
            vout: e.vout,
            scriptType: owner.address.type,
            blockHeight: 1,
          ),
          ownerDetails: owner,
        )).toList();

    return utxos;
  }
}
