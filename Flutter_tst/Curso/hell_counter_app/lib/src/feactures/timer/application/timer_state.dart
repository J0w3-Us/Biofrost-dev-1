part of 'timer_bloc.dart';

abstract class TimerState extends Equatable {
  const TimerState(this.duration);
  final int duration;

  @override
  List<Object> get props => [duration];
}

class TimerInitial extends TimerState {
  const TimerInitial(super.duration);
}

class TimerTicking extends TimerState {
  const TimerTicking(super.duration);
}

class TimerFinished extends TimerState {
  const TimerFinished() : super(0);
}
