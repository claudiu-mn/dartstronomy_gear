import 'dart:math';

import 'package:dartstronomy_gear/src/connection/serial_connection.dart';
import 'package:meta/meta.dart';

/// Calling [send] on [ConnectionSimulator]s created with the same [seed] and
/// [reliability] will yield the same outcome sequences (failures vs successes).
class ConnectionSimulator with SerialConnectionBase<void, void> {
  /// [reliability] will be clamped to [0, 1].
  ConnectionSimulator({
    required double reliability,
    this.seed,
  })  : reliability = reliability.clamp(0, 1),
        _random = Random(seed);

  final double reliability;
  final int? seed;

  final Random _random;

  @override
  @protected
  void onTimeToSend(void data, Duration timeout) {
    bool willFail;

    if (reliability == 0) {
      willFail = true;
    } else if (reliability == 1) {
      willFail = false;
    } else {
      willFail = _random.nextDouble() > reliability;
    }

    final clampedMs = timeout.inMilliseconds.clamp(0, 1 << 32);

    final duration = Duration(milliseconds: _random.nextInt(clampedMs));

    if (willFail) {
      final willTimeout = _random.nextBool();

      if (willTimeout) return; // Nothing to do; will timeout.

      Future.delayed(
        duration,
        () => completeWithException(
          SerialConnectionException(
            type: SerialConnectionExceptionType.unknown,
          ),
        ),
      );

      return;
    }

    Future.delayed(duration, () => completeNormally(data));
  }

  @override
  String toString() {
    final seedPart = seed == null ? '' : '; seed=$seed';
    return '$runtimeType(reliability=$reliability$seedPart)';
  }
}
