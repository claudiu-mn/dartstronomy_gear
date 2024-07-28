import 'dart:async';
import 'dart:typed_data';

import 'package:universal_io/io.dart';

enum SocketErrorType { bindFailure, generalFailure }

class SocketError extends Error {
  SocketError({required this.type});

  final SocketErrorType type;
}

final class OneShotUdp {
  OneShotUdp({
    required this.myAddress,
    required this.remoteAddress,
    required this.remotePort,
    required this.timeout,
  });

  final InternetAddress myAddress;
  final InternetAddress remoteAddress;
  final int remotePort;
  final Duration timeout;

  late final RawDatagramSocket _socket;
  late final List<int> _request;

  final _responseCompleter = Completer<Uint8List?>();
  final _timeoutCompleter = Completer<TimeoutException>();
  final _errorCompleter = Completer<SocketError>();

  /// Throws a [SocketError] if socket creation or operation fail somehow.
  /// Throws a [TimeoutException] if [timeout] was reached.
  Future<Uint8List?> send(List<int> message) async {
    _request = message;

    try {
      _socket = await RawDatagramSocket.bind(myAddress, 0);
    } catch (_) {
      throw SocketError(type: SocketErrorType.bindFailure);
    }

    _socket.listen(
      _onRawSocketEvent,
      onError: (_) => _errorCompleter.complete(
        SocketError(type: SocketErrorType.generalFailure),
      ),
    );

    final result = await Future.any<dynamic>(
      [
        _timeoutCompleter.future,
        _responseCompleter.future,
        _errorCompleter.future,
      ],
    );

    _socket.close();

    switch (result) {
      case SocketError e:
        throw e;

      case TimeoutException e:
        throw e;

      case Uint8List d:
        return d;

      case null:
      default:
        return null;
    }
  }

  /// We don't care about [RawSocketEvent.closed] and [RawSocketEvent.readClosed]
  /// will never be received, according to docs.
  void _onRawSocketEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.write) {
      _socket.send(_request, remoteAddress, remotePort);
      Timer(
        timeout,
        () => _timeoutCompleter.complete(TimeoutException('')),
      );
    } else if (event == RawSocketEvent.read) {
      _responseCompleter.complete(_socket.receive()?.data);
    }
  }
}
