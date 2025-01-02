import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// Bitcoin Cash Metadata Registries Script to convert uris and content hash to bitcoin output script
class BCMR implements BitcoinScriptOutput {
  /// Bitcoin Cash Metadata Registries PREFIX
  static const String _pcmrInHex = '42434d52';
  BCMR({required this.uris, required this.hash})
      : assert(
          () {
            if (uris.isEmpty) return false;
            if (!StringUtils.isHexBytes(hash)) return false;
            if (BytesUtils.fromHexString(hash).length != SHA256.digestLength) {
              return false;
            }
            return true;
          }(),
          uris.isEmpty
              ? 'URIs must not be empty.'
              : 'The BCMR hash should be the SHA-256 hash of the URI contents',
        );

  /// list of uris
  final List<String> uris;

  /// uris content SHA-256
  final String hash;

  ///  'script' property from the interface to define the specific script for Bitcoin Cash Metadata Registries OP_RETURN script.
  @override
  Script get script => Script(script: [
        'OP_RETURN',
        _pcmrInHex,
        hash,
        ...uris.map((e) => BytesUtils.toHexString(StringUtils.encode(e)))
      ]);

  /// To Transaction output
  @override
  TxOutput get toOutput => TxOutput(amount: BigInt.zero, scriptPubKey: script);

  /// output value. always zero
  @override
  final BigInt value = BigInt.zero;
}
