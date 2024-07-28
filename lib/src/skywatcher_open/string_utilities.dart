import 'dart:math';

extension StringUtilities on String {
  /// Example:
  /// ```dart
  /// const string = 'dartlang';
  /// var result = string.substring(1); // 'artlang'
  /// result = string.substring(1, 4); // 'artl'
  /// ```
  String cSharpSubstring(int start, [int? length]) {
    if (length == null) return substring(start);

    return substring(start, start + length);
  }

  /// Ported from the [following C# code](https://github.com/skywatcher-pacific/skywatcher_open/blob/5c8277c7c34aa4be870202ecbb56bbed29223650/BasicApi_CS/Mount_Skywatcher.cs#L365):
  /// ```c#
  /// protected long BCDstr2long(string str)
  /// {
  ///   // =020782 => 8521474
  ///   try
  ///   {
  ///     long value = 0;
  ///     for (int i = 1; i+1 < str.Length; i += 2)
  ///     {
  ///       value += (long)(int.Parse(str.Substring(i, 2), System.Globalization.NumberStyles.AllowHexSpecifier) * Math.Pow(16, i - 1));
  ///     }
  ///
  ///     // if(D)
  ///     // Log.d(TAG,"BCDstr2long " + response + ","+value);
  ///     return value;
  ///   }
  ///   catch (FormatException e)
  ///   {
  ///     throw new MountControlException(ErrorCode.ERR_INVALID_DATA,
  ///                     "Parse BCD Failed");
  ///   }
  ///   // return Integer.parseInt(response.substring(0, 2), 16)
  ///   // + Integer.parseInt(response.substring(2, 4), 16) * 256
  ///   // + Integer.parseInt(response.substring(4, 6), 16) * 256 * 256;
  /// }
  /// ```
  static int? tryParseBinaryCodedDecimalFromSyntaResponse(String source) {
    if (source.length < 2) return 0;

    return tryParseBinaryCodedDecimal(source.substring(1));
  }

  static int? tryParseBinaryCodedDecimal(String source) {
    var value = 0;

    for (var i = 0; i + 1 < source.length; i += 2) {
      final sub = source.cSharpSubstring(i, 2);
      final byte = int.tryParse(sub, radix: 16);

      if (byte == null) return null;

      value += byte * pow(16, i).toInt();
    }

    return value;
  }
}
