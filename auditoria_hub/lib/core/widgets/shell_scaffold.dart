// core/widgets/shell_scaffold.dart — Bottom Nav Shell estilo Biofrost
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/auth_state.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../theme/app_theme.dart';

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
      _NavTab(
        icon: Icons.home_outlined,
        iconActive: Icons.home_rounded,
        label: 'Inicio',
        route: '/showcase',
      ),
      _NavTab(
        icon: Icons.bar_chart_outlined,
        iconActive: Icons.bar_chart_rounded,
        label: 'Ranking',
        route: '/ranking',
      ),
      if (isAuth)
        _NavTab(
          icon: Icons.person_outline_rounded,
          iconActive: Icons.person_rounded,
          label: 'Perfil',
          route: '/profile',
        )
      else
        _NavTab(
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

    final bgColor = isDark ? AppColors.darkSurface1 : AppColors.lightSidebar;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    // Both modes share a dark nav background, so use zinc-400 for inactive items
    final inactiveColor = AppColors.darkTextSecondary;

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: borderColor),
          Container(
            height: 60,
            color: bgColor,
            child: Row(
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final isActive = currentIndex == i;
                final color = isActive ? activeColor : inactiveColor;

                return Expanded(
                  child: InkWell(
                    onTap: () => context.go(tab.route),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: isActive
                                ? activeColor.withAlpha(30)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Icon(
                            isActive ? tab.iconActive : tab.icon,
                            color: color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
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
