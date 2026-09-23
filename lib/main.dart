import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth_service.dart';
import 'core/theme_controller.dart';
import 'screens/main/main_screen.dart';
import 'theme/app_theme.dart';

/// จุดเริ่มต้นของแอป: เชื่อมต่อ Supabase, เตรียม AuthService/ธีมที่จำไว้ แล้วเปิด MainScreen
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://knzngvzjozpahxbpwivv.supabase.co',
    publishableKey: 'sb_publishable_Mdx2V1gYa3VQtFS_WTI33w_xkNZa_kj',
  );

  // สร้าง AuthService ตั้งแต่แอปเริ่มทำงาน เพื่อให้สถานะ login/สิทธิ์ admin
  // พร้อมใช้งานก่อนหน้าแรกจะ build (ไม่ต้องรอผู้ใช้เปิดแท็บบัญชีก่อน)
  AuthService.instance;

  // โหลดโหมดธีม (สว่าง/มืด) ที่ผู้ใช้เคยเลือกไว้จากเครื่อง ก่อนเปิดหน้าแรก
  await ThemeController.instance.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // สลับ ThemeData ทั้งแอปทันทีที่ผู้ใช้เปลี่ยนโหมดธีมในหน้าบัญชี
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Webtoon App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.current,
          home: const MainScreen(),
        );
      },
    );
  }
}
