import 'package:dartstronomy_gear/src/debug/debug.dart';
import 'package:dartstronomy_gear/src/mounts/dartstronomy_mount.dart';
import 'package:dartstronomy_gear/src/search/mount_search.dart';
import 'package:dartstronomy_gear/src/search/search.dart';
import 'package:dartstronomy_gear/src/simulation.dart';
import 'package:meta/meta.dart';

export 'package:dartstronomy_gear/src/canceling/cancelable.dart';
export 'package:dartstronomy_gear/src/math/math.dart';
export 'package:dartstronomy_gear/src/mounts/dartstronomy_mount.dart';
export 'package:dartstronomy_gear/src/mounts/movement.dart';
export 'package:dartstronomy_gear/src/search/mount_search.dart';

@immutable
final class DartstronomyGear {
  const DartstronomyGear._();

  /// Returns a [Future] that completes with a [Set] of [String]s
  /// that represent the names of the network interfaces on which
  /// [DartstronomyGear] can look for [DartstronomyMount]s.
  static Future<Set<String>> get namesOfMountSearchCapableNetworkInterfaces =>
      getNamesOfSearchableNetworkInterfaces();

  /// The [MountSearch.stream] emits a [DartstronomyMount] for every
  /// mount within reach.
  ///
  /// [timeout] dictates how much to wait for an answer from a potential
  /// mount.
  ///
  /// [targetNetworkInterfaceNames] must be a subset of
  /// [DartstronomyGear.namesOfMountSearchCapableNetworkInterfaces].
  static MountSearch startMountSearch({
    required Duration timeout,
    required Set<String> targetNetworkInterfaceNames,
  }) =>
      getMountSearch(timeout, targetNetworkInterfaceNames);

  /// Returns a new simulated [DartstronomyMount].
  /// [reliability] will be clamped to be within [0, 1].
  /// Supply [seed] to insure reproducibility.
  static DartstronomyMount getAMountSimulator({
    required double reliability,
    int? seed,
  }) =>
      getSimulatedMount(reliability, seed);

  static set debugMode(bool value) {
    if (debugEnabled != value) {
      debugPrint(
        'Debugging has been ${value ? 'enabled' : 'disabled'}.',
        useForce: true,
      );
      debugEnabled = value;
    }
  }
}
