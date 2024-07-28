import 'package:dartstronomy_gear/src/skywatcher_open/string_utilities.dart';
import 'package:test/test.dart';

void main() {
  test('String.cSharpSubstring() works', () {
    var cases = [
      (i: 'dartlang', o: 'artlang', s: 1, l: null),
      (i: 'dartlang', o: 'artl', s: 1, l: 4),
    ];

    for (final c in cases) {
      expect(c.i.cSharpSubstring(c.s, c.l), equals(c.o));
    }
  });

  test('StringUtilities.tryParseBinaryCodedDecimalFromSyntaResponse() works',
      () {
    var cases = [
      (s: '=020782', i: 8521474),
      (s: 'w000000', i: 0),
      (s: '2FFfFFF', i: 16777215),
      (s: '8734fhu', i: null),
      (s: '', i: 0),
    ];

    for (final c in cases) {
      expect(
        StringUtilities.tryParseBinaryCodedDecimalFromSyntaResponse(c.s),
        equals(c.i),
      );
    }
  });
}
