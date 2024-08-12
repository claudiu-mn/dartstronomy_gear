import 'package:dartstronomy_gear/src/connection/serial_connection.dart';
import 'package:dartstronomy_gear/src/mounts/dartstronomy_mount.dart';
import 'package:dartstronomy_gear/src/mounts/dartstronomy_mount_base.dart';
import 'package:dartstronomy_gear/src/mounts/movement.dart';

final class MountSimulator extends DartstronomyMountBase<void, void>
    with DartstronomyMountExtras<void, void>
    implements DartstronomyMount {
  MountSimulator({required super.connection});

  @override
  String get name =>
      'Mt Sim [${identityHashCode(this).toRadixString(16).toUpperCase()}]';

  bool _wasSetUp = false;

  @override
  Future<void> cruise(Movement movement) async {
    _throwIfNotSetUp();
    await _send();
  }

  @override
  Future<void> shoot(Movement movement) async {
    _throwIfNotSetUp();
    await _send();
  }

  @override
  Future<void> setUp() async {
    await _send();
    _wasSetUp = true;
  }

  Future<void> _send() async {
    try {
      await connection.send(null, timeout);
    } on SerialConnectionException catch (e) {
      DartstronomyMountErrorType errorType;

      switch (e.type) {
        case SerialConnectionExceptionType.anotherRequestInProgress:
          errorType = DartstronomyMountErrorType.anotherRequestInProgress;
          break;

        case SerialConnectionExceptionType.timedOut:
          errorType = DartstronomyMountErrorType.timedOut;
          break;

        default:
          errorType = DartstronomyMountErrorType.unknown;
          break;
      }

      throw DartstronomyMountError(
        type: errorType,
        message: 'Simulated error with $connection: $e',
      );
    }
  }

  void _throwIfNotSetUp() {
    if (!_wasSetUp) {
      throw DartstronomyMountError(
        type: DartstronomyMountErrorType.notSetUp,
      );
    }
  }
}
