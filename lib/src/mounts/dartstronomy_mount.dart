import 'package:dartstronomy_gear/src/mounts/movement.dart';

enum DartstronomyMountErrorType {
  unknownCommand,
  commandLength,
  motorNotStopped,
  invalidCharacter,
  notInitialized,
  driverSleeping,
  pecTrainingRunning,
  noValidPecData,
  malformedResponse,
  timedOut,
  anotherRequestInProgress,
  setUpFailure,
  notSetUp,
  unknown,
}

class DartstronomyMountError extends Error {
  DartstronomyMountError({required this.type, this.message});

  final DartstronomyMountErrorType type;
  final String? message;

  @override
  String toString() {
    final msg = message != null ? '($message)' : '';
    return '$runtimeType.${type.name}$msg';
  }
}

abstract interface class DartstronomyMount {
  String get name;

  Duration get timeout;
  set timeout(Duration value);

  /// Returns:
  ///   - `null` if the communication line is idle
  ///   - the estimated time until the current operation potentially times out
  Duration? get timeoutEta;

  /// You must call this before calling other methods on [DartstronomyMount].
  /// The initial call sets up the mount for it to be used.
  /// Subsequent calls do nothing.
  ///
  /// Throws [DartstronomyMountError].
  Future<void> setUp();

  /// Throws [DartstronomyMountError].
  Future<void> setMovement(Movement movement);
}
