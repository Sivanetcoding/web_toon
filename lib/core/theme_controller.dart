import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// จัดการโหมดธีม (สว่าง/มืด) ของทั้งแอปไว้ที่เดียว
/// ค่าเริ่มต้นเป็นธีมมืด (ของเดิมที่แอปใช้อยู่) และจำค่าที่ผู้ใช้เลือกไว้ผ่าน SharedPreferences
class ThemeController {
  ThemeController._internal();

  static final ThemeController instance = ThemeController._internal();

  static const _prefsKey = 'is_light_theme';

  final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
    ThemeMode.dark,
  );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isLight = prefs.getBool(_prefsKey) ?? false;
    mode.value = isLight ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setLight(bool isLight) async {
    mode.value = isLight ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, isLight);
  }
}
