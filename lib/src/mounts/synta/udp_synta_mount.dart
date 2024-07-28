import 'dart:math';
import 'dart:typed_data';

import 'package:dartstronomy_gear/src/connection/serial_connection.dart';
import 'package:dartstronomy_gear/src/mounts/dartstronomy_mount.dart';
import 'package:dartstronomy_gear/src/mounts/dartstronomy_mount_base.dart';
import 'package:dartstronomy_gear/src/mounts/movement.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_channel.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_command_header.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_constants.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_mount_model.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_mount_model_ints.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_request.dart';
import 'package:dartstronomy_gear/src/mounts/synta/synta_response.dart';
import 'package:dartstronomy_gear/src/mounts/synta/two_motors.dart';
import 'package:dartstronomy_gear/src/skywatcher_open/astronomy.dart';
import 'package:dartstronomy_gear/src/skywatcher_open/int_utilities.dart';
import 'package:dartstronomy_gear/src/skywatcher_open/string_utilities.dart';
import 'package:meta/meta.dart';

final class UdpSyntaMount extends DartstronomyMountBase<Uint8List, Uint8List>
    with DartstronomyMountExtras<Uint8List, Uint8List>
    implements DartstronomyMount {
  UdpSyntaMount({
    required super.connection,
    required int motorBoardVersion,
  }) : _motorBoardVersion = motorBoardVersion;

  final int _motorBoardVersion;

  final _motors = TwoMotors();

  var _wasSetUp = false;

  @override
  Future<void> setUp() async {
    if (_wasSetUp) return;

    final channel1 = SyntaChannel.one;
    final channel2 = SyntaChannel.two;

    final motor1Props = _motors.getProperties(SyntaChannel.one);
    final motor2Props = _motors.getProperties(SyntaChannel.two);

    try {
      // Inquire counts per revolution -----------------------------------------
      motor1Props.stepsPerRevolution = await _getStepsPerRevolutionForChannel(
        channel1,
      );
      motor2Props.stepsPerRevolution =
          await _getStepsPerRevolutionForChannel(channel2);

      // Inquire timer interrupt frequency -------------------------------------
      final frequencyHeader = SyntaCommandHeader.inquireTimerInterruptFrequency;
      motor1Props.timerInterruptFrequency = await _getIntValue(
        channel1,
        frequencyHeader,
      );
      motor2Props.timerInterruptFrequency = await _getIntValue(
        channel2,
        frequencyHeader,
      );

      // Inquire high speed ratio ----------------------------------------------
      final ratioHeader = SyntaCommandHeader.inquireHighSpeedRatio;
      motor1Props.highSpeedRatio = await _getIntValue(channel1, ratioHeader);
      motor2Props.highSpeedRatio = await _getIntValue(channel2, ratioHeader);

      // Inquire axis position -------------------------------------------------
      motor1Props.stepRotation = await _getCurrentSteps(channel1);
      motor2Props.stepRotation = await _getCurrentSteps(channel2);

      // Default break steps ---------------------------------------------------
      final defaultSteps = 3500;
      motor1Props.breakSteps = defaultSteps;
      motor2Props.breakSteps = defaultSteps;

      // Instant stopping ------------------------------------------------------
      final defaultStop = false;
      motor1Props.stopsInstantly = defaultStop;
      motor2Props.stopsInstantly = defaultStop;

      // Tell mount initialization is done -------------------------------------
      // TODO: Find out why we need to do this.
      final doneHeader = SyntaCommandHeader.initializationDone;
      await _getIntValue(channel1, doneHeader);
      await _getIntValue(channel2, doneHeader);

      // Release the hounds.
      _wasSetUp = true;
    } catch (_) {
      throw DartstronomyMountError(
        type: DartstronomyMountErrorType.setUpFailure,
      );
    }
  }

  @override
  String get name {
    final theInt = _modelInt;
    return _model?.productString ?? 'Synta(0x${theInt.toRadixString(16)})';
  }

  SyntaMountModel? get _model => _modelInt.toSyntaMountModel();

  int get _modelInt => _motorBoardVersion & 0xFF;

  @override
  Future<void> setMovement(Movement movement) async {
    _throwIfNotSetUp();

    // FIXME: Find out the maxSpeed value.

    // minSpeed <= maxSpeed
    const minSpeed = 0.0;
    // const maxSpeed = 0.05;
    // const maxSpeed = SyntaConstants.lowSpeedMargin;
    const maxSpeed = 800 * siderealRate;

    final speed = minSpeed + movement.speed * (maxSpeed - minSpeed);

    // print('trying speed: $speed');

    final direction = movement.direction;

    // x/azimuth/horizontal
    final channel1Speed = speed * cos(direction);
    // y/altitude/vertical
    final channel2Speed = speed * sin(direction);

    // Not guaranteed that the calls will succeed for both axes, so we randomize
    // which one goes first.
    final records = [
      (channel: SyntaChannel.one, speed: channel1Speed),
      (channel: SyntaChannel.two, speed: channel2Speed),
    ];
    records.shuffle();

    for (final r in records) {
      await _setSpeed(r.channel, r.speed);
    }

    print('got speeds: $channel1Speed x $channel2Speed');
  }

  /// Throws [DartstronomyMountError]
  Future<SyntaResponse> _getValidResponseOrThrow(SyntaRequest request) async {
    try {
      final response = SyntaResponse.fromBytes(await makeRequest(request));
      if (response.type == SyntaResponseType.unknown) {
        throw DartstronomyMountError(
          type: DartstronomyMountErrorType.malformedResponse,
          message: 'Response content: "${response.dataString}"',
        );
      }

      if (response.type == SyntaResponseType.error) {
        throw DartstronomyMountError(
          type: response.dataString.toMountExceptionType(),
        );
      }
      return response;
    } on SerialConnectionException catch (e) {
      throw e.toDartstronomyMountError();
    }
  }
}

extension _Helpers on UdpSyntaMount {
  void _throwIfNotSetUp() {
    if (!_wasSetUp) {
      throw DartstronomyMountError(
        type: DartstronomyMountErrorType.notSetUp,
        message: 'Forgot to call [DartstronomyMount.setUp]?',
      );
    }
  }
}

extension _SyntaCommands on UdpSyntaMount {
  Future<int> _getStepsPerRevolutionForChannel(SyntaChannel channel) async {
    var gearRatio = await _getIntValue(
      channel,
      SyntaCommandHeader.inquireCountsPerRevolution,
    );

    // There is a bug in the earlier version firmware(Before 2.00) of motor
    // controller MC001.
    // Overwrite the GearRatio reported by the MC for 80GT and 114GT mounts.
    if (_model == SyntaMountModel.celestronNexStar80Gt) {
      gearRatio = 0x162B97;
    } else if (_model == SyntaMountModel.celestronNexStar114Gt) {
      gearRatio = 0x205318;
    }

    return gearRatio;
  }

  Future<int> _getCurrentSteps(SyntaChannel channel) async {
    var steps = await _getIntValue(channel, SyntaCommandHeader.inquirePosition);
    steps -= 0x00800000;
    return steps;
  }

  Future<int> _getIntValue(SyntaChannel ch, SyntaCommandHeader header) async {
    final res = await _getValidResponseOrThrow(SyntaRequest(
      header: header,
      channel: ch,
    ));

    var integer = StringUtilities.tryParseBinaryCodedDecimal(res.dataString);

    if (integer == null) throw Error(); // TODO: Throw a more specific error.

    return integer;
  }

  Future<void> _setSpeed(SyntaChannel channel, double speed) async {
    const maxSpeed = SyntaConstants.maxMotorSpeed;

    // 3.4 degrees/sec, 800X sidereal rate, is the highest speed.
    speed = speed.clamp(-maxSpeed, maxSpeed);

    var internalSpeed = speed;
    var forward = false;
    var highSpeed = false;

    if (internalSpeed.abs() <= siderealRate / 1000) {
      final instantly = _motors.getProperties(channel).stopsInstantly;
      await _stop(channel, instantly);
      return;
    }

    await _prepareForSlewing(channel, internalSpeed);
    // await _prepareForFreeMovement(channel, internalSpeed);

    if (internalSpeed.isNegative) {
      internalSpeed *= -1;
      forward = false;
    } else {
      forward = true;
    }

    // TODO: ask the details

    final props = _motors.getProperties(channel);

    // Calculate and set step period.
    if (internalSpeed > SyntaConstants.lowSpeedMargin) {
      // High speed adjustment
      internalSpeed = internalSpeed / props.highSpeedRatio;
      highSpeed = true;
    }
    internalSpeed = 1 /
        internalSpeed; // For using function radSpeedToInt(), change to unit Senonds/Rad.
    var speedInt = props.radSpeedToInt(internalSpeed);
    if ((_motorBoardVersion == 0x010600) || (_motorBoardVersion == 0x010601)) {
      // For special MC version.
      speedInt -= 3;
    }
    if (speedInt < 6) speedInt = 6;
    await _setStepPeriod(channel, speedInt);

    // Start motion
    // if (axesStatus[Axis] & AXIS_FULL_STOPPED)				// It must be remove for the latest DC motor board.
    await _startMotion(channel);

    props.status.setSlewing(forward, highSpeed);
    props.currentSpeed = speed;
  }

  Future<void> _startMotion(SyntaChannel channel) async {
    await _getValidResponseOrThrow(SyntaRequest(
      header: SyntaCommandHeader.startMotion,
      channel: channel,
    ));
  }

  Future<void> _setStepPeriod(SyntaChannel channel, int stepsCount) async {
    final codeUnits = stepsCount.to24BitHexString().codeUnits;
    await _getValidResponseOrThrow(SyntaRequest(
      header: SyntaCommandHeader.setStepPeriod,
      channel: channel,
      data: Uint8List.fromList(codeUnits),
    ));
  }

  Future<void> _stop(SyntaChannel channel, bool instantly) async {
    await _getValidResponseOrThrow(SyntaRequest(
      header: instantly
          ? SyntaCommandHeader.stopMotionInstantly
          : SyntaCommandHeader.stopMotion,
      channel: channel,
    ));

    _motors.getProperties(channel).status.setFullStop();
  }

  Future<void> _prepareForFreeMovement(
    SyntaChannel channel,
    double speed,
  ) async {
    var sts = await _getMotorStatus(channel);

    var shouldStop = false;
    var shouldConfigureMotion = false;

    final absoluteSpeed = speed.abs();
    final wantsHighSpeed = absoluteSpeed >= SyntaConstants.lowSpeedMargin;
    final isHighSpeed = sts.highSpeed;
    if (wantsHighSpeed != isHighSpeed) {
      shouldStop |= true;
      shouldConfigureMotion |= true;
    }

    final wantsForward = speed > 0;
    final isForward = sts.slewingForward;
    if (wantsForward != isForward) {
      shouldStop |= true;
      shouldConfigureMotion |= true;
    }

    final p = _motors.getProperties(channel);

    if (shouldStop) await _stop(channel, p.stopsInstantly);

    while (true) {
      sts = await _getMotorStatus(channel);
      p.status.copyFrom(sts);

      if (sts.fullStop) break;

      await Future<void>.delayed(Duration(milliseconds: 100));
    }

    if (absoluteSpeed == 0) return;

    if (!shouldConfigureMotion) return;

    await _configureMotion(
      channel,
      _MotionConfiguration(
        mode: _MotionMode.free,
        speed: wantsHighSpeed ? _MotionSpeed.fast : _MotionSpeed.slow,
      ),
      wantsForward
          ? _MotionDirection.clocwise
          : _MotionDirection.counterClockwise,
    );
  }

  Future<void> _prepareForSlewing(SyntaChannel channel, double speed) async {
    final p = _motors.getProperties(channel);

    var sts = await _getMotorStatus(channel);
    p.status.copyFrom(sts);

    if (!sts.fullStop) {
      if ((sts.slewingTo) || // GOTO in action
              (sts.highSpeed) || // Currently high speed slewing
              (speed.abs() >=
                  SyntaConstants
                      .lowSpeedMargin) || // Will be high speed slewing
              (sts.slewingForward && speed < 0) || // Different direction
              (!sts.slewingForward && speed > 0) // Different direction
          ) {
        // We need to stop the motor first to change Motion Mode, etc.
        await _stop(channel, p.stopsInstantly);
      } else {
        // Other situatuion, there is no need to set motion mode.
        return;
      }

      // Wait until the axis stop
      while (true) {
        // Update Mount status, the status of both axes are also updated because _GetMountStatus() includes such operations.
        sts = await _getMotorStatus(channel);
        p.status.copyFrom(sts);

        // Return if the axis has stopped.
        if (sts.fullStop) break;

        await Future<void>.delayed(Duration(milliseconds: 100));

        // If the axis is asked to stop.
        // if ( (!AxesAskedToRun[Axis] && !(MountStatus & MOUNT_TRACKING_ON)) )		// If axis1 or axis2 is asked to stop or
        //	return ERR_USER_INTERRUPT;
      }
    }

    String dir;

    if (speed.isNegative) {
      dir = '1';
      speed *= -1; // Get absolute value of Speed.
    } else {
      dir = '0';
    }

    if (speed > SyntaConstants.lowSpeedMargin) {
      await _setMotionMode(channel, '3', dir); // Set HIGH speed slewing mode.
    } else {
      await _setMotionMode(channel, '1', dir); // Set LOW speed slewing mode.
    }
  }

  Future<void> _configureMotion(
    SyntaChannel channel,
    _MotionConfiguration configuration,
    _MotionDirection direction,
  ) async {
    final configByte = '${configuration.toBitMask()}';
    final dirByte = '${direction.toInt()}';
    await _getValidResponseOrThrow(SyntaRequest(
      header: SyntaCommandHeader.setMotionMode,
      channel: channel,
      data: Uint8List.fromList('$configByte$dirByte'.codeUnits),
    ));
  }

  @Deprecated("Use '_configureMotion' instead")
  Future<void> _setMotionMode(
    SyntaChannel channel,
    String func,
    String direction,
  ) async {
    await _getValidResponseOrThrow(SyntaRequest(
      header: SyntaCommandHeader.setMotionMode,
      channel: channel,
      data: Uint8List.fromList('$func$direction'.codeUnits),
    ));
  }

  // FIXME: Add tests?
  Future<MotorStatus> _getMotorStatus(SyntaChannel channel) async {
    final motorStatus = MotorStatus.defaults();

    final synRes = await _getValidResponseOrThrow(SyntaRequest(
      header: SyntaCommandHeader.inquireStatus,
      channel: channel,
    ));

    final response = synRes.dataString;

    if ((response.codeUnitAt(1) & 0x01) != 0) {
      // Axis is running
      if ((response.codeUnitAt(0) & 0x01) != 0) {
        // Axis in slewing(AstroMisc speed) mode.
        motorStatus.slewing = true;
        motorStatus.slewingTo = false;
      } else {
        // Axis in SlewingTo mode.
        motorStatus.slewing = false;
        motorStatus.slewingTo = true;
      }
      motorStatus.fullStop = false;
    } else {
      motorStatus.slewing = false;
      motorStatus.slewingTo = false;
      motorStatus.fullStop = true; // FullStop = 1;	// Axis is fully stop.
    }

    if ((response.codeUnitAt(0) & 0x02) == 0) {
      motorStatus.slewingForward = true; // Angle increase = 1;
    } else {
      motorStatus.slewingForward = false;
    }

    if ((response.codeUnitAt(0) & 0x04) != 0) {
      motorStatus.highSpeed = true; // HighSpeed running mode = 1;
    } else {
      motorStatus.highSpeed = false;
    }

    if ((response.codeUnitAt(2) & 1) == 0) {
      motorStatus.notInitialized = true; // MC is not initialized.
    } else {
      motorStatus.notInitialized = false;
    }

    return motorStatus;
  }
}

// PODOs -----------------------------------------------------------------------

@immutable
final class _MotionConfiguration {
  const _MotionConfiguration({required this.mode, required this.speed});

  final _MotionMode mode;
  final _MotionSpeed speed;
}

enum _MotionMode {
  /// AKA tracking
  free,
  goTo
}

enum _MotionSpeed { slow, fast }

enum _MotionDirection { clocwise, counterClockwise }

// Conversions -----------------------------------------------------------------

extension _BitMask on _MotionConfiguration {
  int toBitMask() {
    final bits = switch ((mode, speed)) {
      (_MotionMode.free, _MotionSpeed.slow) => [1, 0],
      (_MotionMode.free, _MotionSpeed.fast) => [1, 1],
      // ----------------------------------------------------------
      (_MotionMode.goTo, _MotionSpeed.slow) => [0, 1],
      (_MotionMode.goTo, _MotionSpeed.fast) => [0, 0],
    };

    var mask = 0;
    for (var i = 0; i < bits.length; i++) {
      mask |= bits[i] << i;
    }

    return mask;
  }
}

extension _Ints on _MotionDirection {
  int toInt() => switch (this) {
        _MotionDirection.clocwise => 0,
        _MotionDirection.counterClockwise => 1,
      };
}

extension _SyntaMountModelStrings on SyntaMountModel {
  String get productString => switch (this) {
        SyntaMountModel.skyWatcherEq6 => 'Sky-Watcher EQ6',
        SyntaMountModel.skyWatcherHeq5 => 'Sky-Watcher HEQ5',
        SyntaMountModel.skyWatcherEq5 => 'Sky-Watcher EQ5',
        SyntaMountModel.skyWatcherEq3 => 'Sky-Watcher EQ3',
        SyntaMountModel.celestronNexStar80Gt => 'Celestron NexStar 80 GT',
        SyntaMountModel.mF => 'MF',
        SyntaMountModel.celestronNexStar114Gt => 'Celestron NexStar 114 GT',
        SyntaMountModel.dob => 'DOB',
        SyntaMountModel.skyWatcherAzGtI => 'Sky-Watcher AZ-GTi',
      };
}

extension _SyntaErrorCodeStrings on String {
  DartstronomyMountErrorType toMountExceptionType() => switch (this) {
        '0' => DartstronomyMountErrorType.unknownCommand,
        '1' => DartstronomyMountErrorType.commandLength,
        '2' => DartstronomyMountErrorType.motorNotStopped,
        '3' => DartstronomyMountErrorType.invalidCharacter,
        '4' => DartstronomyMountErrorType.notInitialized,
        '5' => DartstronomyMountErrorType.driverSleeping,
        '7' => DartstronomyMountErrorType.pecTrainingRunning,
        '8' => DartstronomyMountErrorType.noValidPecData,
        _ => DartstronomyMountErrorType.unknown,
      };
}

extension _DartstronomyMountErrors on SerialConnectionException {
  DartstronomyMountError toDartstronomyMountError() {
    switch (type) {
      case SerialConnectionExceptionType.emptyResponse:
        return DartstronomyMountError(
          type: DartstronomyMountErrorType.malformedResponse,
          message: 'Empty response',
        );

      case SerialConnectionExceptionType.anotherRequestInProgress:
        return DartstronomyMountError(
          type: DartstronomyMountErrorType.anotherRequestInProgress,
        );

      case SerialConnectionExceptionType.timedOut:
        return DartstronomyMountError(
          type: DartstronomyMountErrorType.timedOut,
        );

      case SerialConnectionExceptionType.unknown:
        return DartstronomyMountError(
          type: DartstronomyMountErrorType.unknown,
        );
    }
  }
}
