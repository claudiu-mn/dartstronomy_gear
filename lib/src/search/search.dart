import 'package:dartstronomy_gear/src/canceling/cancelation_token.dart';
import 'package:dartstronomy_gear/src/connection/udp_connection.dart';
import 'package:dartstronomy_gear/src/debug/debug.dart';
import 'package:dartstronomy_gear/src/mounts/dartstronomy_mount.dart';
import 'package:dartstronomy_gear/src/mounts/synta/udp_synta_mount.dart';
import 'package:dartstronomy_gear/src/mounts/synta/udp_synta_mount_detector.dart';
import 'package:dartstronomy_gear/src/network/lan.dart';
import 'package:dartstronomy_gear/src/network/one_shot_udp.dart';
import 'package:dartstronomy_gear/src/search/mount_search.dart';
import 'package:universal_io/io.dart';

MountSearch getMountSearch(Duration searchTimeout) {
  final token = CancelationToken();
  return (
    stream: _getMountStream(searchTimeout, token),
    cancelable: token,
  );
}

Stream<DartstronomyMount> _getMountStream(
  Duration searchTimeout,
  CancelationToken token,
) async* {
  const remotePorts = [11880];

  for (final lan in await Lan.ipv4LanCompositions) {
    final myAddress = lan.myAddress;

    for (final remoteAddress in lan.otherAddresses) {
      for (final remotePort in remotePorts) {
        if (token.isCanceled) return;

        final detector = UdpSyntaMountDetector(
          udp: OneShotUdp(
            myAddress: myAddress,
            remoteAddress: remoteAddress,
            remotePort: remotePort,
            timeout: searchTimeout,
          ),
        );

        debugPrint(
          'Checking potential motor board version at ${remoteAddress.host}:$remotePort',
        );
        final motorBoardVersion = await detector.motorBoardVersion;

        if (token.isCanceled) return;

        if (motorBoardVersion != null) {
          final socket = await RawDatagramSocket.bind(myAddress, 0);

          if (token.isCanceled) {
            socket.close();
            return;
          }

          final connection = UdpConnection(
            socket: socket,
            remoteAddress: remoteAddress,
            remotePort: remotePort,
          );

          if (token.isCanceled) {
            socket.close();
            return;
          }

          yield UdpSyntaMount(
            motorBoardVersion: motorBoardVersion,
            connection: connection,
          );
        }
      }
    }
  }
}
