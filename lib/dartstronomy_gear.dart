import 'package:dartstronomy_gear/src/mounts/dartstronomy_mount.dart';
import 'package:dartstronomy_gear/src/search.dart';
import 'package:dartstronomy_gear/src/simulation.dart';

export 'package:dartstronomy_gear/src/canceling/cancelable.dart';
export 'package:dartstronomy_gear/src/math.dart';
export 'package:dartstronomy_gear/src/mounts/dartstronomy_mount.dart';
export 'package:dartstronomy_gear/src/mounts/movement.dart';

final class DartstronomyGear {
  DartstronomyGear._();

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
}
