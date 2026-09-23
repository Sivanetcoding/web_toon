import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_client.dart';

/// จัดการรายการโปรด (ผูกกับบัญชีผู้ใช้ผ่าน Supabase) และประวัติการอ่านล่าสุด (เก็บในเครื่องผ่าน SharedPreferences)
class LibraryService {
  static const _recentKey = 'recent_chapters';

  // --- รายการโปรด: ผูกกับบัญชีผู้ใช้ผ่าน Supabase (คนละบัญชีเห็นคนละรายการ) ---
  // ต้อง login ก่อนถึงจะกด/ดูรายการโปรดได้ ดู supabase/sql/004_favorites_table.sql

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await supabase
        .from('favorites')
        .select('comics(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row['comics'] as Map))
        .toList();
  }

  static Future<bool> isFavorite(String comicId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final row = await supabase
        .from('favorites')
        .select('comic_id')
        .eq('user_id', userId)
        .eq('comic_id', comicId)
        .maybeSingle();
    return row != null;
  }

  /// โยน StateError ถ้ายังไม่ได้ login (ให้ฝั่ง UI ดักจับไปแจ้งเตือนผู้ใช้)
  static Future<void> toggleFavorite(Map<String, dynamic> comic) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('ต้องเข้าสู่ระบบก่อนถึงจะกดรายการโปรดได้');
    }

    final comicId = comic['id'];
    final existing = await supabase
        .from('favorites')
        .select('comic_id')
        .eq('user_id', userId)
        .eq('comic_id', comicId)
        .maybeSingle();

    if (existing != null) {
      await supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('comic_id', comicId);
    } else {
      await supabase.from('favorites').insert({
        'user_id': userId,
        'comic_id': comicId,
      });
    }
  }

  // --- ประวัติการอ่าน: ยังเก็บในเครื่องเหมือนเดิม (ไม่ผูกกับบัญชี) ---

  static Future<List<Map<String, dynamic>>> getRecentChapters() =>
      _readItems(_recentKey);

  static Future<void> saveRecentChapter(
    Map<String, dynamic> comic,
    Map<String, dynamic> chapter,
  ) async {
    final recentChapters = await getRecentChapters();
    final comicId = comic['id'].toString();
    final chapterId = chapter['id'].toString();
    recentChapters.removeWhere(
      (item) =>
          item['comic_id'].toString() == comicId &&
          item['chapter_id'].toString() == chapterId,
    );

    recentChapters.insert(0, {
      ..._comicData(comic),
      'comic_id': comicId,
      'chapter_id': chapterId,
      'chapter_title':
          'ตอนที่ ${chapter['chapter_number']}: ${chapter['title']}',
      'image_urls': chapter['image_urls'] ?? [],
    });

    await _writeItems(_recentKey, recentChapters.take(20).toList());
  }

  static Map<String, dynamic> _comicData(Map<String, dynamic> comic) => {
    'id': comic['id'],
    'title': comic['title'],
    'cover_url': comic['cover_url'],
    'description': comic['description'],
    'category': comic['category'],
    'view_count': comic['view_count'],
  };

  static Future<List<Map<String, dynamic>>> _readItems(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedItems = preferences.getString(key);
    if (encodedItems == null) return [];

    final decodedItems = jsonDecode(encodedItems) as List<dynamic>;
    return decodedItems
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<void> _writeItems(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(items));
  }
}
