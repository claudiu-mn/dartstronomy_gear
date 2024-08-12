import 'package:dartstronomy_gear/src/canceling/cancelable.dart';

class CancelationToken implements Cancelable {
  @override
  bool isCanceled = false;

  @override
  void cancel() => isCanceled = true;
}
