import 'dart:math';

import 'package:dartstronomy_gear/src/mounts/synta/synta_channel.dart';
import 'package:dartstronomy_gear/src/skywatcher_open/astronomy.dart';
import 'package:meta/meta.dart';

@immutable
class TwoMotors {
  TwoMotors();

  final _channels = <SyntaChannel, MotorProperties>{
    SyntaChannel.one: MotorProperties(),
    SyntaChannel.two: MotorProperties(),
  };

  MotorProperties getProperties(SyntaChannel channel) => _channels[channel]!;
}

class MotorProperties {
  // Constants -----------------------------------------------------------------

  /// The number of steps it takes for the motor to complete one revolution.
  var stepsPerRevolution = 0;

  var highSpeedRatio = 0;

  /// Break steps from slewing to stop.
  var breakSteps = 0;

  // Not sure if constants -----------------------------------------------------

  var timerInterruptFrequency = 0;

  // Definitely not constants --------------------------------------------------

  /// Current rotation in number of steps.
  var stepRotation = 0;

  var stopsInstantly = false;

  final status = MotorStatus.defaults();

  var currentSpeed = 0.0;

  // Utilities -----------------------------------------------------------------

  /// Multiplier to convert from radians to motor steps.
  double get radToStepRatio => stepsPerRevolution / (2 * pi);

  /// Multiplier to convert from motor steps to radians.
  double get stepToRadRatio => 2 * pi / stepsPerRevolution;

  /// Not sure, but I think this determines speed when moving freely.
  double get radRateToIntRatio => timerInterruptFrequency / radToStepRatio;

  /// This is the current rotation in radians.
  double get radRotation => stepRotation * stepToRadRatio;

  /// If slewing steps exceed this value, GoTo is in high speed slewing mode.
  int get lowSpeedGoToMargin {
    // This is calculated from slewing for 5 seconds in 128x sidereal rate.
    return (640 * siderealRate * radToStepRatio).toInt();
  }

  int radSpeedToInt(double rateInRad) {
    return (rateInRad * radRateToIntRatio).toInt();
  }
}

class MotorStatus {
  MotorStatus._({
    required this.fullStop,
    required this.slewing,
    required this.slewingTo,
    required this.slewingForward,
    required this.highSpeed,
    required this.notInitialized,
  });

  factory MotorStatus.defaults() {
    return MotorStatus._(
      fullStop: false,
      notInitialized: true,
      highSpeed: false,
      slewing: false,
      slewingForward: false,
      slewingTo: false,
    );
  }

  bool fullStop;
  bool slewing;
  bool slewingTo;
  bool slewingForward;
  bool highSpeed;
  bool notInitialized;

  void setFullStop() {
    fullStop = true;
    slewingTo = slewing = false;
  }

  void setSlewing(bool forward, bool highspeed) {
    fullStop = slewingTo = false;
    slewing = true;

    slewingForward = forward;
    highSpeed = highspeed;
  }

  void setSlewingTo(bool forward, bool highspeed) {
    fullStop = slewing = false;
    slewingTo = true;

    slewingForward = forward;
    highSpeed = highspeed;
  }

  /// Copies all properties from [other].
  void copyFrom(MotorStatus other) {
    fullStop = other.fullStop;
    slewing = other.slewing;
    slewingTo = other.slewingTo;
    slewingForward = other.slewingForward;
    highSpeed = other.highSpeed;
    notInitialized = other.notInitialized;
  }

  @override
  String toString() => '$runtimeType(\n'
      'fullStop: $fullStop,\n'
      'slewing: $slewing,\n'
      'slewingTo: $slewingTo,\n'
      'slewingForward: $slewingForward,\n'
      'highSpeed: $highSpeed,\n'
      'notInitialized: $notInitialized,\n'
      ')';

  //// Mask for axis status
  //public const long AXIS_FULL_STOPPED = 0x0001;		// 該軸處於完全停止狀態
  //public const long AXIS_SLEWING = 0x0002;			// 該軸處於恒速運行狀態
  //public const long AXIS_SLEWING_TO = 0x0004;		    // 該軸處於運行到指定目標位置的過程中
  //public const long AXIS_SLEWING_FORWARD = 0x0008;	// 該軸正向運轉
  //public const long AXIS_SLEWING_HIGHSPEED = 0x0010;	// 該軸處於高速運行狀態
  //public const long AXIS_NOT_INITIALIZED = 0x0020;    // MC控制器尚未初始化, axis is not initialized.
}
