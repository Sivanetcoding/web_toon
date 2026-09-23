//สำหรับพาผู้ใช้กลับหน้าหลักและล้างหน้าที่เปิดค้างอยู่ครับ
import 'package:flutter/material.dart';
import 'package:web_toon/screens/main/main_screen.dart';

void goToHome(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MainScreen()),
    (route) => false,
  );
}
