import 'package:dartstronomy_gear/src/canceling/cancelable.dart';

class CancelationToken implements Cancelable {
  bool isCancelled = false;

  @override
  void cancel() => isCancelled = true;
}
