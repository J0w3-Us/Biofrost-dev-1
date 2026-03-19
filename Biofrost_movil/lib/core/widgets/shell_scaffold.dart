// core/widgets/shell_scaffold.dart — Bottom Nav Shell estilo Biofrost
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/auth_state.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/nav_bar_visibility_provider.dart';
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
    final isTeacherOrAdmin =
        auth is AuthAuthenticated && (auth.isTeacher || auth.isAdmin);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
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
      if (isTeacherOrAdmin)
        const _NavTab(
          icon: Icons.grid_view_outlined,
          iconActive: Icons.grid_view_rounded,
          label: 'Mi Panel',
          route: '/dashboard',
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
    // Solid colors — zero blur / glassmorphism (performance constraint)
    final navBgColor = isDark ? AppColors.darkSurface1 : AppColors.lightCard;
    final baseAccent = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final activeCircleColor = Color.lerp(navBgColor, baseAccent, 0.82)!;
    final activeIconColor = isDark ? AppColors.darkTextPrimary : Colors.white;
    final inactiveIconColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    final isOnline = ref.watch(isOnlineProvider);
    final autoHideEnabled = location.startsWith('/ranking');
    final navVisibleState = ref.watch(navBarVisibleProvider);
    final isNavVisible = autoHideEnabled ? navVisibleState : true;

    return Scaffold(
      extendBody: false,
      body: Column(
        children: [
          OfflineBanner(visible: !isOnline),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offset: isNavVisible ? Offset.zero : const Offset(0, 1.2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isNavVisible ? 1 : 0,
          child: IgnorePointer(
            ignoring: !isNavVisible,
            child: Container(
              decoration: BoxDecoration(
                color: navBgColor,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: List.generate(tabs.length, (index) {
                      final tab = tabs[index];
                      final isSelected = index == currentIndex;
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.go(tab.route),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  width: isSelected ? 40 : 0,
                                  height: isSelected ? 32 : 0,
                                  decoration: BoxDecoration(
                                    color: isSelected ? activeCircleColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isSelected ? tab.iconActive : tab.icon,
                                      size: 20,
                                      color: isSelected ? activeIconColor : Colors.transparent,
                                    ),
                                  ),
                                ),
                                if (!isSelected)
                                  Icon(
                                    tab.icon,
                                    size: 20,
                                    color: inactiveIconColor,
                                  ),
                              ],
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
