import 'dart:async';
import 'dart:io';
import 'core.dart';

Future<WebSocketCore> connectSoc(String url, {List<String>? protocols}) async =>
    await WebsocketIO.connect(url);

class WebsocketIO implements WebSocketCore {
  final WebSocket _socket;
  final StreamController<dynamic> _streamController =
      StreamController<dynamic>();
  @override
  bool get isConnected => _socket.readyState == WebSocket.open;
  WebsocketIO._(this._socket) {
    _socket.listen(
      (dynamic data) {
        _streamController.add(data);
      },
      onDone: () {
        _streamController.close();
      },
      onError: (dynamic error) {
        // Handle errors as needed
        _streamController.addError(error);
      },
    );
  }

  @override
  void close({int? code}) {
    _socket.close(code, 'Closed by client.');
  }

  @override
  Stream<dynamic> get stream => _streamController.stream;

  static Future<WebsocketIO> connect(String url,
      {List<String>? protocols}) async {
    final completer = Completer<WebsocketIO>();
    final socket = await WebSocket.connect(url, protocols: protocols);
    completer.complete(WebsocketIO._(socket));

    return completer.future;
  }

  @override
  void sink(List<int> message) {
    _socket.add(message);
  }
}
