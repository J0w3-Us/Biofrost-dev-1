// core/widgets/shell_scaffold.dart — Bottom Nav Shell estilo Biofrost
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/auth_state.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isAuth = auth is AuthAuthenticated;
    final isTeacher = auth is AuthAuthenticated && auth.isTeacher;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      const _NavTab(
        icon: Icons.grid_view_outlined,
        iconActive: Icons.grid_view_rounded,
        label: 'Dashboard',
        route: '/dashboard',
      ),
      const _NavTab(
        icon: Icons.rocket_launch_outlined,
        iconActive: Icons.rocket_launch_rounded,
        label: 'Galería',
        route: '/showcase',
      ),
      if (isTeacher)
        const _NavTab(
          icon: Icons.folder_open_outlined,
          iconActive: Icons.folder_rounded,
          label: 'Evaluar',
          route: '/dashboard', // Misma ruta por ahora para la vista de profesor
        ),
      const _NavTab(
        icon: Icons.emoji_events_outlined,
        iconActive: Icons.emoji_events_rounded,
        label: 'Ranking',
        route: '/ranking',
      ),
      if (isAuth)
        const _NavTab(
          icon: Icons.person_outline_rounded,
          iconActive: Icons.person_rounded,
          label: 'Perfil',
          route: '/profile',
        )
      else
        const _NavTab(
          icon: Icons.login_rounded,
          iconActive: Icons.login_rounded,
          label: 'Entrar',
          route: '/login',
        ),
    ];

    int currentIndex = 0;
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].route)) {
        currentIndex = i;
        break;
      }
    }

    // ── Nav bar palette ──────────────────────────────────────────────────────
    final navBgColor = isDark ? Colors.black.withAlpha(120) : Colors.white.withAlpha(200);
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10);

    // Ícono inactivo
    const inactiveColor = AppColors.darkTextSecondary;

    // Aurora gradient — activo (mismo en dark y light, texto siempre blanco)
    const activeGradient = LinearGradient(
      colors: [
        Color(0xFFFF6B9D), // pink
        Color(0xFFFF8C5A), // orange
        Color(0xFFA855F7), // purple
      ],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );
    const activeIconColor = Colors.white;

    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      extendBody: true, // Para que el child ocupe todo el espacio detrás del nav flotante
      body: Column(
        children: [
          OfflineBanner(visible: !isOnline),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 8),
          child: Container(
            height: 70, // un poco más alto para verse más redondo y premium
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 60 : 20),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Efecto Glassmorphism
                child: Container(
                  decoration: BoxDecoration(
                    color: navBgColor,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: borderColor, width: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(tabs.length, (i) {
                      final tab = tabs[i];
                      final isActive = currentIndex == i;

                      return GestureDetector(
                        onTap: () => context.go(tab.route),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                          // ── Jelly / Gota effect ──
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: isActive
                                  ? [
                                      // Outer glow: deep purple
                                      BoxShadow(
                                        color: const Color(0xFFA855F7).withAlpha(150),
                                        blurRadius: 28,
                                        spreadRadius: -2,
                                        offset: const Offset(0, 8),
                                      ),
                                      // Inner glow: pink
                                      BoxShadow(
                                        color: const Color(0xFFFF6B9D).withAlpha(90),
                                        blurRadius: 14,
                                        spreadRadius: -4,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // ── Gradient background (animated width) ──
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isActive ? 18 : 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isActive ? activeGradient : null,
                                      color: isActive ? null : Colors.transparent,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isActive ? tab.iconActive : tab.icon,
                                          color: isActive ? activeIconColor : inactiveColor,
                                          size: 24,
                                        ),
                                        if (isActive) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            tab.label,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                  // ── Specular highlight (jelly top shine) ──
                                  if (isActive)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      height: 26,
                                      child: IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.white.withAlpha(110),
                                                Colors.white.withAlpha(0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.icon,
    required this.iconActive,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData iconActive;
  final String label;
  final String route;
}
