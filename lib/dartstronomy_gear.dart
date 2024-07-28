import 'package:dartstronomy_gear/src/connection/connection_simulator.dart';
import 'package:dartstronomy_gear/src/connection/udp_connection.dart';
import 'package:dartstronomy_gear/src/mounts/dartstronomy_mount.dart';
import 'package:dartstronomy_gear/src/mounts/mount_simulator.dart';
import 'package:dartstronomy_gear/src/mounts/synta/udp_synta_mount.dart';
import 'package:dartstronomy_gear/src/mounts/synta/udp_synta_mount_detector.dart';
import 'package:dartstronomy_gear/src/network/lan.dart';
import 'package:dartstronomy_gear/src/network/one_shot_udp.dart';
import 'package:universal_io/io.dart';

export 'package:dartstronomy_gear/src/mounts/dartstronomy_mount.dart';
export 'package:dartstronomy_gear/src/mounts/movement.dart';

final class DartstronomyGear {
  DartstronomyGear._();

  /// The [Stream] returned emits a [DartstronomyMount] for every mount within
  /// reach.
  ///
  /// [searchTimeout] dictates how much to wait for an answer from a potential
  /// mount.
  static Stream<DartstronomyMount> getRealMounts(
    Duration searchTimeout,
  ) async* {
    const remotePorts = [11880];

    for (final lan in await Lan.ipv4LanCompositions) {
      final myAddress = lan.myAddress;

      for (final remoteAddress in lan.otherAddresses) {
        for (final remotePort in remotePorts) {
          final detector = UdpSyntaMountDetector(
            udp: OneShotUdp(
              myAddress: myAddress,
              remoteAddress: remoteAddress,
              remotePort: remotePort,
              timeout: searchTimeout,
            ),
          );

          final motorBoardVersion = await detector.motorBoardVersion;
          if (motorBoardVersion != null) {
            final socket = await RawDatagramSocket.bind(myAddress, 0);

            final connection = UdpConnection(
              socket: socket,
              remoteAddress: remoteAddress,
              remotePort: remotePort,
            );

            yield UdpSyntaMount(
              motorBoardVersion: motorBoardVersion,
              connection: connection,
            );
          }
        }
      }
    }
  }

  /// Returns a new simulated [DartstronomyMount].
  /// [reliability] will be clamped to be within [0, 1].
  /// Supply [seed] to insure reproducibility.
  static DartstronomyMount getAMountSimulator(double reliability, [int? seed]) {
    return MountSimulator(
      connection: ConnectionSimulator(reliability: reliability, seed: seed),
    );
  }
}
