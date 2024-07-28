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
      'Mt Simulator [${identityHashCode(this).toRadixString(16).toUpperCase()}]';

  bool _wasSetUp = false;

  @override
  Future<void> setMovement(Movement movement) async {
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
      throw DartstronomyMountError(
        type: DartstronomyMountErrorType.unknown,
        message: 'Problem with $connection: $e',
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
