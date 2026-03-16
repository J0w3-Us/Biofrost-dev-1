import 'package:flutter/services.dart';

class HapticService {
  const HapticService._();

  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> success() async {
    // Flutter currently does not expose a dedicated success haptic on all platforms.
    await selection();
    await Future<void>.delayed(const Duration(milliseconds: 35));
    await lightImpact();
  }
}
