import 'core.dart';

Future<WebSocketCore> connectSoc(String url, {List<String>? protocols}) =>
    throw UnsupportedError(
        'Cannot create a instance without dart:html or dart:io.');
