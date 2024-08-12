abstract interface class Cancelable {
  bool get isCanceled;

  void cancel();
}
