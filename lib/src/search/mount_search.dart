import 'package:dartstronomy_gear/src/canceling/cancelable.dart';
import 'package:dartstronomy_gear/src/mounts/dartstronomy_mount.dart';

typedef MountSearch = ({
  Stream<DartstronomyMount> stream,
  Cancelable cancelable,
});
