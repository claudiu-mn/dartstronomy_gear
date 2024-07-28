import 'package:meta/meta.dart';

/// Use [toString] to get the command header character.
@immutable
final class SyntaCommandHeader {
  const SyntaCommandHeader._(this._);

  final String _;

  static const inquireMotorBoardVersion = SyntaCommandHeader._('e');
  static const inquireCountsPerRevolution = SyntaCommandHeader._('a');
  static const inquireTimerInterruptFrequency = SyntaCommandHeader._('b');
  static const inquireHighSpeedRatio = SyntaCommandHeader._('g');
  static const inquirePosition = SyntaCommandHeader._('j');
  static const inquireStatus = SyntaCommandHeader._('f');

  static const initializationDone = SyntaCommandHeader._('F');

  static const setMotionMode = SyntaCommandHeader._('G');
  static const startMotion = SyntaCommandHeader._('J');
  static const stopMotion = SyntaCommandHeader._('K');
  static const stopMotionInstantly = SyntaCommandHeader._('L');

  static const setPosition = SyntaCommandHeader._('E');
  static const setStepPeriod = SyntaCommandHeader._('I');

  @override
  String toString() => _;
}
