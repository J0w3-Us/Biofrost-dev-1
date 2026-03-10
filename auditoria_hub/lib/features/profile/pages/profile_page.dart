// features/profile/pages/profile_page.dart — Pantalla de perfil (Biofrost)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/domain/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_remote_datasource.dart';

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
        title: const Text('Mi Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.sp40),
        children: [
          // ── Header ──────────────────────────────────────────────────
          _ProfileHeader(
            auth: auth,
            isDark: isDark,
            onPickPhoto: () => _pickAndUploadPhoto(context, ref, auth),
          ),

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
            onTap: () => _showEditProfileSheet(context, ref, auth, isDark),
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
                    value: _capitalize(auth.role),
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

  Future<void> _pickAndUploadPhoto(
      BuildContext context, WidgetRef ref, AuthAuthenticated auth) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !context.mounted) return;

    final ds = ref.read(profileRemoteDatasourceProvider);
    try {
      final url = await ds.uploadImage(picked);
      await ds.updatePhoto(auth.uid, url);
      ref.read(authStateProvider.notifier).updatePhotoInState(url);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir la foto')),
        );
      }
    }
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref,
      AuthAuthenticated auth, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(auth: auth, isDark: isDark, ref: ref),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
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
  const _ProfileHeader({
    required this.auth,
    required this.isDark,
    required this.onPickPhoto,
  });
  final AuthAuthenticated auth;
  final bool isDark;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurface1, AppColors.darkSurface0]
              : [AppColors.lightCard, AppColors.lightMuted],
        ),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp16, vertical: AppSpacing.sp24),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPickPhoto,
            child: Stack(
              children: [
                UserAvatar(
                  name: auth.displayName,
                  imageUrl: auth.photoUrl,
                  size: 72,
                  showBorder: true,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkSurface0
                            : AppColors.lightBackground,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
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

// ── Edit Profile Bottom Sheet ─────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.auth,
    required this.isDark,
    required this.ref,
  });
  final AuthAuthenticated auth;
  final bool isDark;
  final WidgetRef ref;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _linkedinCtrl;
  late final TextEditingController _githubCtrl;
  late final TextEditingController _websiteCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _linkedinCtrl = TextEditingController();
    _githubCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _linkedinCtrl.dispose();
    _githubCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final links = <String, String>{};
    if (_linkedinCtrl.text.trim().isNotEmpty) {
      links['linkedin'] = _linkedinCtrl.text.trim();
    }
    if (_githubCtrl.text.trim().isNotEmpty) {
      links['github'] = _githubCtrl.text.trim();
    }
    if (_websiteCtrl.text.trim().isNotEmpty) {
      links['website'] = _websiteCtrl.text.trim();
    }

    setState(() => _saving = true);
    try {
      final ds = widget.ref.read(profileRemoteDatasourceProvider);
      await ds.updateSocial(widget.auth.uid, links);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar los cambios')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface1 : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.sp16,
        right: AppSpacing.sp16,
        top: AppSpacing.sp16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.sp32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp16),
          Text(
            'Editar perfil',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.sp8),
          Text(
            'Actualiza tus redes sociales para que aparezcan en tu perfil público.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color:
                  isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
            ),
          ),
          const SizedBox(height: AppSpacing.sp20),
          _SocialField(
            controller: _linkedinCtrl,
            label: 'LinkedIn',
            hint: 'https://linkedin.com/in/usuario',
            icon: Icons.link_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sp12),
          _SocialField(
            controller: _githubCtrl,
            label: 'GitHub',
            hint: 'https://github.com/usuario',
            icon: Icons.code_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sp12),
          _SocialField(
            controller: _websiteCtrl,
            label: 'Sitio web',
            hint: 'https://mi-sitio.com',
            icon: Icons.language_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sp24),
          BioButton(
            label: 'Guardar cambios',
            onPressed: _saving ? null : _save,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}

class _SocialField extends StatelessWidget {
  const _SocialField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          autocorrect: false,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightForeground,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon,
                size: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightMutedFg),
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color:
                  isDark ? AppColors.darkTextDisabled : AppColors.lightMutedFg,
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface2 : AppColors.lightMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp12, vertical: AppSpacing.sp12),
          ),
        ),
      ],
    );
  }
}
