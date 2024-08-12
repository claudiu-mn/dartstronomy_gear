var debugEnabled = false;

/// Prints an object to the consolse using [print] if:
///   - [debugEnabled] was set to `true` previously
///   - [useForce] is `true`
void debugPrint(Object? object, {bool useForce = false}) {
  // TODO: Get package name automatically
  if (debugEnabled || useForce) print('dartstronomy_gear: $object');
}
