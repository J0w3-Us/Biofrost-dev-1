// core/theme/app_theme.dart — Design system Biofrost (Material 3 + Inter)
import 'package:flutter/material.dart';

const _fontFamily = 'Inter';

// ── Colores ────────────────────────────────────────────────────────────────

abstract class AppColors {
  // ── Dark mode (shadcn/zinc palette — oklch dark) ──────────────────────
  static const darkSurface0 = Color(0xFF090606); // background — near-black warm
  static const darkSurface1 = Color(0xFF1E1E24); // card / navbar surface
  static const darkSurface2 =
      Color(0xFF3F3F46); // muted / input fill  (zinc-700)
  static const darkSurface3 =
      Color(0xFF52525B); // hover / disabled btn (zinc-600)

  static const darkBorder = Color(0xFF3F3F46); // same as muted
  static const darkBorderFocus = Color(0xFFFAFAFA); // white ring (primary)

  static const darkPrimary = Color(0xFFFAFAFA); // near-white primary
  static const darkAccent = Color(0xFFA1A1AA); // zinc-400

  static const darkTextPrimary = Color(0xFFFAFAFA);
  static const darkTextSecondary = Color(0xFFA1A1AA); // zinc-400
  static const darkTextDisabled = Color(0xFF71717A); // zinc-500
  static const darkTextInverse = Color(0xFF09090B); // near-black

  static const darkSuccess = Color(0xFF34C759);
  static const darkError = Color(0xFFEE4443);
  static const darkWarning = Color(0xFFFF9F0A);
  static const darkInfo = Color(0xFF0A84FF);

  // Badge bg colors
  static const badgeActiveBg = Color(0xFF14281C);
  static const badgeCompletoBg = Color(0xFF0A1628);
  static const badgeBorradorBg = Color(0xFF1E1E24);

  // Podium colors (unchanged)
  static const podiumGold = Color(0xFFD4AF37);
  static const podiumSilver = Color(0xFF9E9E9E);
  static const podiumBronze = Color(0xFFCD7F32);

  // ── Light mode (shadcn/zinc palette — oklch light) ────────────────────
  static const lightBackground = Color(0xFFF7F2F2); // warm off-white bg
  static const lightForeground = Color(0xFF363738); // dark charcoal text
  static const lightCard = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFF4442D1); // vivid indigo
  static const lightSecondary = Color(0xFFE1E1E1); // light gray
  static const lightMuted = Color(0xFFE2E2E4); // barely-tinted cool gray
  static const lightMutedFg = Color(0xFF6E6F78); // medium muted text
  static const lightAccent = Color(0xFFE2E2E4);
  static const lightBorder = Color(0xFFE2E2E4);
  static const lightInput = Color(0xFFE2E2E4);
  static const lightSidebar =
      Color(0xFF09090B); // dark bottom nav in light mode
  static const lightDestructive = Color(0xFFEE4443);

  // ── Shared ─────────────────────────────────────────────────────────────
  static const success = Color(0xFF34C759);
  static const error = Color(0xFFEE4443);
  static const warning = Color(0xFFFF9F0A);
  static const info = Color(0xFF0A84FF);
}

// ── Espaciado y radios ─────────────────────────────────────────────────────

abstract class AppSpacing {
  static const sp2 = 2.0;
  static const sp4 = 4.0;
  static const sp6 = 6.0;
  static const sp8 = 8.0;
  static const sp10 = 10.0;
  static const sp12 = 12.0;
  static const sp14 = 14.0;
  static const sp16 = 16.0;
  static const sp20 = 20.0;
  static const sp24 = 24.0;
  static const sp32 = 32.0;
  static const sp40 = 40.0;
  static const sp48 = 48.0;
}

abstract class AppRadius {
  // Based on --radius: 0.25rem (4px) from Tailwind theme
  static const xs = 2.0; // radius-sm  ≈ 0px → min 2
  static const sm = 4.0; // radius-lg  = 0.25rem
  static const md = 6.0; // intermediate
  static const lg = 8.0; // radius-xl  = 0.25rem + 4px
  static const xl = 12.0; // 0.25rem + 8px
  static const full = 999.0;
}

// ── Tema ──────────────────────────────────────────────────────────────────

abstract class AppTheme {
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 57,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          color: primaryColor),
      displayMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          color: primaryColor),
      displaySmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 36,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: primaryColor),
      headlineLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: primaryColor),
      headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: primaryColor),
      headlineSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: primaryColor),
      titleLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: primaryColor),
      titleMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
          color: primaryColor),
      titleSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: primaryColor),
      bodyLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: primaryColor),
      bodyMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: primaryColor),
      bodySmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: secondaryColor),
      labelLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: primaryColor),
      labelMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondaryColor),
      labelSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: secondaryColor),
    );
  }

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: _fontFamily,
        colorScheme: const ColorScheme.dark(
          brightness: Brightness.dark,
          primary: AppColors.darkPrimary,
          onPrimary: AppColors.darkTextInverse,
          secondary: AppColors.darkAccent,
          onSecondary: AppColors.darkTextInverse,
          surface: AppColors.darkSurface1,
          onSurface: AppColors.darkTextPrimary,
          error: AppColors.darkError,
          onError: AppColors.darkTextPrimary,
          surfaceContainerHighest: AppColors.darkSurface2,
          outline: AppColors.darkBorder,
          outlineVariant:
              AppColors.darkTextSecondary, // zinc-400 for subtle borders
          onSurfaceVariant: AppColors.darkTextSecondary,
          secondaryContainer: AppColors.darkSurface2,
        ),
        scaffoldBackgroundColor: AppColors.darkSurface0,
        textTheme: _buildTextTheme(
            AppColors.darkTextPrimary, AppColors.darkTextSecondary),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.darkSurface0,
          foregroundColor: AppColors.darkTextPrimary,
          titleTextStyle: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.darkTextPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.darkBorder, width: 1),
          ),
          color: AppColors.darkSurface1,
          shadowColor: Colors.black26,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface2,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide:
                const BorderSide(color: AppColors.darkBorderFocus, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.darkError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide:
                const BorderSide(color: AppColors.darkError, width: 1.5),
          ),
          hintStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontSize: 15,
              color: AppColors.darkTextDisabled),
          prefixIconColor: AppColors.darkTextDisabled,
          suffixIconColor: AppColors.darkTextDisabled,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder,
          thickness: 1,
          space: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkSurface2,
          contentTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: AppColors.darkTextPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.darkSurface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.darkBorder),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTextPrimary,
          ),
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: _fontFamily,
        colorScheme: const ColorScheme.light(
          brightness: Brightness.light,
          primary: AppColors.lightPrimary,
          onPrimary: Colors.white,
          secondary: AppColors.lightAccent,
          surface: AppColors.lightCard,
          onSurface: AppColors.lightForeground,
          error: AppColors.lightDestructive,
          outline: AppColors.lightBorder,
          onSurfaceVariant: AppColors.lightMutedFg,
          surfaceContainerHighest: AppColors.lightMuted,
          secondaryContainer: AppColors.lightSecondary,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        textTheme:
            _buildTextTheme(AppColors.lightForeground, AppColors.lightMutedFg),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.lightBackground,
          foregroundColor: AppColors.lightForeground,
          titleTextStyle: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.lightForeground,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.lightBorder, width: 1),
          ),
          color: AppColors.lightCard,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightInput,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide:
                const BorderSide(color: AppColors.lightPrimary, width: 1.5),
          ),
          hintStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontSize: 15,
              color: AppColors.lightMutedFg),
          prefixIconColor: AppColors.lightMutedFg,
          suffixIconColor: AppColors.lightMutedFg,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.lightBorder,
          thickness: 1,
          space: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.lightBorder),
          ),
        ),
      );
}
