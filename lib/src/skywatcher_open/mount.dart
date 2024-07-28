import 'dart:async';

import 'package:dartstronomy_gear/src/skywatcher_open/astro_type_def.dart';
import 'package:dartstronomy_gear/src/skywatcher_open/serial_connection.dart';
import 'package:dartstronomy_gear/src/skywatcher_open/utf_16_char.dart';
import 'package:meta/meta.dart';

/// Notes:
/// 1. Use exception instead of ErrCode because there is no dll import issue we need to handle and
/// the exception code stlye will much easier to maintain.
/// 2. Need to confirm the mapping between SerialPort class in C# and DCB class in C++, such as CTS.
/// 3. Rename UpdateAxisPosition and UpdateAxesStatus to GetAxisPosition and GetAxesStatus to hide the details
/// 4. LastSlewingIsPositive has been merge with axesStatus.SLEWING_FORWARD
///
/// 5. While bluetooth connection fail, user should apply connectCom and try to connect again
/// RTSEnable may not be accepcted
/// http://blog.csdn.net/solond/archive/2008/03/04/2146446.aspx
/// 6. It looks like Skywatcher mounts response time is 1.5x longer than Celestron's mount

/// <summary>
/// Define the abstract interface of a Mount, includes:
/// 1) Connection via Serial Port
/// 2) Protocol
/// 3) Basic Mount control interface
/// LV0.
/// talkWithAxis
/// LV1.
/// detectMount // Not implement yet
/// MCOpenTelescopeConnection
/// MCCloseTelescopeConnection
/// mcAxisSlew
/// mcAxisSlewTo
/// mcAxisStop
/// mcSetAxisPosition
/// mcGetAxisPosition
/// mcGetAxisStatus
/// </summary>
/// Checked 2/7/2011
abstract class Mount {
  /// The abstract Serial connection instance
  /// it is static because all connection shared the same serial connection
  /// and connection should be lock between differnct thread
  @protected
  SerialConnection? mConnection;

  // 馬達控制器的版本號
  @protected
  var mcVersion = 0;

  // Mount Id
  var mountModel = MountModel.celestronAz;

  // the physical meaning of mount (Az or EQ)
  var isEqMount = false;

  /// ************ Motion control related **********************
  /// They are variables represent the mount's status, but not grantee always updated.
  /// 1) The positions are updated with mcGetAxisPosition and mcSetAxisPosition
  /// 2) The targetPositions are updated with mcAxisSlewTo
  /// 3) The slewingSpeed are updated with MCAxisSlew
  /// 4) The axesStatus are updated updated with mcGetAxisStatus, mcAxisSlewTo, MCAxisSlew
  /// Notes:
  /// 1. positions may not represent the mount's position while it is slewing, or user manually update by hand
  var positions = <double>[0, 0]; // 托架的軸坐標位置，以弧度爲單位
  var targetPositions = <double>[0, 0]; // 目標位置，以弧度爲單位
  var slewingSpeed = <double>[0, 0]; // 以弧度/秒為單位的運行速度
  var axesStatus =
      <AxisStatus>[]; // 托架的兩軸狀態，應通過AxesStatus[axis1]和AxesStatus[axis2]引用

  Mount() {
    mcVersion = 0;
    isEqMount = false;

    positions[Axis.axis1.index] = 0;
    targetPositions[Axis.axis1.index] = 0;
    slewingSpeed[Axis.axis1.index] = 0;
    axesStatus[Axis.axis1.index] = AxisStatus(
      fullStop: false,
      notInitialized: true,
      highSpeed: false,
      slewing: false,
      slewingForward: false,
      slewingTo: false,
    );

    positions[Axis.axis2.index] = 0;
    targetPositions[Axis.axis2.index] = 0;
    slewingSpeed[Axis.axis2.index] = 0;
    axesStatus[Axis.axis2.index] = AxisStatus(
      fullStop: false,
      notInitialized: true,
      highSpeed: false,
      slewing: false,
      slewingForward: false,
      slewingTo: false,
    );
  }

  void dispose() {
    mConnection?.close();
  }

  /// <summary>
  /// Build a connection to mount via COM
  /// </summary>
  /// <param name="telescopePort">the COM port number for connection</param>
  /// Raise IOException
  void connectCom(int telescopePort) {
    throw UnimplementedError("Implement [Mount.connectCom]!");

    // FIXME: Implement serial COM connection
    /*
  
            // May raise IOException 
            //var hCom = new SerialPort(string.Format("\\$device\\COM{0}", telescopePort));
            var hCom = new SerialPort(string.Format("COM{0}", telescopePort));

            // Origional Code in C++
            //// Set communication parameter.
            //GetCommState(hCom, &dcb);
            //dcb.BaudRate = CBR_9600;
            //dcb.fOutxCtsFlow = FALSE;
            //dcb.fOutxDsrFlow = FALSE;
            //dcb.fDtrControl = DTR_CONTROL_DISABLE;
            //dcb.fDsrSensitivity = FALSE;
            //dcb.fTXContinueOnXoff = TRUE;
            //dcb.fOutX = FALSE;
            //dcb.fInX = FALSE;
            //dcb.fErrorChar = FALSE;
            //dcb.fNull = FALSE;
            //dcb.fRtsControl = RTS_CONTROL_DISABLE;
            //dcb.fAbortOnError = FALSE;
            //dcb.ByteSize = 8;
            //dcb.fParity = NOPARITY;
            //dcb.StopBits = ONESTOPBIT;
            //SetCommState(hCom, &dcb);

            //// Communication overtime parameter
            //GetCommTimeouts(hCom, &TimeOuts);
            //TimeOuts.ReadIntervalTimeout = 30;			// Maxim interval between two charactors, set according to Celestron's hand control.
            //TimeOuts.ReadTotalTimeoutAstroMisc = 500;	// Timeout for reading operation.
            //TimeOuts.ReadTotalTimeoutMultiplier = 2;	// DOUBLE the reading timeout
            //TimeOuts.WriteTotalTimeoutAstroMisc = 30;	// Write timeout
            //TimeOuts.WriteTotalTimeoutMultiplier = 2;	// DOUBLE the writing timeout
            //SetCommTimeouts(hCom, &TimeOuts);

            //// Set RTS to high level, this will disable TX driver in iSky.
            //EscapeCommFunction(hCom, CLRRTS);

            // Set communication parameter
            hCom.BaudRate = SerialConnect_COM.CBR.CBR_9600;
            // fOutxCTSFlow
            // fOutxDsrFlow
            hCom.DtrEnable = false;
            // fDsrSensitivity            
            hCom.Handshake = Handshake.RequestToSendXOnXOff;
            // fOutX
            // fInX
            // fErrorChar
            // fNull
            hCom.RtsEnable = false;
            // fAboveOnError
            hCom.Parity = Parity.None;
            hCom.DataBits = 8;
            hCom.StopBits = StopBits.One;

            hCom.ReadTimeout = 1000;
            hCom.WriteTimeout = 60;

            hCom.Open();
            mConnection = COMConnection(hCom);

    */
  }

  // Return the mount's info
  MountType? detectMount() => null;

  /// <summary>
  /// One communication between mount and client
  /// </summary>
  /// <param name="Axis">The target of command</param>
  /// <param name="Command">The comamnd char set</param>
  /// <param name="cmdDataStr">The data need to send</param>
  /// <returns>The response string from mount</returns>
  @protected
  String talkWithAxis(Axis axis, Utf16Char command, String? cmdDataStr) {
    // FIXME: Implement talkWithAxis
    /*

            /// Lock the serial connection
            /// It grantee there is only one thread entering this function in one time
            /// ref: http://msdn.microsoft.com/en-us/library/ms173179.aspx
            /// TODO: handle exception
            lock (mConnection)
            {
                for (var i = 0; i < 2; i++)
                {
                    /// The General Process for SerialPort COM
                    /// 1. Prepare Command Str by protocol
                    /// 2. Wait CTS if need
                    /// 3. Set RTS
                    /// 4. Send Command
                    /// 5. Receive Response
                    /// 6. Clear RTS

                    // prepare to communicate
                    try
                    {
                        mConnection.clearBuffer();
                        mConnection.waitIdle();
                        mConnection.lock();

                        // send the request
                        sendRequest(axis, command, cmdDataStr);

                        // Release the line, so the mount can send response
                        mConnection.release();

                        //Trace.TraceInformation("Send command successful");
                        // receive the response
                        return receiveResponse();
                    }
                    catch (TimeoutException e)
                    {
                        Trace.TraceError("Timeout, need Resend the Command");                        
                    }
                    catch (IOException e)
                    {
                        Trace.TraceError("Connnection Lost");
                        throw  MountControlException(ErrorCode.notConnected, e.Message);
                    }
                }
                //Trace.TraceError("Timeout, stop send");
                if (axis == Axis.axis1) {
                  throw  MountControlException(ErrorCode.noResponseAxis1);
                } else {
                  throw  MountControlException(ErrorCode.noResponseAxis2);
                }
            }
    */

    throw UnimplementedError("Implement [Mount.talkWithAxis]!");
  }

  /// <summary>
  ///
  /// </summary>
  /// <exception cref="IOException">Throw when</exception>
  /// <param name="Axis"></param>
  /// <param name="Command"></param>
  /// <param name="cmdDataStr"></param>
  @protected
  void sendRequest(Axis axis, Utf16Char command, String? cmdDataStr);

  /// Receive the response.
  ///
  /// Throws [TimeoutException].
  /// <exception cref="IOException"></exception>
  @protected
  Future<String> receiveResponse();

  /// ************** The Mount Control Interface *****************
  Future<void> mcInit();

  // Mount dependent motion control functions
  void mcAxisSlew(Axis axis, double speed);
  void mcAxisSlewTo(Axis axis, double pos);
  void mcAxisStop(Axis axis);
  // Unit: radian
  void mcSetAxisPosition(Axis axis, double pos);
  double mcGetAxisPosition(Axis axis);
  // Support Mount Status;
  AxisStatus mcGetAxisStatus(Axis axis);
  void mcSetSwitch(bool on);

  // 將弧度角度轉換為"步"
  @protected
  var factorRadToStep = <double>[0, 0]; // 將弧度數值乘以該系數即可得到馬達板的位置數值（24位數則丟棄最高字節即可）

  @protected
  int angleToStep(Axis axis, double angleInRad) {
    return (angleInRad * factorRadToStep[axis.index]) as int;
  }

  // 將"步"轉換為弧度角度
  @protected
  var factorStepToRad = <double>[0, 0]; // 將馬達板的位置數值(需處理符號問題后)乘以該系數即可得到弧度數值

  @protected
  double stepToAngle(Axis axis, int steps) {
    return steps * factorStepToRad[axis.index];
  }

  // 將弧度/秒的速度轉換為設定速度所用的整數
  @protected
  var factorRadRateToInt = <double>[0, 0]; // 將弧度/秒數值乘以該系數即可得到馬達板所使用的設定速度的32位整數

  @protected
  int radSpeedToInt(Axis axis, double rateInRad) {
    return (rateInRad * factorRadRateToInt[axis.index]) as int;
  }
}
