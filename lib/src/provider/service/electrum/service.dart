import 'package:bitcoin_base/src/provider/service/electrum/params.dart';

/// A mixin for providing JSON-RPC service functionality.
mixin BitcoinBaseElectrumRPCService {
  /// Represents the URL endpoint for JSON-RPC calls.
  String get url;

  /// Makes an HTTP GET request to the Tron network with the specified [params].
  ///
  /// The optional [timeout] parameter sets the maximum duration for the request.
  Future<Map<String, dynamic>> call(ElectrumRequestDetails params,
      [Duration? timeout]);
}
