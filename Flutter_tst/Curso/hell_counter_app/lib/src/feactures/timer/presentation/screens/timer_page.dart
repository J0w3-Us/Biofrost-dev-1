import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hell_counter_app/src/feactures/timer/bloc/timer_bloc.dart';
import 'package:hell_counter_app/src/feactures/timer/ticker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerPage extends StatelessWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TimerBloc(ticker: const Ticker()),
      child: const TimerView(),
    );
  }
}

class TimerView extends StatefulWidget {
  const TimerView({super.key});

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  bool _backgroundEnabled = true;
  bool _alarmPlayed = false;

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  Future<void> _loadPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('timer_background_enabled') ?? true;
      if (mounted) setState(() => _backgroundEnabled = enabled);
    } catch (_) {
      // ignore errors and leave default true
    }
  }

  void _playAlarm() async {
    if (_alarmPlayed) return;
    _alarmPlayed = true;

    // Vibración/feedback háptico repetido para simular alarma
    for (int i = 0; i < 5; i++) {
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void _showTimePickerDialog() {
    final TextEditingController minutesController = TextEditingController();
    final TextEditingController secondsController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Configurar Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutos',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: secondsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Segundos',
                hintText: '0',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(minutesController.text) ?? 0;
              final seconds = int.tryParse(secondsController.text) ?? 0;
              final totalSeconds = (minutes * 60) + seconds;

              if (totalSeconds > 0) {
                context.read<TimerBloc>().add(
                  TimerStarted(duration: totalSeconds),
                );
                _alarmPlayed = false; // Reset alarm flag
              }

              Navigator.of(dialogContext).pop();
            },
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Timer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer),
            tooltip: 'Configurar tiempo',
            onPressed: _showTimePickerDialog,
          ),
        ],
      ),
      body: BlocListener<TimerBloc, TimerState>(
        listener: (context, state) {
          // Activar alarma cuando el timer llegue a cero
          if (state is TimerRunComplete) {
            _playAlarm();
          }
        },
        child: Stack(
          children: [
            if (_backgroundEnabled) const Background(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 100.0),
                  child: Center(child: TimerText()),
                ),
                Actions(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TimerText extends StatelessWidget {
  const TimerText({super.key});

  @override
  Widget build(BuildContext context) {
    final duration = context.select((TimerBloc bloc) => bloc.state.duration);
    final minutesStr = ((duration / 60) % 60).floor().toString().padLeft(
      2,
      '0',
    );
    final secondsStr = (duration % 60).floor().toString().padLeft(2, '0');
    return Text(
      '$minutesStr:$secondsStr',
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
        fontSize: 72,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class Actions extends StatelessWidget {
  const Actions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      buildWhen: (prev, state) => prev.runtimeType != state.runtimeType,
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...switch (state) {
              TimerInitial() => [
                FloatingActionButton(
                  child: const Icon(Icons.play_arrow),
                  onPressed: () => context.read<TimerBloc>().add(
                    TimerStarted(duration: state.duration),
                  ),
                ),
              ],
              TimerRunInProgress() => [
                FloatingActionButton(
                  child: const Icon(Icons.pause),
                  onPressed: () =>
                      context.read<TimerBloc>().add(const TimerPaused()),
                ),
                FloatingActionButton(
                  child: const Icon(Icons.replay),
                  onPressed: () =>
                      context.read<TimerBloc>().add(const TimerReset()),
                ),
              ],
              TimerRunPause() => [
                FloatingActionButton(
                  child: const Icon(Icons.play_arrow),
                  onPressed: () =>
                      context.read<TimerBloc>().add(const TimerResumed()),
                ),
                FloatingActionButton(
                  child: const Icon(Icons.replay),
                  onPressed: () =>
                      context.read<TimerBloc>().add(const TimerReset()),
                ),
              ],
              TimerRunComplete() => [
                FloatingActionButton(
                  child: const Icon(Icons.replay),
                  onPressed: () =>
                      context.read<TimerBloc>().add(const TimerReset()),
                ),
              ],
            },
          ],
        );
      },
    );
  }
}

class Background extends StatefulWidget {
  const Background({super.key});

  @override
  State<Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<Background> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<AnimatedCircle> _circles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Crear múltiples círculos animados con diferentes propiedades
    _circles = List.generate(15, (index) {
      final random = math.Random(index);
      return AnimatedCircle(
        size: random.nextDouble() * 150 + 50,
        xOffset: random.nextDouble() * 2 - 1,
        yOffset: random.nextDouble() * 2 - 1,
        speed: random.nextDouble() * 0.5 + 0.3,
        opacity: random.nextDouble() * 0.3 + 0.1,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        // Colores según el estado del timer
        List<Color> colors = switch (state) {
          TimerInitial() => [const Color(0xFF667eea), const Color(0xFF764ba2)],
          TimerRunInProgress() => [
            const Color(0xFF11998e),
            const Color(0xFF38ef7d),
          ],
          TimerRunPause() => [const Color(0xFFf093fb), const Color(0xFFF5576c)],
          TimerRunComplete() => [
            // Colores de alarma: rojo brillante a naranja
            const Color(0xFFFF0000),
            const Color(0xFFFF6B00),
          ],
        };

        return AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Stack(
            children: [
              // Círculos animados
              ..._circles.map((circle) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // Si el timer terminó, hacer la animación más rápida y errática
                    final speed = state is TimerRunComplete
                        ? circle.speed * 3
                        : circle.speed;
                    final progress = (_controller.value * speed) % 1.0;
                    final x =
                        circle.xOffset + math.sin(progress * 2 * math.pi) * 0.3;
                    final y =
                        circle.yOffset + math.cos(progress * 2 * math.pi) * 0.3;

                    return Positioned.fill(
                      child: Align(
                        alignment: Alignment(x, y),
                        child: Container(
                          width: circle.size,
                          height: circle.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(
                                  alpha: state is TimerRunComplete
                                      ? circle.opacity * 2
                                      : circle.opacity,
                                ),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
              // Efecto de ondas
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(
                      animationValue: _controller.value,
                      color: Colors.white.withValues(
                        alpha: state is TimerRunComplete ? 0.3 : 0.1,
                      ),
                    ),
                    child: Container(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class AnimatedCircle {
  final double size;
  final double xOffset;
  final double yOffset;
  final double speed;
  final double opacity;

  AnimatedCircle({
    required this.size,
    required this.xOffset,
    required this.yOffset,
    required this.speed,
    required this.opacity,
  });
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  WavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final waveHeight = 20.0;
    final waveLength = size.width / 2;

    for (var i = 0; i < 3; i++) {
      path.reset();
      final yOffset =
          size.height * (0.3 + i * 0.2) +
          math.sin(animationValue * 2 * math.pi + i) * 30;

      path.moveTo(0, yOffset);

      for (double x = 0; x <= size.width; x++) {
        final y =
            yOffset +
            math.sin((x / waveLength + animationValue * 2 + i) * math.pi * 2) *
                waveHeight;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
