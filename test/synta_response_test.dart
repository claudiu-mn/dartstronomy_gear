import 'dart:typed_data';

import 'package:dartstronomy_gear/src/mounts/synta/synta_response.dart';
import 'package:test/test.dart';

void main() {
  test('SyntaResponse.fromBytes() works', () {
    var cases = [
      (cmdStr: '=\r', type: SyntaResponseType.normal, dataStr: ''),
      (cmdStr: '=.\r', type: SyntaResponseType.normal, dataStr: '.'),
      (cmdStr: '', type: SyntaResponseType.unknown, dataStr: ''),
      (cmdStr: '!', type: SyntaResponseType.unknown, dataStr: '!'),
      (cmdStr: '!0', type: SyntaResponseType.unknown, dataStr: '!0'),
      (cmdStr: '!\r', type: SyntaResponseType.error, dataStr: ''),
      (cmdStr: '!Fé\r', type: SyntaResponseType.unknown, dataStr: '!Fé\r'),
      (cmdStr: '!Fe\r', type: SyntaResponseType.error, dataStr: 'Fe'),
      (cmdStr: '\r', type: SyntaResponseType.unknown, dataStr: '\r'),
    ];

    for (final c in cases) {
      expect(
        SyntaResponse.fromBytes(Uint8List.fromList(c.cmdStr.codeUnits)),
        equals(SyntaResponse(
          type: c.type,
          data: Uint8List.fromList(c.dataStr.codeUnits),
        )),
      );
    }
  });
}
