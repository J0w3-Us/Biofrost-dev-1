import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../feactures/timer/presentation/screens/timer_screen.dart';

class TimerApp extends StatelessWidget {
  const TimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Timer',
      theme: AppTheme().getTheme(),
      home: const TimerScreen(),
    );
  }
}
