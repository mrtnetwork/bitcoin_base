import 'package:blockchain_utils/blockchain_utils.dart';

extension Take<T> on List<T> {
  List<T> takeShuffle([int limit = 2]) {
    final shuffle = clone()..shuffle();
    return shuffle.take(limit).toList();
  }
}
