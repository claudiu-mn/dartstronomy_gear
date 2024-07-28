extension IntUtilities on int {
  // FIXME: Why not 31 -> 1F0000? Typo?
  //
  /// Ported from the [following C# code](https://github.com/skywatcher-pacific/skywatcher_open/blob/5c8277c7c34aa4be870202ecbb56bbed29223650/BasicApi_CS/Mount_Skywatcher.cs#L389):
  /// ```c#
  /// protected string longTo6BitHEX(long number)
  /// {
  ///   // 31 -> 0F0000
  ///   String A = ((int)number & 0xFF).ToString("X").ToUpper();
  ///   String B = (((int)number & 0xFF00) / 256).ToString("X").ToUpper();
  ///   String C = (((int)number & 0xFF0000) / 256 / 256).ToString("X").ToUpper();
  ///
  ///   if (A.Length == 1) A = "0" + A;
  ///   if (B.Length == 1) B = "0" + B;
  ///   if (C.Length == 1) C = "0" + C;
  ///
  ///   // if (D)
  ///   // Log.d(TAG, "longTo6BitHex " + number + "," + A + "," + B + "," + C);
  ///
  ///   return A + B + C;
  /// }
  /// ```
  String to24BitHexString() {
    var a = (this & 0x0000FF).toRadixString(16).toUpperCase();
    var b = ((this & 0x00FF00) ~/ 256).toRadixString(16).toUpperCase();
    var c = ((this & 0xFF0000) ~/ 256 ~/ 256).toRadixString(16).toUpperCase();

    if (a.length == 1) a = '0$a';
    if (b.length == 1) b = '0$b';
    if (c.length == 1) c = '0$c';

    return '$a$b$c';
  }
}
