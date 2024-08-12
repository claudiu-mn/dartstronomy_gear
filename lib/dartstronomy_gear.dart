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

  /// The [MountSearch.stream] emits a [DartstronomyMount] for every
  /// mount within reach.
  ///
  /// [searchTimeout] dictates how much to wait for an answer from a potential
  /// mount.
  static MountSearch startMountSearch(Duration searchTimeout) =>
      getMountSearch(searchTimeout);

  /// Returns a new simulated [DartstronomyMount].
  /// [reliability] will be clamped to be within [0, 1].
  /// Supply [seed] to insure reproducibility.
  static DartstronomyMount getAMountSimulator(
    double reliability, [
    int? seed,
  ]) =>
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
