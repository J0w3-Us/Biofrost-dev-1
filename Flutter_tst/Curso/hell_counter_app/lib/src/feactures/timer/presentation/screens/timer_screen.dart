import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/timer_bloc.dart';
import '../../data/repositories/timer_repository_impl.dart';
import '../../domain/entities/ticker.dart';
import '../widgets/timer_view.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TimerBloc(timerRepository: TimerRepositoryImpl(const Ticker())),
      child: const TimerView(),
    );
  }
}
