import 'dart:async';

class AsyncRequestCompleter {
  AsyncRequestCompleter(this.params);
  final Completer<Map<String, dynamic>> completer = Completer();
  final Map<String, dynamic> params;
}
