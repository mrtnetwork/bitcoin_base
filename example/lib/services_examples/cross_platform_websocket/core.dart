/// I haven't implemented any specific HTTP service or socket service within this plugin.
/// The reason is that different applications may use various plugins or methods
/// to interact with network protocols. However,
/// I have included numerous examples to demonstrate
/// how Electrum and HTTP services can be utilized. You can
/// leverage these examples as a reference to easily create
/// your own services tailored to your application's specific needs.
import 'cross.dart'
    if (dart.library.html) 'web.dart'
    if (dart.library.io) 'io.dart';

abstract class WebSocketCore {
  void close({int? code});
  void sink(List<int> message);
  Stream<dynamic> get stream;
  bool get isConnected;
  static Future<WebSocketCore> connect(String url,
          {List<String>? protocols}) async =>
      connectSoc(url, protocols: protocols);
}
