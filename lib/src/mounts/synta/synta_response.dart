import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_constants.dart';
import 'package:meta/meta.dart';

enum SyntaResponseType { error, normal, unknown }

@immutable
final class SyntaResponse {
  const SyntaResponse({required this.type, required this.data});

  factory SyntaResponse.fromBytes(Uint8List bytes) {
    try {
      final asciiString = ascii.decode(bytes, allowInvalid: false);

      if (asciiString.length < 2) {
        return SyntaResponse(type: SyntaResponseType.unknown, data: bytes);
      }

      final headerString = asciiString[0];

      final type = switch (headerString) {
        '=' => SyntaResponseType.normal,
        '!' => SyntaResponseType.error,
        _ => SyntaResponseType.unknown,
      };

      if (type == SyntaResponseType.unknown) {
        return SyntaResponse(type: type, data: bytes);
      }

      final footerString = asciiString[asciiString.length - 1];
      if (footerString != SyntaConstants.messageEndCharacter) {
        return SyntaResponse(type: SyntaResponseType.unknown, data: bytes);
      }

      return SyntaResponse(
        type: type,
        data: bytes.sublist(1, bytes.length - 1),
      );
    } catch (_) {
      return SyntaResponse(type: SyntaResponseType.unknown, data: bytes);
    }
  }

  final SyntaResponseType type;
  final Uint8List data;

  String get dataString => String.fromCharCodes(data);

  @override
  bool operator ==(covariant SyntaResponse other) {
    if (identical(this, other)) return true;

    if (type != other.type) return false;
    if (!ListEquality<int>().equals(data.toList(), other.data.toList())) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => ListEquality<dynamic>().hash([type, data]);

  @override
  String toString() {
    return '$runtimeType(${type.name}\ncontent: "${String.fromCharCodes(data)}"\n)';
  }
}
