import 'dart:async';

class AsyncRequestCompleter {
  AsyncRequestCompleter();
  final Completer<Map<String, dynamic>> completer = Completer();
}
