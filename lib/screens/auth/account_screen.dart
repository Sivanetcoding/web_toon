import 'package:flutter/material.dart';
import 'package:web_toon/core/auth_service.dart';

import '../../theme/app_theme.dart';
import 'login_screen.dart';

/// หน้าบัญชีของฉัน: โชว์สถานะ login/สิทธิ์ admin หรือชวนเข้าสู่ระบบถ้ายังไม่ได้ login
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('บัญชีของฉัน')),
      body: ValueListenableBuilder(
      valueListenable: AuthService.instance.currentUser,
      builder: (context, user, _) {
        if (user == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ยังไม่ได้เข้าสู่ระบบ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'เข้าสู่ระบบเพื่อจัดการบัญชีของคุณ',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('เข้าสู่ระบบ'),
                  ),
                ],
              ),
            ),
          );
        }

        return ValueListenableBuilder<bool>(
          valueListenable: AuthService.instance.isAdmin,
          builder: (context, isAdmin, _) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.surfaceVariant,
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        size: 36,
                        color: isAdmin
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.email ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAdmin ? 'ผู้ดูแลระบบ (Admin)' : 'ผู้ใช้ทั่วไป',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => AuthService.instance.signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('ออกจากระบบ'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      ),
    );
  }
}
