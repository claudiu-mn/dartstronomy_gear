import 'package:dartstronomy_gear/src/connection/connection_simulator.dart';
import 'package:dartstronomy_gear/src/mounts/dartstronomy_mount.dart';
import 'package:dartstronomy_gear/src/mounts/mount_simulator.dart';

DartstronomyMount getSimulatedMount(double reliability, [int? seed]) {
  return MountSimulator(
    connection: ConnectionSimulator(reliability: reliability, seed: seed),
  );
}
