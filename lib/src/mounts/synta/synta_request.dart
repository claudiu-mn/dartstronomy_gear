import 'dart:typed_data';

import 'package:dartstronomy_gear/src/mounts/mount_request.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_channel.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_command_header.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_constants.dart';
import 'package:meta/meta.dart';

/// Use [toString] to get the Synta protocol request string.
@immutable
final class SyntaRequest implements MountRequest<Uint8List> {
  SyntaRequest({required this.header, required this.channel, this.data});

  final SyntaCommandHeader header;
  final SyntaChannel channel;
  final Uint8List? data;

  // TODO: Should we make sure to use ASCII? Mount will probably complain, so
  //       not that sure we need to here.
  @override
  String toString() {
    var requestString = ':';
    requestString += '$header';
    requestString += '$channel';
    requestString += String.fromCharCodes(data ?? Uint8List(0));
    requestString += SyntaConstants.messageEndCharacter;

    return requestString;
  }

  @override
  Uint8List get objectForConnection => Uint8List.fromList(toString().codeUnits);
}
