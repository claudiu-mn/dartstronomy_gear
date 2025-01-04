import 'package:dartstronomy_gear/src/canceling/cancelation_token.dart';
import 'package:dartstronomy_gear/src/connection/udp_connection.dart';
import 'package:dartstronomy_gear/src/debug/debug.dart';
import 'package:dartstronomy_gear/src/mounts/dartstronomy_mount.dart';
import 'package:dartstronomy_gear/src/mounts/synta/udp_synta_mount.dart';
import 'package:dartstronomy_gear/src/mounts/synta/udp_synta_mount_detector.dart';
import 'package:dartstronomy_gear/src/network/network.dart';
import 'package:dartstronomy_gear/src/network/one_shot_udp.dart';
import 'package:dartstronomy_gear/src/search/mount_search.dart';
import 'package:universal_io/io.dart';

Future<Set<String>> getNamesOfSearchableNetworkInterfaces() async {
  final interfaces = await Network.supportedNetworkInterfaces;
  return interfaces.map((i) => i.name).toSet();
}

/// [targetNetworkInterfaceNames] should be a subset of the [Set] of [String]s
/// resolved by the [Future] returned from [getNamesOfSearchableNetworkInterfaces];
/// any others will be ignored.
MountSearch getMountSearch(
  Duration timeout,
  Set<String> targetNetworkInterfaceNames,
) {
  final token = CancelationToken();
  return (
    stream: _getMountStream(timeout, targetNetworkInterfaceNames, token),
    cancelable: token,
  );
}

Stream<DartstronomyMount> _getMountStream(
  Duration searchTimeout,
  Set<String> targetNetworkInterfaceNames,
  CancelationToken token,
) async* {
  const remotePorts = [11880];

  final interfaces = (await Network.supportedNetworkInterfaces).where(
    (i) => targetNetworkInterfaceNames.contains(i.name),
  );

  for (final interface in interfaces) {
    final compositions = Network.getIpV4SubnetComposition(interface);
    for (final composition in compositions) {
      final myAddress = composition.myAddress;

      for (final remoteAddress in composition.otherAddresses) {
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
}
