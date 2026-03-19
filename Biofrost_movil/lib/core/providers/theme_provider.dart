// core/providers/theme_provider.dart — Toggle de tema oscuro/claro
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'theme_mode';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.dark; // Default: dark-first
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    if (saved != null) {
      state = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    }
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    unawaited(
      prefs.setString(_kThemeKey, next == ThemeMode.light ? 'light' : 'dark'),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    unawaited(
      prefs.setString(_kThemeKey, mode == ThemeMode.light ? 'light' : 'dark'),
    );
  }

  bool get isDark => state == ThemeMode.dark;
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
