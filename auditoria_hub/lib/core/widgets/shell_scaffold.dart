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
    // Ajuste de colores para un Glassmorphism mucho más intenso y translúcido
    final navBgColor = isDark ? Colors.black.withAlpha(20) : Colors.white.withAlpha(40);
    final borderColor = isDark ? Colors.white.withAlpha(15) : Colors.white.withAlpha(30);

    // Ícono inactivo
    const inactiveColor = AppColors.darkTextSecondary;

    // Active pill styles (Glassmorphic pill)
    final activePillColor = isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(15);
    final activeIconColor = isDark ? Colors.white : Colors.black;

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
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), // Desenfoque más potente para mejor glassmorphism
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

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => context.go(tab.route),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
                            // ── Clean Pill con efecto lupa (sin texto) ──
                            child: Container(
                              color: Colors.transparent, // Facilita el área de tap total
                              alignment: Alignment.center,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.elasticOut, // Efecto gelatina
                                width: isActive ? 52 : 40,
                                height: isActive ? 52 : 40,
                                decoration: BoxDecoration(
                                  color: isActive ? activePillColor : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: AnimatedScale(
                                  scale: isActive ? 1.2 : 1.0, // Efecto lupa
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.elasticOut, // Movimiento de gelatina en el icono
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, animation) {
                                      // Usar fade para transición suave del ícono
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                    child: Icon(
                                      isActive ? tab.iconActive : tab.icon,
                                      key: ValueKey<bool>(isActive),
                                      color: isActive ? activeIconColor : inactiveColor,
                                      size: 24, // El tamaño base es el mismo, el zoom lo da AnimatedScale
                                    ),
                                  ),
                                ),
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
