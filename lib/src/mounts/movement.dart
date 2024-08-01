import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
class Movement {
  /// Clamps [speed] to `[0, 1]` and [direction] to `[-π, π]`.
  Movement({required double speed, required double direction})
      : speed = speed.clamp(0, 1),
        direction = direction.clamp(-pi, pi);

  final double speed;
  final double direction;

  @override
  bool operator ==(covariant Movement other) {
    if (identical(this, other)) return true;

    return speed == other.speed && direction == other.direction;
  }

  @override
  int get hashCode => ListEquality<double>().hash([speed, direction]);

  @override
  String toString() {
    return '$runtimeType(${speed.toStringAsFixed(1)} @ ${direction.toStringAsFixed(1)})';
  }
}
