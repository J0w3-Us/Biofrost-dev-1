part of 'counter_cubit.dart';

class CounterState {
  final int value;

  const CounterState(this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CounterState && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
