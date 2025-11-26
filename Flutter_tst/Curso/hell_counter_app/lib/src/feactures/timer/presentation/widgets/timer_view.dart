import 'package:flutter/material.dart';
import 'background.dart';
import 'timer_text.dart';
import 'actions_buttons.dart';

class TimerView extends StatelessWidget {
  const TimerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
      body: Stack(children: const [Background(), _TimerViewContent()]),
    );
  }
}

class _TimerViewContent extends StatelessWidget {
  // ignore: unused_element_parameter
  const _TimerViewContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [TimerText(), SizedBox(height: 24), ActionsButtons()],
      ),
    );
  }
}
