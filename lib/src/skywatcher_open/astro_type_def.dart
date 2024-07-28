class MountControlException implements Exception {
  final ErrorCode code;
  final String? message;

  MountControlException(this.code, [this.message]);
}

class MountType {
  /// AZ or EQ
  /// Skywatcher or Celestron
  /// Model #
}

// if it is a flag, should use const, if it is a state, should use enum

class AxisStatus {
  /// <summary>
  /// 4 different state
  /// 1. FullStop
  /// 2. Slewing
  /// 3. SlewingTo
  /// 4. Notinitialized
  /// </summary>
  AxisStatus({
    required this.fullStop,
    required this.slewing,
    required this.slewingTo,
    required this.slewingForward,
    required this.highSpeed,
    required this.notInitialized,
  });

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

  //// Mask for axis status
  //public const long AXIS_FULL_STOPPED = 0x0001;		// 該軸處於完全停止狀態
  //public const long AXIS_SLEWING = 0x0002;			// 該軸處於恒速運行狀態
  //public const long AXIS_SLEWING_TO = 0x0004;		    // 該軸處於運行到指定目標位置的過程中
  //public const long AXIS_SLEWING_FORWARD = 0x0008;	// 該軸正向運轉
  //public const long AXIS_SLEWING_HIGHSPEED = 0x0010;	// 該軸處於高速運行狀態
  //public const long AXIS_NOT_INITIALIZED = 0x0020;    // MC控制器尚未初始化, axis is not initialized.
}

// 望遠鏡兩軸的代碼
// ID unsed in ASTRO.DLL for axis 1 and axis 2 of a mount.
enum Axis {
  axis1,
  axis2,
}

enum ErrorCode {
  // 無效的望遠鏡代碼
  // Invalid mount ID
  invalidId(1),
  // 已經連接到另外一個ID的望遠鏡
  // Already connected to another mount ID
  alreadyConnected(2),
  // 尚未連接到望遠鏡
  // Telescope not connected.
  notConnected(3),
  // 無效或超範圍的資料
  // Invalid data, over range etc
  invalidData(4),
  // 串口忙
  // Serial port is busy.
  serialPortBusy(5),
  // 望遠鏡的主軸沒有回應
  //// No response from axis1
  noResponseAxis1(100),
  // 望遠鏡的次軸沒有回應
  noResponseAxis2(101),
  // 暫時無法執行該操作
  axisBusy(102),
  // 目標位置仰角過高
  maxPitch(103),
  // 目標位置仰角過低
  minPitch(104),
  // 用戶強制終止
  userInterrupt(105),
  // 校準望遠鏡失敗
  alignFailed(200),
  // 未實現的方法
  unimplement(300),
  // The alignment data is incorect.
  wrongAlignmentData(400);

  const ErrorCode(this.intValue);
  final int intValue;
}

enum MountModel {
  // Telescope ID, they must be started from 0 and coded continuously.
  celestronAz, // Celestron Alt/Az Mount
  celestronEq, // Celestron EQ Mount
  skyWatcherAz, // Skywatcher Alt/Az Mount
  skyWatcherEq, // Skywatcher EQ Mount
  orionEqg, // Orion EQ Mount
  orionTeleTrack, // Orion TeleTrack Mount
  eqEmulator, // EQ Mount Emulator
  azEmulator, // Alt/Az Mount Emulator
  nexStarGt80, // NexStarGT-80 mount
  nexStarGt114, // NexStarGT-114 mount
  starSeeker80, // NexStarGT-80 mount
  starSeeker114; // NexStarGT-114 mount
}
