import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// จัดการสถานะการเข้าสู่ระบบและสิทธิ์ (admin/user) ไว้ที่เดียว
/// ให้ทุกหน้าฟัง ValueNotifier นี้เพื่อโชว์/ซ่อนปุ่มที่ต้องใช้สิทธิ์ admin
///
/// หมายเหตุ: การซ่อนปุ่มฝั่งแอปเป็นแค่ UX เท่านั้น สิทธิ์จริงต้องถูกบังคับด้วย
/// Row Level Security (RLS) ฝั่ง Supabase เสมอ (ดู supabase/sql/003_admin_write_policies.sql)
class AuthService {
  AuthService._internal() {
    _refreshRole();
    supabase.auth.onAuthStateChange.listen((_) => _refreshRole());
  }

  static final AuthService instance = AuthService._internal();

  final ValueNotifier<User?> currentUser = ValueNotifier<User?>(
    supabase.auth.currentUser,
  );
  final ValueNotifier<bool> isAdmin = ValueNotifier<bool>(false);

  Future<void> _refreshRole() async {
    final user = supabase.auth.currentUser;
    currentUser.value = user;

    if (user == null) {
      isAdmin.value = false;
      return;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      isAdmin.value = profile?['role'] == 'admin';
    } catch (_) {
      // ยังไม่ได้สร้างตาราง profiles หรือดึงข้อมูลไม่สำเร็จ -> ถือว่าไม่ใช่ admin ไว้ก่อน
      isAdmin.value = false;
    }
  }

  Future<void> signIn(String email, String password) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) {
    return supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() {
    return supabase.auth.signOut();
  }
}
