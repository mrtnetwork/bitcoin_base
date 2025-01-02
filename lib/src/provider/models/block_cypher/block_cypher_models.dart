import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/provider/models/utxo_details.dart';

class TxRef implements UTXO {
  final String txHash;
  final int blockHeight;
  final int txInputN;
  final int txOutputN;
  final BigInt value;
  final int refBalance;
  final bool spent;
  final int confirmations;
  final DateTime confirmed;
  final String script;

  TxRef({
    required this.txHash,
    required this.blockHeight,
    required this.txInputN,
    required this.txOutputN,
    required this.value,
    required this.refBalance,
    required this.spent,
    required this.confirmations,
    required this.confirmed,
    required this.script,
  });

  factory TxRef.fromJson(Map<String, dynamic> json) {
    return TxRef(
      txHash: json['tx_hash'],
      blockHeight: json['block_height'],
      txInputN: json['tx_input_n'],
      txOutputN: json['tx_output_n'],
      value: BigInt.from(json['value']),
      refBalance: json['ref_balance'],
      spent: json['spent'],
      confirmations: json['confirmations'],
      confirmed: DateTime.parse(json['confirmed']),
      script: json['script'],
    );
  }

  @override
  BitcoinUtxo toUtxo(BitcoinAddressType addressType) {
    return BitcoinUtxo(
        txHash: txHash,
        value: value,
        vout: txOutputN,
        scriptType: addressType,
        blockHeight: blockHeight);
  }
}

class BlockCypherUtxo {
  final String address;
  final int totalReceived;
  final int totalSent;
  final int balance;
  final int unconfirmedBalance;
  final int finalBalance;
  final int nTx;
  final int unconfirmedNTx;
  final int finalNTx;
  final List<TxRef> txRefs;
  final String txURL;

  BlockCypherUtxo({
    required this.address,
    required this.totalReceived,
    required this.totalSent,
    required this.balance,
    required this.unconfirmedBalance,
    required this.finalBalance,
    required this.nTx,
    required this.unconfirmedNTx,
    required this.finalNTx,
    required this.txRefs,
    required this.txURL,
  });

  factory BlockCypherUtxo.fromJson(Map<String, dynamic> json) {
    return BlockCypherUtxo(
      address: json['address'],
      totalReceived: json['total_received'],
      totalSent: json['total_sent'],
      balance: json['balance'],
      unconfirmedBalance: json['unconfirmed_balance'],
      finalBalance: json['final_balance'],
      nTx: json['n_tx'],
      unconfirmedNTx: json['unconfirmed_n_tx'],
      finalNTx: json['final_n_tx'],
      txRefs: (json['txrefs'] as List?)
              ?.map((ref) => TxRef.fromJson(ref))
              .toList() ??
          <TxRef>[],
      txURL: json['tx_url'],
    );
  }

  List<UtxoWithAddress> toUtxoWithOwner(UtxoAddressDetails owner) {
    final utxos = txRefs.map((ref) {
      return UtxoWithAddress(
        utxo: ref.toUtxo(owner.address.type),
        ownerDetails: owner,
      );
    }).toList();
    return utxos;
  }
}

class BlockCypherTransactionInput {
  final String prevHash;
  final int outputIndex;
  final int outputValue;
  final int sequence;
  final List<String> addresses;
  final String scriptType;
  final int age;
  final List<String>? witness;

  BlockCypherTransactionInput({
    required this.prevHash,
    required this.outputIndex,
    required this.outputValue,
    required this.sequence,
    required this.addresses,
    required this.scriptType,
    required this.age,
    required this.witness,
  });

  factory BlockCypherTransactionInput.fromJson(Map<String, dynamic> json) {
    return BlockCypherTransactionInput(
      prevHash: json['prev_hash'],
      outputIndex: json['output_index'],
      outputValue: json['output_value'],
      sequence: json['sequence'],
      addresses: List<String>.from(json['addresses']),
      scriptType: json['script_type'],
      age: json['age'],
      witness: (json['witness'] as List?)?.cast(),
    );
  }
}

class BlockCypherTransactionOutput {
  final int value;
  final String script;
  final List<String> addresses;
  final String scriptType;
  final String? dataHex;
  final String? dataString;

  BlockCypherTransactionOutput({
    required this.value,
    required this.script,
    required this.addresses,
    required this.scriptType,
    required this.dataHex,
    required this.dataString,
  });

  factory BlockCypherTransactionOutput.fromJson(Map<String, dynamic> json) {
    return BlockCypherTransactionOutput(
      value: json['value'],
      script: json['script'],
      addresses: List<String>.from(json['addresses'] ?? []),
      scriptType: json['script_type'],
      dataHex: json['data_hex'],
      dataString: json['data_string'],
    );
  }
}

class BlockCypherTransaction {
  final int blockHeight;
  final int blockIndex;
  final String hash;
  final List<String> addresses;
  final int total;
  final int fees;
  final int size;
  final int? vSize;
  final String preference;
  final String? relayedBy;
  final DateTime? received;
  final int ver;
  final bool doubleSpend;
  final int vinSz;
  final int voutSz;
  final bool? optInRBF;
  final String? dataProtocol;
  final int confirmations;
  final List<BlockCypherTransactionInput> inputs;
  final List<BlockCypherTransactionOutput> outputs;

  BlockCypherTransaction({
    required this.blockHeight,
    required this.blockIndex,
    required this.hash,
    required this.addresses,
    required this.total,
    required this.fees,
    required this.size,
    required this.vSize,
    required this.preference,
    required this.relayedBy,
    required this.received,
    required this.ver,
    required this.doubleSpend,
    required this.vinSz,
    required this.voutSz,
    required this.optInRBF,
    required this.dataProtocol,
    required this.confirmations,
    required this.inputs,
    required this.outputs,
  });

  factory BlockCypherTransaction.fromJson(Map<String, dynamic> json) {
    return BlockCypherTransaction(
      blockHeight: json['block_height'],
      blockIndex: json['block_index'],
      hash: json['hash'],
      addresses: List<String>.from(json['addresses']),
      total: json['total'],
      fees: json['fees'],
      size: json['size'],
      vSize: json['vsize'],
      preference: json['preference'],
      relayedBy: json['relayed_by'],
      received:
          json['received'] == null ? null : DateTime.parse(json['received']),
      ver: json['ver'],
      doubleSpend: json['double_spend'],
      vinSz: json['vin_sz'],
      voutSz: json['vout_sz'],
      optInRBF: json['opt_in_rbf'],
      dataProtocol: json['data_protocol'],
      confirmations: json['confirmations'],
      inputs: (json['inputs'] as List<dynamic>)
          .map((input) => BlockCypherTransactionInput.fromJson(input))
          .toList(),
      outputs: (json['outputs'] as List<dynamic>)
          .map((output) => BlockCypherTransactionOutput.fromJson(output))
          .toList(),
    );
  }
}

class BlockCypherAddressInfo {
  final String address;
  final int totalReceived;
  final int totalSent;
  final int balance;
  final int unconfirmedBalance;
  final int finalBalance;
  final int numTransactions;
  final int unconfirmedNumTx;
  final int finalNumTx;
  final List<BlockCypherTransaction> txs;

  BlockCypherAddressInfo({
    required this.address,
    required this.totalReceived,
    required this.totalSent,
    required this.balance,
    required this.unconfirmedBalance,
    required this.finalBalance,
    required this.numTransactions,
    required this.unconfirmedNumTx,
    required this.finalNumTx,
    required this.txs,
  });

  factory BlockCypherAddressInfo.fromJson(Map<String, dynamic> json) {
    return BlockCypherAddressInfo(
      address: json['address'],
      totalReceived: json['total_received'],
      totalSent: json['total_sent'],
      balance: json['balance'],
      unconfirmedBalance: json['unconfirmed_balance'],
      finalBalance: json['final_balance'],
      numTransactions: json['n_tx'],
      unconfirmedNumTx: json['unconfirmed_n_tx'],
      finalNumTx: json['final_n_tx'],
      txs: (json['txs'] as List?)
              ?.map(
                  (transaction) => BlockCypherTransaction.fromJson(transaction))
              .toList() ??
          [],
    );
  }
}
