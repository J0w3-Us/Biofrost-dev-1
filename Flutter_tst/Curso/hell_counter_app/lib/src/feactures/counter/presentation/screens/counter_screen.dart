import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hell_counter_app/src/feactures/counter/applications/counter_cubit.dart';

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contador'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CounterCubit>().reset(),
            tooltip: 'Reiniciar',
          ),
        ],
      ),
      body: BlocBuilder<CounterCubit, CounterState>(
        builder: (context, state) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Has presionado el botón esta cantidad de veces:',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${state.value}',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      onPressed: state.value > 0
                          ? () => context.read<CounterCubit>().decrement()
                          : null,
                      heroTag: "decrement",
                      backgroundColor: state.value > 0
                          ? Colors.red
                          : Colors.grey.withValues(alpha: 0.3),
                      child: const Icon(Icons.remove, color: Colors.white),
                    ),
                    FloatingActionButton.extended(
                      onPressed: () => context.read<CounterCubit>().reset(),
                      heroTag: "reset",
                      backgroundColor: Colors.orange,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: () => context.read<CounterCubit>().increment(),
                      heroTag: "increment",
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (state.value > 0) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.celebration,
                            size: 32,
                            color: Colors.amber,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.value == 1
                                ? '¡Primer click!'
                                : state.value < 10
                                ? '¡Sigue así!'
                                : state.value < 50
                                ? '¡Impresionante!'
                                : '¡Eres imparable!',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
