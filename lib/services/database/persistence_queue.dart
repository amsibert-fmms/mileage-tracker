import 'dart:async';

/// Serialises persistence operations so they can be retried/replayed when
/// running offline or under heavy contention. Each enqueued task will be
/// executed sequentially.
class PersistenceQueue {
  PersistenceQueue();

  Future<void> _tail = Future<void>.value();

  Future<T> enqueue<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _tail = _tail
        .then((_) => task())
        .then((result) {
      completer.complete(result);
    }).catchError((Object error, StackTrace stackTrace) {
      completer.completeError(error, stackTrace);
      return Future<void>.value();
    });
    return completer.future;
  }
}
