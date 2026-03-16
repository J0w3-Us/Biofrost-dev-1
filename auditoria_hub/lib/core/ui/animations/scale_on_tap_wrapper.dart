import 'package:flutter/material.dart';

class ScaleOnTapWrapper extends StatefulWidget {
  const ScaleOnTapWrapper({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.985,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<ScaleOnTapWrapper> createState() => _ScaleOnTapWrapperState();
}

class _ScaleOnTapWrapperState extends State<ScaleOnTapWrapper> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (!widget.enabled) return;
        setState(() => _pressed = true);
      },
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        scale: _pressed ? widget.pressedScale : 1,
        child: widget.child,
      ),
    );
  }
}
