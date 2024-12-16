import 'package:dartstronomy_gear/src/mounts/movement.dart';

enum DartstronomyMountExceptionType {
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
  malformedMotorStatus,
  unknown,
}

class DartstronomyMountException implements Exception {
  DartstronomyMountException({required this.type, this.message});

  final DartstronomyMountExceptionType type;
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
  /// Throws [DartstronomyMountException].
  Future<void> setUp();

  /// Throws [DartstronomyMountException].
  Future<void> cruise(Movement movement);

  /// Throws [DartstronomyMountException].
  Future<void> shoot(Movement movement);
}
