// features/profile/pages/profile_page.dart
// ─────────────────────────────────────────────────────────────────────────────
// Perfil — minimalista, iOS-nativo, edición in-line, redes estilo shadcn/ui
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/micro_interactions.dart';
import '../../auth/domain/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_remote_datasource.dart';
import '../domain/social_type.dart';
import '../widgets/account_settings_card.dart';
import '../widgets/identity_section.dart';
import '../widgets/social_links_group.dart';

// ── Page ─────────────────────────────────────────────────────────────────────

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (auth is! AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // ── Top bar sin título prominente — estilo páginas de ajustes iOS ──────
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // Título muy discreto — la identidad del usuario aporta el contexto
        title: Text(
          'Perfil',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
          ),
        ),
        actions: [
          // ── Toggle tema — discreto, sin tooltip verboso ──────────────
          _ThemeToggleButton(isDark: isDark),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.sp48),
        children: [
          // ── Identidad (avatar + nombre editable + email) ─────────────────
          IdentitySection(
            auth: auth,
            isDark: isDark,
            onPickPhoto: () => _pickAndUploadPhoto(context, ref, auth),
            onSaveName: (name) => _saveName(context, ref, auth, name),
          ),

          const SizedBox(height: AppSpacing.sp28),

          // ── Redes Sociales — lista shadcn-style ──────────────────────────
          _SectionLabel(label: 'Redes sociales', isDark: isDark),
          const SizedBox(height: AppSpacing.sp8),
          SocialLinksGroup(
            socialLinks: auth.socialLinks ?? const {},
            isDark: isDark,
            onEditRequested: (type) => _openSocialSheet(
              context,
              ref,
              auth,
              isDark,
              focused: type,
            ),
          ),

          const SizedBox(height: AppSpacing.sp28),

          _SectionLabel(label: 'Configuración de cuenta', isDark: isDark),
          const SizedBox(height: AppSpacing.sp8),
          AccountSettingsCard(
            isDark: isDark,
            onAccountDeleted: () => context.go('/login'),
          ),

          const SizedBox(height: AppSpacing.sp28),

          // ── Cerrar sesión — acción destructiva sutil ──────────────────────
          _SignOutButton(onPressed: () => _confirmLogout(context, ref)),

          const SizedBox(height: AppSpacing.sp20),

          Center(
            child: Text(
              'Auditoría Hub v1.0.0 · IntegradorHub',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                letterSpacing: 0.1,
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

  // ── Acciones ────────────────────────────────────────────────────────────────

  Future<void> _pickAndUploadPhoto(
      BuildContext context, WidgetRef ref, AuthAuthenticated auth) async {
    await HapticFeedback.lightImpact();
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

  Future<void> _saveName(BuildContext context, WidgetRef ref,
      AuthAuthenticated auth, String name) async {
    if (name.trim().isEmpty || name.trim() == auth.displayName) return;
    await HapticFeedback.lightImpact();
    final ds = ref.read(profileRemoteDatasourceProvider);
    try {
      await ds.updateDisplayName(auth.uid, name.trim());
      ref
          .read(authStateProvider.notifier)
          .updateDisplayNameInState(name.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre actualizado')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el nombre')),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isDark
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
      await HapticFeedback.lightImpact();
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

// ── Theme Toggle Button ───────────────────────────────────────────────────────
// Icono discreto sin fondo ni borde — un solo trazo limpio

class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = isDark
        ? Icons.light_mode_rounded
        : Icons.dark_mode_outlined;
    final color = isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(themeProvider.notifier).toggle();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(icon, key: ValueKey<bool>(isDark), size: 22, color: color),
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp20),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
        ),
      ),
    );
  }
}

// ── Sign Out Button ───────────────────────────────────────────────────────────
// Acción destructiva sutil: texto rojo sin borde, sin fondo pesado.
// Diseño inspirado en iOS Settings "Sign Out" row.

class _SignOutButton extends StatefulWidget {
  const _SignOutButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sp16, horizontal: AppSpacing.sp20),
          decoration: BoxDecoration(
            color:
                _pressed ? AppColors.error.withAlpha(10) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.error.withAlpha(_pressed ? 60 : 40),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.error.withAlpha(_pressed ? 220 : 180),
              ),
              const SizedBox(width: AppSpacing.sp8),
              Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error.withAlpha(_pressed ? 220 : 180),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edit Social Sheet ─────────────────────────────────────────────────────────
// Bottom sheet de edición (abierto desde _SocialLinksGroup cuando vacío
// o con long-press cuando ya tiene un link guardado)

void _openSocialSheet(
  BuildContext context,
  WidgetRef ref,
  AuthAuthenticated auth,
  bool isDark, {
  required SocialType? focused,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditSocialSheet(
      auth: auth,
      isDark: isDark,
      ref: ref,
      focused: focused,
    ),
  );
}

class _EditSocialSheet extends StatefulWidget {
  const _EditSocialSheet({
    required this.auth,
    required this.isDark,
    required this.ref,
    this.focused,
  });

  final AuthAuthenticated auth;
  final bool isDark;
  final WidgetRef ref;
  final SocialType? focused;

  @override
  State<_EditSocialSheet> createState() => _EditSocialSheetState();
}

class _EditSocialSheetState extends State<_EditSocialSheet> {
  late final Map<SocialType, TextEditingController> _ctrls;
  late final Map<SocialType, FocusNode> _focusNodes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final t in SocialType.values)
        t: TextEditingController(text: widget.auth.socialLinks?[t.name] ?? ''),
    };
    _focusNodes = {
      for (final t in SocialType.values) t: FocusNode(),
    };

    if (widget.focused != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[widget.focused!]?.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    for (final f in _focusNodes.values) f.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await HapticFeedback.lightImpact();
    final links = <String, String>{
      for (final entry in _ctrls.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key.name: entry.value.text.trim(),
    };

    setState(() => _saving = true);
    try {
      final ds = widget.ref.read(profileRemoteDatasourceProvider);
      await ds.updateSocial(widget.auth.uid, links);
      widget.ref
          .read(authStateProvider.notifier)
          .updateSocialLinksInState(links);
      if (mounted) {
        await HapticFeedback.selectionClick();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redes sociales actualizadas')),
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
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textMuted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface1 : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.sp20,
        right: AppSpacing.sp20,
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
          const SizedBox(height: AppSpacing.sp20),
          Text(
            'Redes sociales',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sp4),
          Text(
            'Agrega tus links para que aparezcan en tu perfil.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sp24),

          ...SocialType.values.map((type) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sp16),
                child: _SocialField(
                  controller: _ctrls[type]!,
                  focusNode: _focusNodes[type]!,
                  label: type.label,
                  hint: type.hint,
                  icon: type.icon,
                  isDark: isDark,
                ),
              )),

          const SizedBox(height: AppSpacing.sp12),
          SizedBox(
            width: double.infinity,
            child: PressScale(
              enabled: !_saving,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.lightCard, strokeWidth: 2),
                      )
                    : const Text('Guardar cambios'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Social Field ──────────────────────────────────────────────────────────────

class _SocialField extends StatelessWidget {
  const _SocialField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textMuted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sp6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.url,
          autocorrect: false,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: textMuted),
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.full),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.full),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.full),
              borderSide:
                  const BorderSide(color: AppColors.lightPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
