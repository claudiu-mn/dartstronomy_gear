import 'package:dartstronomy_gear/src/connection/serial_connection.dart';
import 'package:dartstronomy_gear/src/mounts/dartstronomy_mount.dart';
import 'package:dartstronomy_gear/src/mounts/mount_request.dart';
import 'package:meta/meta.dart';

class DartstronomyMountBase<I, O> {
  DartstronomyMountBase({
    required this.connection,
    this.timeout = const Duration(milliseconds: 1000),
  });

  Duration timeout;

  @protected
  final SerialConnection<I, O> connection;

  @protected
  Future<O> makeRequest(MountRequest<I> request) async =>
      connection.send(request.objectForConnection, timeout);
}

mixin DartstronomyMountExtras<I, O>
    implements DartstronomyMountBase<I, O>, DartstronomyMount {
  @override
  Duration? get timeoutEta => connection.timeUntilTimeout;
}
