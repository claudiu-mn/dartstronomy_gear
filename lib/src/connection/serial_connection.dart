import 'dart:async';

import 'package:dartstronomy_gear/src/another_timer.dart';
import 'package:meta/meta.dart';

enum SerialConnectionExceptionType {
  anotherRequestInProgress,
  timedOut,
  emptyResponse,
  unknown,
}

class SerialConnectionException implements Exception {
  SerialConnectionException({required this.type, this.message});

  final SerialConnectionExceptionType type;
  final String? message;

  @override
  String toString() {
    final msgPart = message == null ? '' : ': $message';
    return '$runtimeType(${type.name})$msgPart';
  }
}

abstract interface class SerialConnection<I, O> {
  /// Returns `null` if the [SerialConnection] is idle.
  Duration? get timeUntilTimeout;

  /// Throws [SerialConnectionException].
  Future<O> send(I data, Duration timeout);
}

mixin SerialConnectionBase<I, O> implements SerialConnection<I, O> {
  AnotherTimer? _timer;

  Completer<O?>? _responseCompleter;
  Completer<SerialConnectionException>? _timeoutCompleter;
  Completer<SerialConnectionException>? _errorCompleter;

  @override
  Duration? get timeUntilTimeout => _timer?.remaining;

  @protected
  void onTimeToSend(I data, Duration timeout);

  @override
  Future<O> send(I data, Duration timeout) async {
    if (_timer != null) {
      throw SerialConnectionException(
        type: SerialConnectionExceptionType.anotherRequestInProgress,
      );
    }

    _responseCompleter = Completer();
    _timeoutCompleter = Completer();
    _errorCompleter = Completer();

    _timer = AnotherTimer(
      timeout,
      () => _timeoutCompleter?.complete(
        SerialConnectionException(type: SerialConnectionExceptionType.timedOut),
      ),
    );

    onTimeToSend(data, timeout);

    final result = await Future.any<dynamic>(
      [
        _timeoutCompleter!.future,
        _responseCompleter!.future,
        _errorCompleter!.future,
      ],
    );

    _timer?.cancel();
    _timer = null;
    _responseCompleter = null;
    _timeoutCompleter = null;
    _errorCompleter = null;

    switch (result) {
      case SerialConnectionException e:
        throw e;

      case O d:
        return d;

      case null:
        throw SerialConnectionException(
          type: SerialConnectionExceptionType.emptyResponse,
        );

      default:
        throw SerialConnectionException(
          type: SerialConnectionExceptionType.unknown,
        );
    }
  }

  @protected
  void completeWithException(SerialConnectionException exception) {
    _errorCompleter?.complete(exception);
  }

  @protected
  void completeNormally(O? data) => _responseCompleter?.complete(data);
}
