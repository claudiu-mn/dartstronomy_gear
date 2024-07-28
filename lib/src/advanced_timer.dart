import 'dart:async';

/// A millisecond precision timer.
class AnotherTimer implements Timer {
  AnotherTimer._(this.duration, this._timer, this._watch);

  AnotherTimer(this.duration, void Function() callback)
      : _timer = Timer(duration, callback),
        _watch = Stopwatch()..start();

  /// Creates a new repeating timer.
  ///
  /// The [callback] is invoked repeatedly with [duration] intervals until
  /// canceled with the [cancel] function.
  ///
  /// The exact timing depends on the underlying timer implementation.
  /// No more than `n` callbacks will be made in `duration * n` time,
  /// but the time between two consecutive callbacks
  /// can be shorter and longer than `duration`.
  ///
  /// In particular, an implementation may schedule the next callback, e.g.,
  /// a `duration` after either when the previous callback ended,
  /// when the previous callback started, or when the previous callback was
  /// scheduled for - even if the actual callback was delayed.
  ///
  /// A negative [duration] is treated the same as [Duration.zero].
  ///
  /// Example:
  /// ```dart
  /// var counter = 3;
  /// AnotherTimer.periodic(const Duration(seconds: 2), (timer) {
  ///   print(timer.tick);
  ///   counter--;
  ///   if (counter == 0) {
  ///     print('Cancel timer');
  ///     timer.cancel();
  ///   }
  /// });
  /// // Outputs:
  /// // 1
  /// // 2
  /// // 3
  /// // "Cancel timer"
  /// ```
  factory AnotherTimer.periodic(
    Duration duration,
    void Function(Timer timer) callback,
  ) {
    final watch = Stopwatch()..start();
    final timer = Timer.periodic(duration, (t) {
      watch.reset();
      callback(t);
    });

    return AnotherTimer._(duration, timer, watch);
  }

  final Duration duration;

  final Timer _timer;
  final Stopwatch _watch;

  /// Returns:
  ///   - for a non-periodic timer, the elapsed time since the timer was started
  ///   - for a periodic timer, the elapsed time since the last callback execution
  Duration get elapsed => Duration(milliseconds: _watch.elapsedMilliseconds);

  /// Returns:
  ///   - `null` if not active
  ///   - remaining time until the next (on a periodic timer) or the only (on a
  ///     non-periodic timer) callback execution
  Duration? get remaining => !_timer.isActive
      ? null
      : Duration(
          milliseconds: duration.inMilliseconds - _watch.elapsedMilliseconds,
        );

  /// Cancels the timer.
  ///
  /// Once an [AnotherTimer] has been canceled, the callback function will not
  /// be called by the timer. Calling [cancel] more than once on an
  /// [AnotherTimer] is allowed, and will have no further effect.
  ///
  /// Example:
  /// ```dart
  /// final timer = AnotherTimer(
  ///   const Duration(seconds: 5),
  ///   () => print('Timer finished')
  /// );
  /// // Cancel timer, callback never called.
  /// timer.cancel();
  /// ```
  @override
  void cancel() => _timer.cancel();

  /// Returns whether the timer is still active.
  ///
  /// A non-periodic timer is active if the callback has not been executed,
  /// and the timer has not been canceled.
  ///
  /// A periodic timer is active if it has not been canceled.
  @override
  bool get isActive => _timer.isActive;

  /// The number of durations preceding the most recent timer event.
  ///
  /// The value starts at zero and is incremented each time a timer event
  /// occurs, so each callback will see a larger value than the previous one.
  ///
  /// If a periodic timer with a non-zero duration is delayed too much,
  /// so more than one tick should have happened,
  /// all but the last tick in the past are considered "missed",
  /// and no callback is invoked for them.
  /// The [tick] count reflects the number of durations that have passed and
  /// not the number of callback invocations that have happened.
  ///
  /// Example:
  /// ```dart
  /// final stopwatch = Stopwatch()..start();
  /// AnotherTimer.periodic(const Duration(seconds: 1), (timer) {
  ///   print(timer.tick);
  ///   if (timer.tick == 1) {
  ///     while (stopwatch.elapsedMilliseconds < 4500) {
  ///       // Run uninterrupted for another 3.5 seconds!
  ///       // The latest due tick after that is the 4-second tick.
  ///     }
  ///   } else {
  ///     timer.cancel();
  ///   }
  /// });
  /// // Outputs:
  /// // 1
  /// // 4
  /// ```
  @override
  int get tick => _timer.tick;
}
