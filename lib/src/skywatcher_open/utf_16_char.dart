class Utf16Char {
  Utf16Char.fromString(String charString) {
    _setStringValue(charString);
  }

  Utf16Char.fromCharCode(int intValue) {
    _setStringValue(String.fromCharCode(intValue));
  }

  late final String _stringValue;

  /// Throws an [ArgumentError] if [charString] is not a single UTF-16 code unit
  void _setStringValue(String charString) {
    if (charString.length != 1) {
      throw ArgumentError.value(
        charString,
        "charString",
        "Must be a single character!",
      );
    }

    _stringValue = charString;
  }

  @override
  String toString() => _stringValue;
}
