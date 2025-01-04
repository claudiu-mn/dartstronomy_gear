import 'dart:math';

import 'package:dartstronomy_gear/src/math/size.dart';

Point<double> getPointOnEllipse(Point center, Size halfSize, num angle) {
  return Point(
    center.x + halfSize.width * cos(angle),
    center.y + halfSize.height * sin(angle),
  );
}

Point<double> getPointOnCircle(Point center, num radius, num angle) {
  return getPointOnEllipse(center, Size.square(radius), angle);
}
