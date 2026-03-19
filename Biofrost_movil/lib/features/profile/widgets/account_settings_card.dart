import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/micro_interactions.dart';
import '../providers/account_settings_controller.dart';

class AccountSettingsCard extends ConsumerStatefulWidget {
  const AccountSettingsCard({
    super.key,
    required this.isDark,
    required this.onAccountDeleted,
  });

  final bool isDark;
  final VoidCallback onAccountDeleted;

  @override
  ConsumerState<AccountSettingsCard> createState() =>
      _AccountSettingsCardState();
}

class _AccountSettingsCardState extends ConsumerState<AccountSettingsCard> {
  bool _publicProfile = true;

  Future<void> _openChangePasswordSheet() async {
    final currentCtrl = TextEditingController();
    final nextCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = widget.isDark;
        final bg = isDark ? AppColors.darkSurface1 : AppColors.lightCard;
        final textPrimary =
            isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
        final textMuted =
            isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            final ctrlState = ref.watch(accountSettingsControllerProvider);

            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
              ),
              padding: EdgeInsets.only(
                left: AppSpacing.sp20,
                right: AppSpacing.sp20,
                top: AppSpacing.sp16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.sp28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp20),
                  Text(
                    'Cambiar contraseña',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verifica tu identidad antes de actualizar tu clave.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp16),
                  _SecureField(
                    controller: currentCtrl,
                    label: 'Contrasena actual',
                    hint: 'Ingresa tu contrasena actual',
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.sp12),
                  _SecureField(
                    controller: nextCtrl,
                    label: 'Nueva contrasena',
                    hint: 'Minimo 10 caracteres con complejidad',
                    isDark: isDark,
                  ),
                  if (ctrlState.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.sp10),
                    Text(
                      ctrlState.errorMessage!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.error.withAlpha(200),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sp16),
                  SizedBox(
                    width: double.infinity,
                    child: PressScale(
                      enabled: !ctrlState.isLoading,
                      child: ElevatedButton(
                        onPressed: ctrlState.isLoading
                            ? null
                            : () async {
                                await HapticFeedback.lightImpact();
                                ref
                                    .read(accountSettingsControllerProvider
                                        .notifier)
                                    .clearMessages();

                                final success = await ref
                                    .read(accountSettingsControllerProvider
                                        .notifier)
                                    .changePassword(
                                      currentPassword: currentCtrl.text,
                                      newPassword: nextCtrl.text,
                                    );

                                if (!mounted) return;
                                if (success) {
                                  await HapticFeedback.selectionClick();
                                  Navigator.of(sheetContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Contrasena actualizada correctamente',
                                      ),
                                    ),
                                  );
                                } else {
                                  setLocalState(() {});
                                }
                              },
                        child: ctrlState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: AppColors.lightCard,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar contrasena'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    currentCtrl.dispose();
    nextCtrl.dispose();
  }

  Future<void> _startDeleteFlow() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Esta accion desactivara tu cuenta y perderas acceso a tus datos. '
          'Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Continuar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (approved != true || !mounted) return;

    final passwordCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = widget.isDark;
        final bg = isDark ? AppColors.darkSurface1 : AppColors.lightCard;
        final textPrimary =
            isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
        final textMuted =
            isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            final ctrlState = ref.watch(accountSettingsControllerProvider);

            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
              ),
              padding: EdgeInsets.only(
                left: AppSpacing.sp20,
                right: AppSpacing.sp20,
                top: AppSpacing.sp16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.sp28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirmar eliminacion',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ingresa tu contrasena actual para finalizar.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp16),
                  _SecureField(
                    controller: passwordCtrl,
                    label: 'Contrasena actual',
                    hint: 'Confirma tu contrasena',
                    isDark: isDark,
                  ),
                  if (ctrlState.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.sp10),
                    Text(
                      ctrlState.errorMessage!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.error.withAlpha(200),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sp16),
                  SizedBox(
                    width: double.infinity,
                    child: PressScale(
                      enabled: !ctrlState.isLoading,
                      child: ElevatedButton(
                        onPressed: ctrlState.isLoading
                            ? null
                            : () async {
                                await HapticFeedback.lightImpact();
                                ref
                                    .read(accountSettingsControllerProvider
                                        .notifier)
                                    .clearMessages();

                                final success = await ref
                                    .read(accountSettingsControllerProvider
                                        .notifier)
                                    .deleteAccountWithVerification(
                                      currentPassword: passwordCtrl.text,
                                    );

                                if (!mounted) return;
                                if (success) {
                                  await HapticFeedback.selectionClick();
                                  Navigator.of(sheetContext).pop();
                                  widget.onAccountDeleted();
                                } else {
                                  setLocalState(() {});
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: ctrlState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: AppColors.lightCard,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Eliminar definitivamente'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    passwordCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgCard = isDark ? AppColors.darkSurface1 : AppColors.lightCard;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textMuted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;
    final dividerColor = isDark
        ? AppColors.darkBorder.withAlpha(100)
        : AppColors.lightBorder.withAlpha(150);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 28 : 9),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            children: [
              _AccountTile(
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.lightOlive,
                title: 'Cambiar contrasena',
                titleColor: textPrimary,
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: textMuted,
                ),
                onTap: _openChangePasswordSheet,
              ),
              Divider(
                height: 0.5,
                thickness: 0.5,
                color: dividerColor,
                indent: AppSpacing.sp62,
              ),
              _AccountTile(
                icon: Icons.visibility_outlined,
                iconColor: AppColors.lightOlive,
                title: 'Perfil Publico',
                titleColor: textPrimary,
                trailing: Switch.adaptive(
                  value: _publicProfile,
                  activeColor: AppColors.lightPrimary,
                  onChanged: (value) {
                    setState(() => _publicProfile = value);
                  },
                ),
              ),
              Divider(
                height: 0.5,
                thickness: 0.5,
                color: dividerColor,
                indent: AppSpacing.sp62,
              ),
              _AccountTile(
                icon: Icons.delete_outline_rounded,
                iconColor: AppColors.error.withAlpha(180),
                title: 'Eliminar cuenta',
                titleColor: AppColors.error.withAlpha(180),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: textMuted,
                ),
                onTap: _startDeleteFlow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecureField extends StatelessWidget {
  const _SecureField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.isDark,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
          obscureText: true,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor:
                isDark ? AppColors.darkSurface2 : AppColors.lightBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide:
                  const BorderSide(color: AppColors.lightPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp16,
        vertical: AppSpacing.sp8,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      splashColor: AppColors.lightPrimary.withAlpha(12),
      highlightColor: AppColors.lightPrimary.withAlpha(8),
      child: row,
    );
  }
}
