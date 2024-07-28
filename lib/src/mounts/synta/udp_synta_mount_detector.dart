import 'dart:async';

import 'package:dartstronomy_gear/src/mounts/synta/synta_channel.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_command_header.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_request.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_response.dart';
import 'package:dartstronomy_gear/src/network/one_shot_udp.dart';
import 'package:dartstronomy_gear/src/skywatcher_open/string_utilities.dart';

final class UdpSyntaMountDetector {
  UdpSyntaMountDetector({required this.udp});

  final OneShotUdp udp;

  /// Returns a [Future] that completes with:
  /// - an [int] representing the motor board version of the mount
  /// - `null` if:
  ///   - not a Synta mount
  ///   - an error occurred
  ///   - operation timed out
  Future<int?> get motorBoardVersion async {
    try {
      final result = await udp.send(
        SyntaRequest(
          header: SyntaCommandHeader.inquireMotorBoardVersion,
          channel: SyntaChannel.one,
        ).objectForConnection,
      );

      if (result == null) return null;

      final response = SyntaResponse.fromBytes(result);

      if (response.type != SyntaResponseType.normal) return null;

      final bcd = StringUtilities.tryParseBinaryCodedDecimal(
        response.dataString,
      );

      if (bcd == null) return null;

      return ((bcd & 0x0000FF) << 16) |
          ((bcd & 0x00FF00)) |
          ((bcd & 0xFF0000) >> 16);
    } catch (_) {
      return null;
    }
  }
}
