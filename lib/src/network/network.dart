import 'package:dartstronomy_gear/src/debug/debug.dart';
import 'package:meta/meta.dart';
import 'package:universal_io/io.dart';

@immutable
final class Network {
  Network._();

  static Future<Set<NetworkInterface>> get supportedNetworkInterfaces async {
    final list = await NetworkInterface.list(type: InternetAddressType.IPv4);
    return list.toSet();
  }

  static List<IpV4SubnetComposition> getIpV4SubnetComposition(
    NetworkInterface interface,
  ) {
    final compositions = <IpV4SubnetComposition>[];

    for (final address in interface.addresses) {
      debugPrint('Got ${address.address} on ${interface.name}');

      final myIp = address.address;

      final lastDotIndex = myIp.lastIndexOf('.');

      final subnet = myIp.substring(0, lastDotIndex);

      final myHostNumber = int.parse(myIp.substring(lastDotIndex + 1));

      final myAddress = address;
      final otherAddresses = <InternetAddress>[];

      // Skip 2 IPs:
      //  - ###.###.###.0 because it's the network address
      //  - ###.###.###.255 because it's the broadcast address
      for (var i = 1; i < 255; i++) {
        if (i == myHostNumber) continue;

        otherAddresses.add(InternetAddress('$subnet.$i', type: address.type));
      }

      compositions.add(IpV4SubnetComposition(
        myAddress: myAddress,
        otherAddresses: otherAddresses,
      ));
    }

    return compositions;
  }
}

@immutable
final class IpV4SubnetComposition {
  IpV4SubnetComposition({
    required this.myAddress,
    required this.otherAddresses,
  });

  final InternetAddress myAddress;
  final List<InternetAddress> otherAddresses;
}
