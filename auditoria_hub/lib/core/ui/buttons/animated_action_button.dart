import 'package:flutter/material.dart';

import '../animations/scale_on_tap_wrapper.dart';

class AnimatedActionButton extends StatelessWidget {
  const AnimatedActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.isLoading = false,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ScaleOnTapWrapper(
      enabled: !isLoading && onPressed != null,
      child: SizedBox(
        height: height,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: const StadiumBorder(),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foregroundColor,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: foregroundColor,
                  ),
                ),
        ),
      ),
    );
  }
}
