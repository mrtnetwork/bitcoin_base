## 6.5.0

- Fix transaction parsing in Mempool API.

## 6.4.0

- Update dependencies.
- Improved security: Private key operations now use blinded ecmult for safer public key generation.
- All signing methods now use constant-time operations with blinded ecmult to securely generate signatures.



## 6.3.0

- Update dependencies.
- Add estimate transaction size for psbt
- Add more script validation in psbt

## 6.2.0

- Update dependencies.
- Support PSBT for BCH
- Support for BIP-173
- Support for BCH schnorr signing

## 6.1.0

- Fix der signature validation.

## 6.0.0

- Added support for BIP-327: MuSig2 for BIP340-compatible multi-signatures
- Implemented BIP-174: Partially Signed Bitcoin Transaction (PSBT) format
- Integrated BIP-370: PSBT Version 2 enhancements
- Included BIP-371: Taproot fields for PSBT
- Extended support for BIP-373: MuSig2-related PSBT fields

## 5.3.0

* Update dependencies

## 5.2.0

* Update dependencies

## 5.1.0

* Update dependencies

## 5.0.0

* Update dependencies
* Minimum required Dart SDK version updated to 3.3.

## 4.9.4

* Improved serialization process for large transaction scripts.
* Added support for the Electra network.
* Create and spent from uncomprossed public key format.
* Important Notice: This is the final version supporting Dart v2. The next release will require Dart v3.3 or higher.

## 4.9.2

* Update dependencies
* Resolved issue with transaction deserialization (unsigned tx)

## 4.9.1

* Resolved issue with transaction deserialization (Issue #9)

## 4.9.0

* Correct Bitcoin address network configuration.
* Resolve issue with Electrum fee estimation results.


## 4.8.0

* Update dependencies

## 4.7.0

* Update dependencies

## 4.6.0

* add asyncTransactionBuilder method to support building transactions asynchronously.

## 4.5.0

* Added support for Pepecoin network
* Update dependencies

## 4.4.0

* Update dependencies

## 4.3.0

* Update dependencies

## 4.2.2

* Added hourFee and economyFee to mempool api getNetworkFeeRate method

## 4.2.1

* Update dependencies

## 4.2.0

* Update dependencies

## 4.1.0

* Update dependencies

## 4.0.0

* Added support for BitcoinSV network
* Introduced classes for improved network address handling
* Implemented functionalities to create, sign, spend, mint, and burn Bitcoin Cash Tokens (FT, NFT tokens)
* Implemented a class for creating the Bitcoin Cash Metadata Registry (BCMR).
* Utilized BIP69 ordering for enhanced transaction sorting

## 3.0.3

* Update dependencies

## 3.0.2

* Update dependencies

## 3.0.1

* Update dependencies

## 3.0.0

* Downgrade dart SDK from 3.1 to 2.15
* Update dependencies

## 2.0.1

* add some types for find network address support

## 2.0.0

* Added support for Dogecoin, Litecoin, Bitcoin Cash, and Dash.

## 1.4.0

* Fix blockcypher API

## 1.3.0

* Include a constructor in the address for improved clarity and comprehension.
* Update dependencies.

## 1.2.0

* Update dependencies
* The http package was removed from dependencies. Use your HTTP provider
* Remove all dependencies except `blockchain_utils`  
* Change AddressType to BitcoinAddressType

## 1.1.0

* Update dependencies

## 1.0.0

* TransactionBuilder
* Fix bugs

## 0.5.0

* Fix p2sh(segwit)

## 0.4.0

* add bip32, bip39
* add hdwallet
* add new bitcoin address types p2sh(segwit)

## 0.2.0

* commands for methods, better understanding
* add lints package to dependencies

## 0.1.0

* TODO: Release.
