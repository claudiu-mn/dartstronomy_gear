import 'package:dartstronomy_gear/src/skywatcher_open/int_utilities.dart';
import 'package:test/test.dart';

void main() {
  test('int.to24BitHexString() works', () {
    var cases = [
      (i: 31, s: '1F0000'),
      (i: -31, s: 'E1FFFF'),
      (i: 0, s: '000000'),
      (i: -0, s: '000000'),
      (i: 0xFFFFFF, s: 'FFFFFF'),
      (i: 0xFF0000, s: '0000FF'),
      (i: 0x00FF00, s: '00FF00'),
      (i: 0x0000FF, s: 'FF0000'),
      (i: 0xFFFFFFFFFFFF, s: 'FFFFFF'),
    ];

    for (final c in cases) {
      expect(c.i.to24BitHexString(), equals(c.s));
    }
  });
}
