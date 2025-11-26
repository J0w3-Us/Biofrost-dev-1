/// The `Ticker` class in Dart provides a stream of integers that emit a value every second.
class Ticker {
  const Ticker();

  Stream<int> tick() {
    return Stream.periodic(const Duration(seconds: 1), (x) => x + 1);
  }
}
