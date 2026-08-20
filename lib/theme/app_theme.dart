import 'package:flutter/material.dart';

class AppTheme {
  static const _radius = 8.0;
  static const _fontFallback = <String>[
    'SF Pro Text',
    'Segoe UI',
    'Roboto',
    'Noto Sans SC',
    'PingFang SC',
    'Microsoft YaHei',
    'sans-serif',
  ];

  static ThemeData get light => _build(
    brightness: Brightness.light,
    scaffold: Colors.white,
    surface: Colors.white,
    surfaceSoft: const Color(0xFFF1F2F0),
    surfaceMuted: const Color(0xFFE8E9E6),
    onSurface: const Color(0xFF1F2328),
    onMuted: const Color(0xFF687076),
    border: const Color(0xFFDADDD8),
    primary: const Color(0xFF111827),
    accent: const Color(0xFF2563EB),
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scaffold: const Color(0xFF171717),
    surface: const Color(0xFF1F1F1F),
    surfaceSoft: const Color(0xFF272727),
    surfaceMuted: const Color(0xFF303030),
    onSurface: const Color(0xFFEDEDED),
    onMuted: const Color(0xFFA3A3A3),
    border: const Color(0xFF3A3A3A),
    primary: const Color(0xFFEDEDED),
    accent: const Color(0xFF7AA2FF),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color surfaceSoft,
    required Color surfaceMuted,
    required Color onSurface,
    required Color onMuted,
    required Color border,
    required Color primary,
    required Color accent,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? const Color(0xFF111111) : Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerLowest: scaffold,
      surfaceContainerLow: surface,
      surfaceContainer: surfaceSoft,
      surfaceContainerHigh: surfaceMuted,
      surfaceContainerHighest: surfaceMuted,
      outline: border,
      outlineVariant: border.withValues(alpha: isDark ? 0.65 : 0.75),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? Colors.white : const Color(0xFF1F2328),
      onInverseSurface: isDark ? const Color(0xFF1F2328) : Colors.white,
      inversePrimary: accent,
      surfaceTint: Colors.transparent,
    );

    final textTheme = _textTheme(onSurface, onMuted);
    final baseButtonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      cardColor: surface,
      dividerColor: border,
      primaryColor: primary,
      fontFamilyFallback: _fontFallback,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: onMuted, size: 18),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: onMuted, size: 18),
        actionsIconTheme: IconThemeData(color: onMuted, size: 18),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hoverColor: surfaceSoft,
        isDense: true,
        hintStyle: textTheme.bodyMedium?.copyWith(color: onMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: onMuted),
        prefixIconColor: onMuted,
        suffixIconColor: onMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: accent, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? const Color(0xFF111111) : Colors.white,
          disabledBackgroundColor: surfaceMuted,
          disabledForegroundColor: onMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: baseButtonShape,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? const Color(0xFF111111) : Colors.white,
          disabledBackgroundColor: surfaceMuted,
          disabledForegroundColor: onMuted,
          shape: baseButtonShape,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          disabledForegroundColor: onMuted,
          side: BorderSide(color: border),
          shape: baseButtonShape,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: onSurface,
          disabledForegroundColor: onMuted,
          shape: baseButtonShape,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onMuted,
          disabledForegroundColor: onMuted.withValues(alpha: 0.35),
          hoverColor: surfaceMuted,
          highlightColor: surfaceMuted,
          shape: baseButtonShape,
          minimumSize: const Size.square(32),
          fixedSize: const Size.square(32),
          padding: EdgeInsets.zero,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 18,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: border),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: onSurface),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        textStyle: textTheme.bodyMedium?.copyWith(color: onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
      ),
      drawerTheme: DrawerThemeData(
        elevation: 0,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: Border(right: BorderSide(color: border)),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(baseButtonShape),
          elevation: const WidgetStatePropertyAll(8),
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        iconColor: onMuted,
        textColor: onSurface,
        titleTextStyle: textTheme.bodyMedium?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: onMuted),
        shape: baseButtonShape,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFFEDEDED) : const Color(0xFF1F2328),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(
          color: isDark ? const Color(0xFF111111) : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        waitDuration: const Duration(milliseconds: 350),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : onMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primary.withValues(alpha: 0.35)
                  : surfaceMuted,
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color onSurface, Color onMuted) {
    const letterSpacing = 0.0;
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: letterSpacing,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: letterSpacing,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: letterSpacing,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: letterSpacing,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: letterSpacing,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.55,
        letterSpacing: letterSpacing,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: letterSpacing,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: letterSpacing,
        color: onMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: letterSpacing,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: letterSpacing,
        color: onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: letterSpacing,
        color: onMuted,
      ),
    );
  }
}
