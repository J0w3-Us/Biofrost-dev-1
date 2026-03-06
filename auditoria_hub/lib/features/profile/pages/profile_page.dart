// features/profile/pages/profile_page.dart — Pantalla de perfil (Biofrost)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/domain/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);

    if (auth is! AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => _confirmLogout(context, ref),
            child: const Text(
              'Salir',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.sp40),
        children: [
          // ── Header ──────────────────────────────────────────────────
          _ProfileHeader(auth: auth, isDark: isDark),

          const SizedBox(height: AppSpacing.sp20),

          // ── KPIs ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
            child: _KpiRow(isDark: isDark),
          ),

          const SizedBox(height: AppSpacing.sp24),

          // ── Configuración ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
            child: Text(
              'Configuración',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightForeground,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp8),

          // Toggle tema
          _SettingsTile(
            isDark: isDark,
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'Tema oscuro',
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
              activeThumbColor:
                  isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
          ),

          _SettingsTile(
            isDark: isDark,
            icon: Icons.edit_outlined,
            title: 'Editar perfil',
            showArrow: true,
            onTap: () {}, // TODO: navegar a editar perfil
          ),

          const SizedBox(height: AppSpacing.sp24),

          // ── Información profesional ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
            child: Text(
              'Información profesional',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightForeground,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
            child: BioCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Rol',
                    value: auth.role.toUpperCase(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.sp12),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Correo',
                    value: auth.email,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sp32),

          // ── Cerrar sesión ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
            child: BioButton(
              label: 'Cerrar sesión',
              variant: BioButtonVariant.secondary,
              icon: Icons.logout_rounded,
              onPressed: () => _confirmLogout(context, ref),
            ),
          ),

          const SizedBox(height: AppSpacing.sp16),

          // Footer
          Center(
            child: Text(
              'Auditoría Hub v1.0.0 • IntegradorHub',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: isDark
                    ? AppColors.darkTextDisabled
                    : AppColors.lightMutedFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightMutedFg,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

// ── Profile Header ──────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.auth, required this.isDark});
  final AuthAuthenticated auth;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurface1, AppColors.darkSurface2]
              : [AppColors.lightSidebar, AppColors.lightSecondary],
        ),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp16, vertical: AppSpacing.sp24),
      child: Row(
        children: [
          UserAvatar(
            name: auth.displayName,
            imageUrl: auth.photoUrl,
            size: 72,
            showBorder: true,
          ),
          const SizedBox(width: AppSpacing.sp16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.displayName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  auth.isTeacher ? 'Docente' : 'Visitante',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightMutedFg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  auth.email,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextDisabled
                        : AppColors.lightMutedFg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── KPI Row ─────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KpiCard(value: '—', label: 'Proyectos', isDark: isDark),
        const SizedBox(width: AppSpacing.sp8),
        _KpiCard(value: '—', label: 'Evaluaciones', isDark: isDark),
        const SizedBox(width: AppSpacing.sp8),
        _KpiCard(value: '—', label: 'Promedio', isDark: isDark),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.value,
    required this.label,
    required this.isDark,
  });
  final String value;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sp12, horizontal: AppSpacing.sp8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface2 : AppColors.lightMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightForeground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightMutedFg,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings Tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.isDark,
    required this.icon,
    required this.title,
    this.trailing,
    this.showArrow = false,
    this.onTap,
  });

  final bool isDark;
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp16, vertical: AppSpacing.sp12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color:
                  isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
            ),
            const SizedBox(width: AppSpacing.sp12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightForeground,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightMutedFg,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
        ),
        const SizedBox(width: AppSpacing.sp8),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: isDark ? AppColors.darkTextDisabled : AppColors.lightMutedFg,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightForeground,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
