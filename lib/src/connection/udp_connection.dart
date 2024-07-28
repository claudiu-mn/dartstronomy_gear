import 'dart:typed_data';

import 'package:dartstronomy_gear/src/connection/serial_connection.dart';
import 'package:meta/meta.dart';
import 'package:universal_io/io.dart';

final class UdpConnection with SerialConnectionBase<Uint8List, Uint8List> {
  UdpConnection({
    required RawDatagramSocket socket,
    required this.remoteAddress,
    required this.remotePort,
  }) : _socket = socket {
    _socket.listen(_onRawSocketEvent, onError: _onStreamError);
  }

  final InternetAddress remoteAddress;
  final int remotePort;

  final RawDatagramSocket _socket;

  void _onRawSocketEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      completeNormally(_socket.receive()?.data);
    } else if (event == RawSocketEvent.closed) {
      // FIXME: What do we do here?
    }
  }

  void _onStreamError(Object error) => completeWithException(
        SerialConnectionException(type: SerialConnectionExceptionType.unknown),
      );

  @override
  @protected
  void onTimeToSend(Uint8List data, Duration timeout) {
    _socket.send(data, remoteAddress, remotePort);
  }
}
