import 'package:flutter/material.dart';

import '../core/theme_controller.dart';

/// สีหลักของแอป จำลองสไตล์เว็บอ่านมันฮวา/เว็บตูน
/// รองรับทั้งธีมมืด (ค่าเริ่มต้นเดิมของแอป) และธีมสว่าง (background ขาว)
/// สลับอัตโนมัติตาม ThemeController.instance.mode ทุกจุดที่เรียกใช้ AppColors.xxx
class AppColors {
  AppColors._();

  static bool get _isLight => ThemeController.instance.mode.value == ThemeMode.light;

  static Color get background => _isLight ? _lightBackground : _darkBackground;
  static Color get surface => _isLight ? _lightSurface : _darkSurface;
  static Color get surfaceVariant =>
      _isLight ? _lightSurfaceVariant : _darkSurfaceVariant;
  static Color get textPrimary => _isLight ? _lightTextPrimary : _darkTextPrimary;
  static Color get textSecondary =>
      _isLight ? _lightTextSecondary : _darkTextSecondary;

  // สีเอกลักษณ์ของแบรนด์ คงเดิมไม่ว่าจะธีมไหน
  static const primary = Color(0xFFFF3D68); // ชมพูแดงสดเป็นสีเอกลักษณ์
  static const secondary = Color(0xFFFFC93C); // เหลืองทองสำหรับยอดวิว/เรตติ้ง
  static const accentGradientStart = Color(0xFFFF3D68);
  static const accentGradientEnd = Color(0xFF7B2FF7);

  // --- ธีมมืด (ของเดิมที่แอปใช้อยู่) ---
  static const _darkBackground = Color(0xFF0E0E14);
  static const _darkSurface = Color(0xFF181822);
  static const _darkSurfaceVariant = Color(0xFF232331);
  static const _darkTextPrimary = Color(0xFFF5F5FA);
  static const _darkTextSecondary = Color(0xFF9C9CB0);

  // --- ธีมสว่าง: background ขาว ---
  static const _lightBackground = Color(0xFFFFFFFF);
  static const _lightSurface = Color(0xFFF7F7FA);
  static const _lightSurfaceVariant = Color(0xFFEDEDF2);
  static const _lightTextPrimary = Color(0xFF1A1A22);
  static const _lightTextSecondary = Color(0xFF6B6B78);
}

class AppTheme {
  AppTheme._();

  static const LinearGradient heroGradient = LinearGradient(
    colors: [AppColors.accentGradientStart, AppColors.accentGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// สร้าง ThemeData ตามโหมดปัจจุบันของ ThemeController เสมอ
  /// (เรียกใหม่ทุกครั้งที่ ThemeController.instance.mode เปลี่ยน ผ่าน ValueListenableBuilder ใน main.dart)
  static ThemeData get current {
    final isLight = ThemeController.instance.mode.value == ThemeMode.light;
    final base = isLight
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true);
    final colorScheme = base.colorScheme.copyWith(
      brightness: isLight ? Brightness.light : Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.surfaceVariant,
        thickness: 1,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}
