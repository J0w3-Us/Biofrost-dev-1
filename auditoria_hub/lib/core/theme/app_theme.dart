// core/theme/app_theme.dart — Design system Biofrost (Apple HIG inspired)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _fontFamily = 'Inter';

// ── Colores — Paleta iOS/Apple refinada ────────────────────────────────────

abstract class AppColors {
  // ── Dark mode — Apple Dark palette ────────────────────────────────────
  static const darkSurface0 = Color(0xFF000000); // Pure black (OLED)
  static const darkSurface1 = Color(0xFF1C1C1E); // iOS card surface
  static const darkSurface2 = Color(0xFF2C2C2E); // iOS grouped row
  static const darkSurface3 = Color(0xFF3A3A3C); // iOS elevated surface

  static const darkBorder = Color(0xFF38383A); // Subtle separator
  static const darkBorderFocus = Color(0xFF0A84FF); // iOS blue focus ring

  static const darkPrimary = Color(0xFFFFFFFF); // White primary
  static const darkAccent = Color(0xFF0A84FF); // iOS Blue

  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFF8E8E93); // iOS secondary label
  static const darkTextDisabled = Color(0xFF48484A); // iOS tertiary label
  static const darkTextInverse = Color(0xFF000000);

  static const darkSuccess = Color(0xFF30D158); // iOS Green
  static const darkError = Color(0xFFFF453A); // iOS Red
  static const darkWarning = Color(0xFFFF9F0A); // iOS Orange
  static const darkInfo = Color(0xFF0A84FF); // iOS Blue

  // Badge bg colors
  static const badgeActiveBg = Color(0xFF0A2F1A);
  static const badgeCompletoBg = Color(0xFF001A3D);
  static const badgeBorradorBg = Color(0xFF2C2C2E);

  // Podium colors
  static const podiumGold = Color(0xFFFFD60A); // iOS Yellow
  static const podiumSilver = Color(0xFF8E8E93); // iOS Gray
  static const podiumBronze = Color(0xFFBF5AF2); // iOS Purple (distinctive)

  // ── Biofrost Brand Palette ────────────────────────────────────────────
  static const brandCream = Color(0xFFF2F2F7); // Apple light background
  static const brandSlate = Color(0xFFC7C7CC); // Apple separator
  static const brandNavy = Color(0xFF1C1C1E); // Apple label

  // ── Light mode — Biofrost Green palette ────────────────────────────────
  static const lightBackground = Color(0xFFE4E3D9); // Warm beige scaffold
  static const lightForeground = Color(0xFF1C1C1E); // iOS label — unchanged
  static const lightCard = Color(0xFFFFFFFF); // Pure white surface
  static const lightPrimary = Color(0xFF02790A); // Vibrant green — primary CTA
  static const lightAccent =
      Color(0xFF02790A); // Vibrant green — unified action
  static const lightOlive =
      Color(0xFF7A794E); // Olive green — secondary/support
  static const lightSecondary = Color(0xFFE5E5EA); // iOS fill tertiary
  static const lightMuted = Color(0xFFEFEFF4); // iOS grouped background
  static const lightMutedFg = Color(0xFF8E8E93); // iOS secondary label
  static const lightBorder = Color(0xFFD4D3CA); // Warm-tinted separator
  static const lightInput = Color(0xFFDDDCD4); // Warm input fill
  static const lightSidebar = Color(0xFF1C1C1E); // dark nav
  static const lightDestructive = Color(0xFFFF3B30); // iOS Red

  // ── Shared ─────────────────────────────────────────────────────────────
  static const success = Color(0xFF30D158); // iOS Green
  static const error = Color(0xFFFF3B30); // iOS Red
  static const warning = Color(0xFFFF9F0A); // iOS Orange
  static const info = Color(0xFF0A84FF); // iOS Blue
}

// ── Espaciado y Radios — Apple style ───────────────────────────────────────

abstract class AppSpacing {
  static const sp2 = 2.0;
  static const sp4 = 4.0;
  static const sp6 = 6.0;
  static const sp8 = 8.0;
  static const sp10 = 10.0;
  static const sp12 = 12.0;
  static const sp13 = 13.0;
  static const sp14 = 14.0;
  static const sp16 = 16.0;
  static const sp20 = 20.0;
  static const sp24 = 24.0;
  static const sp28 = 28.0;
  static const sp32 = 32.0;
  static const sp40 = 40.0;
  static const sp48 = 48.0;
  static const sp52 = 52.0;
  static const sp62 = 62.0;
  static const sp64 = 64.0;
}

abstract class AppRadius {
  static const xs = 8.0; // Small pills, tiny chips - Slightly softer
  static const sm = 12.0; // Input fields - Softer inputs
  static const md = 16.0; // Cards - Apple squircle standard
  static const lg = 24.0; // Large cards, inner panels
  static const xl = 32.0; // Hero sections, bottom sheets
  static const xxl = 40.0; // Modals, extreme smooth panels
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
          letterSpacing: -0.8,
          color: primaryColor),
      headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: primaryColor),
      headlineSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: primaryColor),
      titleLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
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
          letterSpacing: 0.3,
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
          onSecondary: Colors.white,
          surface: AppColors.darkSurface1,
          onSurface: AppColors.darkTextPrimary,
          error: AppColors.darkError,
          onError: Colors.white,
          surfaceContainerHighest: AppColors.darkSurface2,
          outline: AppColors.darkBorder,
          outlineVariant: AppColors.darkTextSecondary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          secondaryContainer: AppColors.darkSurface2,
        ),
        scaffoldBackgroundColor: AppColors.darkSurface0,
        textTheme: _buildTextTheme(
            AppColors.darkTextPrimary, AppColors.darkTextSecondary),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: AppColors.darkSurface0,
          foregroundColor: AppColors.darkTextPrimary,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.darkTextPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.darkBorder, width: 0.5),
          ),
          color: AppColors.darkSurface1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface2,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: Colors.transparent),
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
          prefixIconColor: AppColors.darkTextSecondary,
          suffixIconColor: AppColors.darkTextSecondary,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder,
          thickness: 0.5,
          space: 0,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return AppColors.darkTextSecondary;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected))
              return AppColors.darkAccent;
            return AppColors.darkSurface3;
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkSurface2,
          contentTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
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
          ),
          titleTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTextPrimary,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkSurface1,
          selectedItemColor: AppColors.darkAccent,
          unselectedItemColor: AppColors.darkTextSecondary,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: _fontFamily,
        colorScheme: const ColorScheme.light(
          brightness: Brightness.light,
          primary: AppColors.lightPrimary, // Vibrant green
          onPrimary: Colors.white,
          secondary: AppColors.lightOlive, // Olive green
          onSecondary: Colors.white,
          surface: AppColors.lightCard, // Pure white
          onSurface: AppColors.lightForeground, // Very dark grey
          error: AppColors.lightDestructive,
          outline: AppColors.lightBorder,
          onSurfaceVariant: AppColors.lightMutedFg,
          surfaceContainerHighest: AppColors.lightMuted,
          secondaryContainer: AppColors.lightSecondary,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground, // Warm beige
        textTheme:
            _buildTextTheme(AppColors.lightForeground, AppColors.lightMutedFg),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.lightBackground, // Matches scaffold
          foregroundColor: AppColors.lightForeground,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.lightForeground,
          ),
        ),
        cardTheme: CardThemeData(
          // No border — depth via shadow only
          elevation: 4,
          shadowColor: Color(0x1A000000), // ~10% black, crisp on beige
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          ),
          color: AppColors.lightCard,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          // Pure white fill — search bar stands out cleanly against beige scaffold
          fillColor: AppColors.lightCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            borderSide: const BorderSide(
                color: AppColors.lightPrimary, width: 1.5), // Green focus
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: const BorderSide(color: AppColors.lightDestructive),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide:
                const BorderSide(color: AppColors.lightDestructive, width: 1.5),
          ),
          hintStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontSize: 15,
              color: AppColors.lightMutedFg),
          prefixIconColor: AppColors.lightMutedFg,
          suffixIconColor: AppColors.lightMutedFg,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.lightBorder,
          thickness: 0.5,
          space: 0,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return Colors.white;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected))
              return AppColors.lightPrimary; // Green track
            return AppColors.lightSecondary;
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.lightForeground,
          contentTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.lightForeground,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.lightCard, // Solid white — no translucency
          selectedItemColor: AppColors.lightPrimary, // Vibrant green
          unselectedItemColor: AppColors.lightMutedFg,
          elevation: 12,
          type: BottomNavigationBarType.fixed,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.lightCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
        ),
      );
}
