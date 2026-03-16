import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../auth/domain/models/auth_state.dart';

class IdentitySection extends StatefulWidget {
  const IdentitySection({
    super.key,
    required this.auth,
    required this.isDark,
    required this.onPickPhoto,
    required this.onSaveName,
  });

  final AuthAuthenticated auth;
  final bool isDark;
  final VoidCallback onPickPhoto;
  final ValueChanged<String> onSaveName;

  @override
  State<IdentitySection> createState() => _IdentitySectionState();
}

class _IdentitySectionState extends State<IdentitySection> {
  bool _editingName = false;
  late final TextEditingController _nameCtrl;
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.auth.displayName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() => _editingName = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
      _nameCtrl.selection =
          TextSelection(baseOffset: 0, extentOffset: _nameCtrl.text.length);
    });
  }

  void _commitEdit() {
    setState(() => _editingName = false);
    widget.onSaveName(_nameCtrl.text);
  }

  void _cancelEdit() {
    setState(() {
      _editingName = false;
      _nameCtrl.text = widget.auth.displayName;
    });
    _nameFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textMuted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;
    final bgCard = isDark ? AppColors.darkSurface1 : AppColors.lightCard;

    return Container(
      color: bgCard,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp20, vertical: AppSpacing.sp28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _EditableAvatar(
            auth: widget.auth,
            isDark: isDark,
            onTap: widget.onPickPhoto,
          ),
          const SizedBox(width: AppSpacing.sp20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_editingName)
                  _InlineNameField(
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    isDark: isDark,
                    onSubmit: _commitEdit,
                    onCancel: _cancelEdit,
                  )
                else
                  _TappableName(
                    name: widget.auth.displayName,
                    textColor: textPrimary,
                    onTap: _startEdit,
                  ),
                const SizedBox(height: 3),
                Text(
                  widget.auth.email,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.auth.role,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableAvatar extends StatefulWidget {
  const _EditableAvatar({
    required this.auth,
    required this.isDark,
    required this.onTap,
  });

  final AuthAuthenticated auth;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_EditableAvatar> createState() => _EditableAvatarState();
}

class _EditableAvatarState extends State<_EditableAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) {
        _anim.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatar(
              name: widget.auth.displayName,
              imageUrl: widget.auth.photoUrl,
              size: 76,
              showBorder: true,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isDark
                        ? AppColors.darkSurface1
                        : AppColors.lightCard,
                    width: 2.5,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 13,
                  color: AppColors.lightCard,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TappableName extends StatefulWidget {
  const _TappableName({
    required this.name,
    required this.textColor,
    required this.onTap,
  });

  final String name;
  final Color textColor;
  final VoidCallback onTap;

  @override
  State<_TappableName> createState() => _TappableNameState();
}

class _TappableNameState extends State<_TappableName> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.5 : 1,
        duration: const Duration(milliseconds: 80),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                widget.name,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: widget.textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.edit_rounded,
              size: 14,
              color: AppColors.lightMutedFg,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineNameField extends StatelessWidget {
  const _InlineNameField({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: textPrimary,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.only(bottom: 3),
              border: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.lightPrimary, width: 1.5),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.lightPrimary, width: 1.5),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.lightPrimary, width: 1.5),
              ),
              filled: false,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
          ),
        ),
        GestureDetector(
          onTap: onCancel,
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.lightMutedFg,
            ),
          ),
        ),
      ],
    );
  }
}
