import 'package:flutter/material.dart';

class CustomWaves extends StatelessWidget {
  const CustomWaves({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF48789E), Color(0xFF709FCC)],
        ),
      ),
    );
  }
}
