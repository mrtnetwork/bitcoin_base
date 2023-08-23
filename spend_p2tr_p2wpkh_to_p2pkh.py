import requests
from bitcoinutils.keys import PrivateKey
from bitcoinutils.setup import setup
from bitcoinutils.transactions import TxOutput, Transaction, TxInput, TxWitnessInput


def main():
    setup('testnet')
    private = PrivateKey.from_wif("cQRddJriQUjQZhQUaW1RGTNW2o3EdBFbiTJP2qRaXTjoSqk8T39m")
    public = private.get_public_key()

    # p2tr utxo details
    p2tr_scriptPubKey = public.get_taproot_address().to_script_pub_key()
    print("tapprot address: ", public.get_taproot_address().to_string())
    p2tr_utxo_tx_id = "ea4dbbc98ba57adc3ce8593a00afd03ae968d3920b5576818a90b8f305a19ccc"
    p2tr_utxo_value = 200000
    p2tr_utxo_vout = 2
    p2tr_input = TxInput(p2tr_utxo_tx_id, p2tr_utxo_vout)

    # p2wpkh utxo details. also have same problem with p2wsh
    p2wpkh_scriptPubKey = public.get_address().to_script_pub_key()
    print("p2wkh address: ", public.get_segwit_address().to_string())
    p2wpkh_utxo_tx_id = "ea4dbbc98ba57adc3ce8593a00afd03ae968d3920b5576818a90b8f305a19ccc"
    p2wpkh_utxo_value = 200000
    p2wpkh_utxo_vout = 1
    p2wpkh_input = TxInput(p2wpkh_utxo_tx_id, p2wpkh_utxo_vout)

    # taproot scriptpubkeys

    all_scripts = [p2tr_scriptPubKey, p2wpkh_scriptPubKey]
    all_amounts = [p2tr_utxo_value, p2wpkh_utxo_value]

    # output
    to_address = public.get_address()
    tx_out = TxOutput(394947, to_address.to_script_pub_key())

    # transaction
    tx = Transaction(inputs=[p2tr_input, p2wpkh_input], outputs=[tx_out],
                     has_segwit=True)

    sig_p2tr = private.sign_taproot_input(tx, 0, all_scripts, all_amounts)
    tx.witnesses.append(TxWitnessInput([sig_p2tr]))

    sig_p2wpkh = private.sign_segwit_input(tx, 1, p2wpkh_scriptPubKey, p2wpkh_utxo_value)
    tx.witnesses.append(TxWitnessInput([sig_p2wpkh, public.to_hex()]))
    print("tx digest: ", tx.serialize())
    re = requests.post("https://mempool.space/signet/api/tx", data=tx.serialize())
    if re.status_code == 200:
        print(f"transaction send {re.text}")
    else:
        print(
            re.text)  # sendrawtransaction RPC error: {"code":-26,"message":"non-mandatory-script-verify-flag (Invalid Schnorr signature)"}


if __name__ == "__main__":
    main()
