import 'dart:async';
import 'dart:math';

import 'package:dartstronomy_gear/src/skywatcher_open/astro_type_def.dart';
import 'package:dartstronomy_gear/src/skywatcher_open/astronomy.dart';
import 'package:dartstronomy_gear/src/skywatcher_open/int_utilities.dart';
// import 'package:dartstronomy_gear/src/connection/bit_rates.dart';
import 'package:dartstronomy_gear/src/skywatcher_open/mount.dart';
import 'package:dartstronomy_gear/src/skywatcher_open/string_utilities.dart';
// import 'package:dartstronomy_gear/src/serial_connection.dart';
import 'package:dartstronomy_gear/src/skywatcher_open/utf_16_char.dart';
import 'package:meta/meta.dart';

/// TODO: PrepareForGoto Should move to mount control
/// Checked 2/8/2011

class MountSkywatcher extends Mount {
  static const maxSpeed = 500.0; //?
  static const lowSpeedMargin = 128 * siderealRate;

  var _dir = Utf16Char.fromString('0'); // direction

  // Mount code: 0x00=EQ6, 0x01=HEQ5, 0x02=EQ5, 0x03=EQ3
  //             0x80=GT,  0x81=MF,   0x82=114GT
  //             0x90=DOB
  late int mountCode;

  final _stepTimerFreq = <int>[]; // Frequency of stepping timer.

  final _peSteps = <int>[];

  final _highSpeedRatio = <int>[];

  //private long[] StepPosition = new long[2];          // Never Used

  final _breakSteps = <int>[]; // Break steps from slewing to stop.

  final _lowSpeedGotoMargin =
      <int>[]; // If slewing steps exceeds this _lowSpeedGotoMargin,
  // GOTO is in high speed slewing.

  late bool
      _isDcMotor; // True: The motor controller is a DC motor controller. It uses TX/RX line is bus topology.
  // False: The motor controller is a stepper motor controller. TX/RX lines are seperated.

  final _instantStop = false; // Use _instantStop command for mcAxisStop

  // FIXME: Implement [MountSkywatcher.connectCom]!
  @override
  void connectCom(int telescopePort) {
    throw UnimplementedError("Implement [MountSkywatcher.connectCom]!");

    // super.connectCom(telescopePort);
    // (mConnection as ComConnection?)?.hCom.BaudRate = BitRates.constant9600;
    // (mConnection as ComConnection?)?.hCom.Encoding = Encoding.ASCII;
  }

  @protected
  @override
  void sendRequest(Axis axis, Utf16Char command, String? cmdDataStr) {
    cmdDataStr ??= "";

    var commandString = "";
    commandString += _Constants.cStartCharOut.toString(); // 0: Leading char
    commandString += command
        .toString(); // 1: Length of command( Source, distination, command char, data )
    // Target Device
    commandString += axis == Axis.axis1 ? "1" : "2"; // 2: Target Axis
    // Copy command data to buffer
    commandString += cmdDataStr;
    commandString += _Constants.cEndChar.toString(); // CR Character

    mConnection!.write(commandString);
  }

  @protected
  @override
  Future<String> receiveResponse() async {
    // Receive Response
    // format "::e1\r=020883\r"

    final start = DateTime.now();

    var mBuffer = "";

    var startReading = false;
    var endReading = false;

    // var index = 0;
    while (!endReading) {
      // index++;

      final now = DateTime.now();

      final elapsed = now.difference(start);

      // Checks if one second has passed
      if (elapsed.inMicroseconds > 1000000) {
        //Trace.TraceError("Timeout {0} / {1}", mConnection.mBuffer, mBuffer);
        throw TimeoutException("");
      }

      var r = mConnection!.read();

      for (var i = 0; i < r.length; i++) {
        // this code order is important
        if (r[i] == _Constants.cStartCharIn.toString() ||
            r[i] == _Constants.cErrChar.toString()) {
          startReading = true;
        }

        if (startReading) mBuffer += r[i];

        if (r[i] == _Constants.cEndChar.toString()) {
          if (startReading) {
            endReading = true;
            break;
          }
        }
      }

      await Future<void>.delayed(Duration(milliseconds: 1));
    }

    //Trace.TraceInformation("Loop :" + index.ToString() + "Ticks :" + interval);
    return mBuffer;
  }

  @override
  Future<void> mcInit() async {
    _isDcMotor = _checkIfDcMotor();
    try {
      inquireMotorBoardVersion(Axis.axis1);
    } catch (_, __) {
      // try again
      await Future<void>.delayed(Duration(milliseconds: 200));
      inquireMotorBoardVersion(Axis.axis1);
    }

    mountCode = mcVersion & 0xFF;

    //// NOTE: Simulator settings, Mount dependent Settings

    // Inquire Gear Rate
    inquireGridPerRevolution(Axis.axis1);
    inquireGridPerRevolution(Axis.axis2);

    // Inquire motor timer interrup frequency
    inquireTimerInterruptFreq(Axis.axis1);
    inquireTimerInterruptFreq(Axis.axis2);

    // Inquire motor high speed ratio
    inquireHighSpeedRatio(Axis.axis1);
    inquireHighSpeedRatio(Axis.axis2);

    // Inquire PEC period
    // DC motor controller does not support PEC
    if (!_isDcMotor) {
      //inquirePECPeriod(Axis.axis1);
      //inquirePECPeriod(Axis.axis2);
    }

    // Inquire Axis Position
    positions[Axis.axis1.index] = mcGetAxisPosition(Axis.axis1);
    positions[Axis.axis2.index] = mcGetAxisPosition(Axis.axis2);

    initializeMC();

    // These two _lowSpeedGotoMargin are calculate from slewing for 5 seconds in 128x sidereal rate
    _lowSpeedGotoMargin[Axis.axis1.index] =
        (640 * siderealRate * factorRadToStep[Axis.axis1.index]) as int;
    _lowSpeedGotoMargin[Axis.axis2.index] =
        (640 * siderealRate * factorRadToStep[Axis.axis2.index]) as int;

    // Default break steps
    _breakSteps[Axis.axis1.index] = 3500;
    _breakSteps[Axis.axis2.index] = 3500;
  }

  @override
  void mcAxisSlew(Axis axis, double speed) {
    // Limit maximum speed
    if (speed > maxSpeed) {
      // 3.4 degrees/sec, 800X sidereal rate, is the highest speed.
      speed = maxSpeed;
    } else if (speed < -maxSpeed) {
      speed = -maxSpeed;
    }

    var internalSpeed = speed;
    var forward = false;
    var highspeed = false;

    // InternalSpeed lower than 1/1000 of sidereal rate?
    if (internalSpeed.abs() <= siderealRate / 1000.0) {
      mcAxisStop(axis);
      return;
    }

    // Stop motor and set motion mode if necessary.
    _prepareForSlewing(axis, internalSpeed);

    if (internalSpeed > 0.0) {
      forward = true;
    } else {
      internalSpeed = -internalSpeed;
      forward = false;
    }

    // TODO: ask the details

    // Calculate and set step period.
    if (internalSpeed > lowSpeedMargin) {
      // High speed adjustment
      internalSpeed = internalSpeed / (_highSpeedRatio[axis.index] as double);
      highspeed = true;
    }
    internalSpeed = 1 /
        internalSpeed; // For using function radSpeedToInt(), change to unit Senonds/Rad.
    var speedInt = radSpeedToInt(axis, internalSpeed);
    if ((mcVersion == 0x010600) || (mcVersion == 0x010601)) {
      // For special MC version.
      speedInt -= 3;
    }
    if (speedInt < 6) speedInt = 6;
    setStepPeriod(axis, speedInt);

    // Start motion
    // if (axesStatus[Axis] & AXIS_FULL_STOPPED)				// It must be remove for the latest DC motor board.
    startMotion(axis);

    axesStatus[axis.index].setSlewing(forward, highspeed);
    slewingSpeed[axis.index] = speed;
  }

  @override
  void mcAxisSlewTo(Axis axis, double pos) {
    // Get current position of the axis.
    var curPosition = mcGetAxisPosition(axis);

    // Calculate slewing distance.
    // Note: For EQ mount, positions[axis1] is offset( -PI/2 ) adjusted in UpdateAxisPosition().
    var movingAngle = pos - curPosition;

    // Convert distance in radian into steps.
    var movingSteps = angleToStep(axis, movingAngle);

    bool forward = false, highspeed = false;

    // If there is no increment, return directly.
    if (movingSteps == 0) {
      return;
    }

    // Set moving direction
    if (movingSteps > 0) {
      _dir = Utf16Char.fromString("0");
      forward = true;
    } else {
      _dir = Utf16Char.fromString("1");
      movingSteps = -movingSteps;
      forward = false;
    }

    // Might need to check whether motor has stopped.

    // Check if the distance is long enough to trigger a high speed GOTO.
    if (movingSteps > _lowSpeedGotoMargin[axis.index]) {
      setMotionMode(
        axis,
        Utf16Char.fromString('0'),
        _dir,
      ); // high speed GOTO slewing
      highspeed = true;
    } else {
      setMotionMode(
        axis,
        Utf16Char.fromString('2'),
        _dir,
      ); // low speed GOTO slewing
      highspeed = false;
    }

    setGotoTargetIncrement(axis, movingSteps);
    setBreakPointIncrement(axis, _breakSteps[axis.index]);
    startMotion(axis);

    targetPositions[axis.index] = pos;
    axesStatus[axis.index].setSlewingTo(forward, highspeed);
  }

  @override
  void mcAxisStop(Axis axis) {
    talkWithAxis(axis, Utf16Char.fromString(_instantStop ? 'L' : 'K'), null);
    axesStatus[axis.index].setFullStop();
  }

  @override
  void mcSetAxisPosition(Axis axis, double pos) {
    var newStepIndex = angleToStep(axis, pos);
    newStepIndex += 0x800000;

    final szCmd = newStepIndex.to24BitHexString();
    talkWithAxis(axis, Utf16Char.fromString('E'), szCmd);

    positions[axis.index] = pos;
  }

  @override
  double mcGetAxisPosition(Axis axis) {
    final response = talkWithAxis(axis, Utf16Char.fromString("j"), null);

    var iPosition = _parseBcdString(response);
    iPosition -= 0x00800000;
    positions[axis.index] = stepToAngle(axis, iPosition);

    return positions[axis.index];
  }

  @override
  AxisStatus mcGetAxisStatus(Axis axis) {
    final response = talkWithAxis(axis, Utf16Char.fromString('f'), null);

    if ((response.codeUnitAt(2) & 0x01) != 0) {
      // Axis is running
      if ((response.codeUnitAt(1) & 0x01) != 0) {
        axesStatus[axis.index].slewing =
            true; // Axis in slewing(AstroMisc speed) mode.
      } else {
        axesStatus[axis.index].slewingTo = true; // Axis in SlewingTo mode.
      }
    } else {
      axesStatus[axis.index].fullStop =
          true; // FullStop = 1;	// Axis is fully stop.
    }

    if ((response.codeUnitAt(1) & 0x02) == 0) {
      axesStatus[axis.index].slewingForward = true; // Angle increase = 1;
    } else {
      axesStatus[axis.index].slewingForward = false;
    }

    if ((response.codeUnitAt(1) & 0x04) != 0) {
      axesStatus[axis.index].highSpeed = true; // HighSpeed running mode = 1;
    } else {
      axesStatus[axis.index].highSpeed = false;
    }

    if ((response.codeUnitAt(3) & 1) == 0) {
      axesStatus[axis.index].notInitialized = true; // MC is not initialized.
    } else {
      axesStatus[axis.index].notInitialized = false;
    }

    return axesStatus[axis.index];
  }

  @override
  void mcSetSwitch(bool on) {
    talkWithAxis(Axis.axis1, Utf16Char.fromString('O'), on ? '1' : '0');
  }

  // Skywaterch Helper function

  // Test if connect to DC motor board.
  bool _checkIfDcMotor() {
    //// Enter critical section to block others conversation with motor controller.
    ////EnterCriticalSection(&csPortBusy);
    ////PortBusy = TRUE;

    //// Enable TX driver.
    //EscapeCommFunction(hCom, SETRTS);
    //// Wait TX enabled
    //Sleep(20);

    //// Clear unsent charactor and any charactor received before this conversation.
    //// Do this after I get control of communication bus.
    //PurgeComm(hCom, PURGE_RXCLEAR | PURGE_TXCLEAR);

    //// Send a Start charactor.
    //// The Skyatcher motor controller always resets its RX buffer whenever a start charactor is received.
    //WriteFile(hCom, ":", 1, &Count, NULL);

    //// Disable TX driver.
    //// EscapeCommFunction(hCom, CLRRTS);

    //ReadFile(hCom, Buffer, 1, &Count, NULL);

    //if ((Count == 1) && (Buffer[0] == ':'))
    //{
    //    _isDcMotor = TRUE;

    //    // Disable TX driver if it is a DC motor controller.
    //    EscapeCommFunction(hCom, CLRRTS);
    //}
    //else
    //    _isDcMotor = FALSE;

    //// PortBusy = FALSE;
    //// Quit critical section. Enable other conversation.
    //// LeaveCriticalSection(&csPortBusy);

    //SetEvent(hEvent_SerialPortIdled);

    //return _isDcMotor;

    // FIXME: Implement [MountSkywatcher._checkIfDcMotor]!
    /*
    lock(mConnection) {
      mConnection.lock();
      System.Threading.Thread.Sleep(20);

      mConnection.clearBuffer();
      mConnection.write(":");

      mConnection.release();

      var r = mConnection.read();

      if (r.Length == 1 && r[0] == ':') return true;

      return false;
    }
    */

    throw UnimplementedError("Implement [MountSkywatcher._checkIfDcMotor]!");
  }

  void _prepareForSlewing(Axis axis, double speed) {
    Utf16Char cDirection;

    var axesstatus = mcGetAxisStatus(axis);
    if (!axesstatus.fullStop) {
      if ((axesstatus.slewingTo) || // GOTO in action
              (axesstatus.highSpeed) || // Currently high speed slewing
              (speed.abs() >= lowSpeedMargin) || // Will be high speed slewing
              ((axesstatus.slewingForward) &&
                  (speed < 0)) || // Different direction
              (!(axesstatus.slewingForward) &&
                  (speed > 0)) // Different direction
          ) {
        // We need to stop the motor first to change Motion Mode, etc.
        mcAxisStop(axis);
      } else {
        // Other situatuion, there is no need to set motion mode.
        return;
      }

      // Wait until the axis stop
      while (true) {
        // Update Mount status, the status of both axes are also updated because _GetMountStatus() includes such operations.
        axesstatus = mcGetAxisStatus(axis);

        // Return if the axis has stopped.
        if (axesstatus.fullStop) break;

        // FIXME: Implement await instead of Thread.Sleep!
        /* Thread.Sleep(100); */

        // If the axis is asked to stop.
        // if ( (!AxesAskedToRun[Axis] && !(MountStatus & MOUNT_TRACKING_ON)) )		// If axis1 or axis2 is asked to stop or
        //	return ERR_USER_INTERRUPT;
      }
    }

    if (speed > 0.0) {
      cDirection = Utf16Char.fromString('0');
    } else {
      cDirection = Utf16Char.fromString('1');
      speed = -speed; // Get absolute value of Speed.
    }

    if (speed > lowSpeedMargin) {
      setMotionMode(axis, Utf16Char.fromString('3'),
          cDirection); // Set HIGH speed slewing mode.
    } else {
      setMotionMode(axis, Utf16Char.fromString('1'),
          cDirection); // Set LOW speed slewing mode.
    }
  }

  //*********************** MOTOR COMMAND SET **************************//
  // Inquire Motor Board Version ":e(*1)", where *1: '1'= CH1, '2'= CH2, '3'= Both.
  @protected
  void inquireMotorBoardVersion(Axis axis) {
    String response = talkWithAxis(
      axis,
      Utf16Char.fromString("e"),
      null,
    );

    var tmpMCVersion = _parseBcdString(response);

    mcVersion = ((tmpMCVersion & 0xFF) << 16) |
        ((tmpMCVersion & 0xFF00)) |
        ((tmpMCVersion & 0xFF0000) >> 16);
  }

  // Inquire Grid Per Revolution ":a(*2)", where *2: '1'= CH1, '2' = CH2.
  @protected
  void inquireGridPerRevolution(Axis axis) {
    final response = talkWithAxis(
      axis,
      Utf16Char.fromString("a"),
      null,
    );

    var gearRatio = _parseBcdString(response);

    // There is a bug in the earlier version firmware(Before 2.00) of motor controller MC001.
    // Overwrite the GearRatio reported by the MC for 80GT mount and 114GT mount.

    if ((mcVersion & 0x0000FF) == 0x80) {
      gearRatio = 0x162B97; // for 80GT mount
    }

    if ((mcVersion & 0x0000FF) == 0x82) {
      gearRatio = 0x205318; // for 114GT mount
    }

    factorRadToStep[axis.index] = gearRatio / (2 * pi);
    factorStepToRad[axis.index] = 2 * pi / gearRatio;
  }

  // Inquire Timer Interrupt Freq ":b1".
  @protected
  void inquireTimerInterruptFreq(Axis axis) {
    final response = talkWithAxis(
      axis,
      Utf16Char.fromString("b"),
      null,
    );

    final frequency = _parseBcdString(response);

    _stepTimerFreq[axis.index] = frequency;

    factorRadRateToInt[axis.index] =
        (frequency as double) / factorRadToStep[axis.index];
  }

  // Inquire high speed ratio ":g(*2)", where *2: '1'= CH1, '2' = CH2.
  @protected
  void inquireHighSpeedRatio(Axis axis) {
    final response = talkWithAxis(axis, Utf16Char.fromString("g"), null);
    _highSpeedRatio[axis.index] = _parseBcdString(response);
  }

  // Inquire PEC Period ":s(*1)", where *1: '1'= CH1, '2'= CH2, '3'= Both.
  @protected
  void inquirePECPeriod(Axis axis) {
    final response = talkWithAxis(
      axis,
      Utf16Char.fromString("s"),
      null,
    );

    final pecPeriod = _parseBcdString(response);
    _peSteps[axis.index] = pecPeriod;
  }

  // Set initialization done ":F3", where '3'= Both CH1 and CH2.
  @protected
  void initializeMC() {
    talkWithAxis(Axis.axis1, Utf16Char.fromString("F"), null);
    talkWithAxis(Axis.axis2, Utf16Char.fromString("F"), null);
  }

  @protected
  void setMotionMode(Axis axis, Utf16Char func, Utf16Char direction) {
    final szCmd = func.toString() + direction.toString();
    talkWithAxis(axis, Utf16Char.fromString("G"), szCmd);
  }

  @protected
  void setGotoTargetIncrement(Axis axis, int stepsCount) {
    final cmd = stepsCount.to24BitHexString();

    talkWithAxis(axis, Utf16Char.fromString("H"), cmd);
  }

  @protected
  void setBreakPointIncrement(Axis axis, int stepsCount) {
    final szCmd = stepsCount.to24BitHexString();

    talkWithAxis(axis, Utf16Char.fromString("M"), szCmd);
  }

  @protected
  void setBreakSteps(Axis axis, int newBreakSteps) {
    var szCmd = newBreakSteps.to24BitHexString();
    talkWithAxis(axis, Utf16Char.fromString("U"), szCmd);
  }

  @protected
  void setStepPeriod(Axis axis, int stepsCount) {
    var szCmd = stepsCount.to24BitHexString();
    talkWithAxis(axis, Utf16Char.fromString("I"), szCmd);
  }

  @protected
  void startMotion(Axis axis) => talkWithAxis(
        axis,
        Utf16Char.fromString("J"),
        null,
      );

  /// Throws a [MountControlException] if parsing failed.
  int _parseBcdString(String string) {
    final value =
        StringUtilities.tryParseBinaryCodedDecimalFromSyntaResponse(string);

    if (value == null) {
      throw MountControlException(
        ErrorCode.invalidData,
        'Parse BCD Failed',
      );
    }

    return value;
  }
}

final class _Constants {
  _Constants._();

  /// Leading charactor of a command
  static Utf16Char get cStartCharOut => Utf16Char.fromString(":");

  /// Leading charactor of a NORMAL response.
  static Utf16Char get cStartCharIn => Utf16Char.fromString("=");

  /// Leading charactor of an ABNORMAL response.
  static Utf16Char get cErrChar => Utf16Char.fromString("!");

  /// Tailing charactor of command and response.
  static Utf16Char get cEndChar => Utf16Char.fromCharCode(13);
}
