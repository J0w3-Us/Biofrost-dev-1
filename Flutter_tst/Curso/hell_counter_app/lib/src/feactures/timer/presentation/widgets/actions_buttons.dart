import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/timer_bloc.dart';

class ActionsButtons extends StatelessWidget {
  const ActionsButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      buildWhen: (prev, state) => prev.runtimeType != state.runtimeType,
      builder: (context, state) {
        if (state is TimerInitial) {
          return FloatingActionButton(
            onPressed: () => context.read<TimerBloc>().add(
              TimerStarted(duration: state.duration),
            ),
            child: const Icon(Icons.play_arrow),
          );
        }
        if (state is TimerTicking) {
          return Row(
            children: [
              FloatingActionButton(
                onPressed: () =>
                    context.read<TimerBloc>().add(const TimerPaused()),
                child: const Icon(Icons.pause),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: () =>
                    context.read<TimerBloc>().add(const TimerReset()),
                child: const Icon(Icons.replay),
              ),
            ],
          );
        }
        return FloatingActionButton(
          onPressed: () => context.read<TimerBloc>().add(const TimerReset()),
          child: const Icon(Icons.replay),
        );
      },
    );
  }
}
