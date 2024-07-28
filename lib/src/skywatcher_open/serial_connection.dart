/// Note:
/// When controller want to send data, it set RTS high
/// When device ready to receive data, it set CTS high, then data transmision begins
///
/// Refactor the CTS method in code:
/// 1: PrepareConversation
///     NexStar_GT, Skywatcher_EQ: SETRTS
///     Celestron,Skywatcher_AZ: Wait CTS on, Set SETRTS
/// 2: Clear Buffer
/// 3: Write
/// 4: PrepareToReceive
///     Celestron: Read Echo, CLRRTS
///     Others: Do nothing
/// 5: ReceiveResponse
///     Celestron, all others: Read,
///     Skywatcher: CLRRTS
/// 6. EndConversation:
///     Celstron, Skywatcher_AZ: CLRRTS
/// Generally Speaking:
/// Wait CTS(depend), SETRTS, Send Data, Read Data, CLRRTS
///
/// Issues, the bluetooth serial port (COM) didn't support RTS operation. it will raise exception
/// HandShake also didn't support RTS operation
/// Right now, the bluetooth connection is built by windows SPP to com support
///
/// <summary>
/// The abstract class of serial connection.
/// We use the same serial connection method with Bluetooth, COM, Wifi connection
/// on PC, WinCE, iPhone, and Android
/// </summary>
abstract class SerialConnection {
  //public int BytesSent;   // How many bytes have been sent in last write

  String stringSent = "";

  void close();

  // StringBuilder mBuffer = new StringBuilder();

  void waitIdle() {}
  void lock() {}
  void release() {}

  /// <summary>
  /// write command to mount
  /// </summary>
  /// <param name="Command">command string</param>
  void write(String command);

  /// <summary>
  /// Read all string available from mount.
  /// </summary>
  /// <returns></returns>
  String read();

  /*
  /// <summary>
  /// Read specify characters to buffer, start at offset
  /// </summary>
  /// <param name="buffer">read buffer</param>
  /// <param name="offset">the starting bits</param>
  /// <param name="count">the offset</param>
  /// <returns></returns>
  abstract int read(char[] buffer, int offset, int count);
  */

  /// <summary>
  /// Clean the read and write buffer
  /// </summary>
  void clearBuffer();
}

// FIXME: Implement COM Connection
/*

    /// <summary>
    /// 
    /// The mapping of DCB in C++ and SerialPort in C#:
    /// BaudRate = BaudRate
    /// BreakState =  Break
    /// BytesToRad = InBufferCount
    /// BytesToWrite= OutBufferCount
    /// CDHolding = MC_RLSD_ON
    /// CtsHolding = MS_CTS_ON
    /// DataBits = ByteSize
    /// DiscardNull = DiscardNulls
    /// DsrHolding = MS_DSR_ON
    /// DtrEnable 
    /// ref: http://www.java2s.com/Open-Source/CSharp/Development/SerialPort/OpenNETCF/IO/Ports/Streams/WinStream.cs.htm     
    /// </summary>
     class ComConnection extends SerialConnection
    {
         SerialPort hCom;

        ComConnection(SerialPort com) : _doNotCheckCTS = false
        {
            hCom = com;
            //_doNotCheckCTS = _hasHardwareFlowControl();
        }

        /// Detect the serial connection need to have HardwareFlowControl or notb
        bool _doNotCheckCTS;
        bool _hasHardwareFlowControl()
        {
            var result = true;
            const SLEEP_TIME = 10;
            var MaxLoopCount = (400 / SLEEP_TIME) as int;

            // Wait for other master to release CTS line.
            do
            {
                // Get CTS status. CTS is active low: it is ON when the level is low.
                if (hCom.CtsHolding)
                {
                    if (MaxLoopCount == 0)
                    {
                        // If overtime, it should be a bluetooth serial port.
                        return false;
                    }
                    // Calling thread sleep, reduce CPU load.
                    System.Threading.Thread.Sleep(SLEEP_TIME);
                    MaxLoopCount--;
                }
            } while (hCom.CtsHolding);// repeat if CTS is low level.

            // Pull CTS/RTS(Active Low) low. Enable TX driver and claim the TX/RX bus is busy.
            hCom.RtsEnable = true;

            // Now check CTS line, it should be pulled down on Celestron mount and Skywatcher's Az mount
            // if using a cable to connect iSky to the mount.
            // Get CTS status. CTS is active low: it is ON when the level is low.
            if (hCom.CtsHolding) {
              result = true;
            } else {
              result = false;
            }

            hCom.RtsEnable = false;

            return result;
        }

        @override
        void waitIdle()
        {
            // Wait Idle is not c

            //const int SleepTime = 10;
            //const int MaxLoopCount = 20 / SleepTime;

            ///// 1. Wait CTS if need
            //if (!_doNotCheckCTS)
            //{
            //    for (int i = 0; i < MaxLoopCount; i++)
            //    {
            //        if (!hCom.CtsHolding)
            //            return;
            //        else
            //        {
            //            // If CTS is low level                                                                
            //            System.Threading.Thread.Sleep(SleepTime);
            //        }
            //    }
            //    throw new TimeoutException();
            //}
        }
        
        @override
         void lock()
        {
            //hCom.RtsEnable = true;
        }
        
        @override
        void write(String Command)
        {
            // throw IOException
                //Console.WriteLine("write :" + Command);
                hCom.Write(Command);
                StringSent = Command;
            
        }
        
        @override
        String read()
        {
            // throw IOException
            var r = hCom.ReadExisting();
            //if(r.Length > 0)
            //    Console.WriteLine("read :" + r);            
            mBuffer.Append(r);
            return r;
        }

        @override
        void release()
        {
            //hCom.RtsEnable = false;
        }

        //public override int read(char[] buffer, int offset, int count)
        //{
        //    return hCom.Read(buffer, offset, count);
        //}

        @override
        void clearBuffer()
        {
            hCom.DiscardOutBuffer();
            hCom.DiscardInBuffer();
            mBuffer.Remove(0, mBuffer.Length);
        }

        @override
        void close() => if (hCom.IsOpen) hCom.close();
    }

*/
