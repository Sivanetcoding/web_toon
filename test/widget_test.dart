import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_toon/screens/team/team_screen.dart';
import 'package:web_toon/theme/app_theme.dart';

void main() {
  // ใช้ TeamScreen แทนหน้าแรกของแอป เพราะหน้าแรก/MyApp ต้องพึ่ง Supabase
  // ที่ initialize และมีเน็ตเวิร์กจริง ซึ่ง widget test ไม่ควรพึ่งพา
  testWidgets('TeamScreen แสดงชื่อแอปและรายชื่อสมาชิกกลุ่ม', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.current, home: const TeamScreen()),
    );
    await tester.pump();

    expect(find.text('Webtoon App'), findsOneWidget);
    expect(find.text('รหัสนักศึกษา 6721652692'), findsOneWidget);
    expect(find.text('รหัสนักศึกษา 6721652650'), findsOneWidget);
  });
}
