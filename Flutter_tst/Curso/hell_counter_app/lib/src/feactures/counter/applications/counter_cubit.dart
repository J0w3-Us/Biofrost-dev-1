import 'package:flutter_bloc/flutter_bloc.dart';

part 'counter_state.dart';

class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(const CounterState(0));

  void increment() {
    emit(CounterState(state.value + 1));
  }

  void decrement() {
    if (state.value > 0) {
      emit(CounterState(state.value - 1));
    }
  }

  void reset() {
    emit(const CounterState(0));
  }

  void setValue(int value) {
    if (value >= 0) {
      emit(CounterState(value));
    }
  }
}
