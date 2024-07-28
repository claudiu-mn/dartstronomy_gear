import 'package:meta/meta.dart';
import 'package:universal_io/io.dart';

@immutable
final class Lan {
  Lan._();

  // FIXME: Assumes we're working with class C networks
  static Future<List<LanComposition>> get ipv4LanCompositions async {
    final type = InternetAddressType.IPv4;

    final lanCompositions = <LanComposition>[];

    for (final interface in await NetworkInterface.list()) {
      for (final address in interface.addresses) {
        if (address.type == type) {
          final myIp = address.address;

          final lastDotIndex = myIp.lastIndexOf('.');

          final subnet = myIp.substring(0, lastDotIndex);

          final myHostNumber = int.parse(myIp.substring(lastDotIndex + 1));

          final myAddress = address;
          final otherAddresses = <InternetAddress>[];

          for (var i = 0; i < 256; i++) {
            if (i == myHostNumber) continue;

            final ip = '$subnet.$i';

            otherAddresses.add(InternetAddress(ip, type: type));
          }

          lanCompositions.add(LanComposition(
            myAddress: myAddress,
            otherAddresses: otherAddresses,
          ));
        }
      }
    }

    return lanCompositions;
  }
}

@immutable
final class LanComposition {
  LanComposition({required this.myAddress, required this.otherAddresses});

  final InternetAddress myAddress;
  final List<InternetAddress> otherAddresses;
}
