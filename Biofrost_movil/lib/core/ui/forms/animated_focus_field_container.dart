import 'package:flutter/material.dart';

class AnimatedFocusFieldContainer extends StatelessWidget {
  const AnimatedFocusFieldContainer({
    super.key,
    required this.focusNode,
    required this.child,
    required this.backgroundColor,
    required this.focusedColor,
    required this.unfocusedColor,
    this.borderRadius = 999,
  });

  final FocusNode focusNode;
  final Widget child;
  final Color backgroundColor;
  final Color focusedColor;
  final Color unfocusedColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isFocused ? focusedColor : unfocusedColor,
              width: isFocused ? 1.8 : 1,
            ),
          ),
          child: child,
        );
      },
    );
  }
}
