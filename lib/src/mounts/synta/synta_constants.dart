import 'package:dartstronomy_gear/src/skywatcher_open/astronomy.dart';
import 'package:meta/meta.dart';

@immutable
final class SyntaConstants {
  SyntaConstants._();

  static const messageEndCharacter = '\r';

  static const maxMotorSpeed = 500.0;

  static const lowSpeedMargin = 128 * siderealRate;

  static const highSpeedMargin = 800 * siderealRate;
}
