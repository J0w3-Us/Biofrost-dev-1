// core/widgets/form_label.dart — Etiqueta reutilizable para campos de formulario
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Etiqueta de campo de formulario estilo Biofrost.
/// Reemplaza la clase _FieldLabel duplicada en login y register.
class FormLabel extends StatelessWidget {
  const FormLabel(this.text, {super.key, bool isDark = false});
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
      ),
    );
  }
}
