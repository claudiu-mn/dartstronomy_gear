import 'dart:math';

Point<double> getPointOnCircle(Point center, num radius, num angle) {
  return Point(
    center.x + radius * cos(angle),
    center.y + radius * sin(angle),
  );
}
