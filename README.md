# BITCOIN Dart Package

Dart library for Bitcoin-family transactions: build, sign, and submit across Bitcoin, Dogecoin, Litecoin, Dash, Bitcoin Cash, and Bitcoin SV — including SegWit, Taproot, CashTokens, PSBT, MuSig2, and DKLs23 threshold signing.

This package is the continuation of the original
[mrtnetwork/bitcoin_base](https://github.com/mrtnetwork/bitcoin_base).

## Crypto engine: `blockchain_utils` dual backend

All cryptography delegates to
[`blockchain_utils`](https://github.com/mrtnetwork/blockchain_utils): pure
Dart by default, optional Rust backend (FFI on native, WASM on web). When set
(`blockchainUtils.setRustApi()`), all high-level crypto used here routes
through Rust. Rust core:
[mrtnetwork/blockchain-utils](https://github.com/mrtnetwork/blockchain-utils).

## Supported networks

| Network | Address types |
|---|---|
| Bitcoin | P2PK, P2PKH, P2SH, P2WPKH, P2WSH, P2TR, P2SH-P2WPKH, P2SH-P2WSH |
| Dogecoin | P2PK, P2PKH, P2SH |
| Litecoin | P2PK, P2PKH, P2SH, P2WPKH, P2WSH |
| Dash | P2PK, P2PKH, P2SH |
| Bitcoin Cash | P2PK, P2PKH, P2SH, P2SH32, token-aware (P2PKHWT, P2SH32WT), CashTokens, BCMR |
| Bitcoin SV | P2PK, P2PKH |

## Features

### Transactions

| Area | Support |
|---|---|
| Builders | `BitcoinTransactionBuilder` (BTC/DOGE/LTC/DASH), `ForkedTransactionBuilder` (BCH/BSV), raw `BtcTransaction` |
| Types | Legacy, SegWit (v0), Taproot, multisig, time-locked, coinbase, OP_RETURN, RBF, BIP-69 ordering, fee estimation |
| Signing | ECDSA (legacy + SegWit v0), BIP-340 Schnorr (Taproot key/script path, tap-tweak), message signing |
| Multisig | Classic multisig + `multiSigSign` batch callback (sync + async) |

### Taproot

Key-path and script-path spends, tap-tweak, Schnorr signatures and
Schnorr-MuSig aggregation.

### PSBT

BIP-174 (v0), BIP-370 (v2), BIP-371 (Taproot fields), BIP-373 (MuSig2 fields).

### MuSig2 (BIP-327)

Key aggregation, nonce aggregation, signing and verification.

### DKLs23 threshold ECDSA

`t`-of-`n` threshold ECDSA over secp256k1 via `blockchain_utils`, producing
standard DER-encoded Bitcoin signatures — no single key reconstructed. Do
**not** use DKLs23 for Taproot (P2TR): key-path spends require BIP-340
Schnorr signatures, which threshold ECDSA cannot produce. ECDSA outputs only
(P2PKH, P2SH-P2WPKH, P2WPKH, P2WSH, P2SH).

### Bitcoin Cash tokens

Fungible and non-fungible CashTokens (create, mint, send, melt, burn),
capabilities (none / mutable / minting), BCMR metadata registries.

### Providers

Electrum (WebSocket, TCP, SSL), Mempool and BlockCypher explorer APIs —
UTXOs, balances, history, fee rates, broadcast.

## Examples

See [`example/`](https://github.com/mrtnetwork/bitcoin_base/tree/main/example)
and [`test/`](https://github.com/mrtnetwork/bitcoin_base/tree/main/test)
(includes `dkls23_ecdsa.dart`, PSBT, MuSig, CashToken flows).

## Contributing

Contributions are welcome! Please follow these guidelines:

- Fork the repository and create a new branch.
- Make your changes and ensure tests pass.
- Submit a pull request with a detailed description of your changes.

## Feature requests and bugs

Please file feature requests and bugs in the issue tracker.
