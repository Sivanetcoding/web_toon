import 'dart:convert';
import 'package:http/http.dart' as http;

/// เรียก AniList GraphQL API (https://anilist.co) ซึ่งเป็น public API ฟรี
/// ไม่ต้องขอ key ใช้ดึงมังงะยอดนิยมจากภายนอกมาโชว์เสริมในหน้าแรก
/// (คนละแหล่งข้อมูลกับ Supabase ของแอปเอง)
class ExternalMangaService {
  static const _endpoint = 'https://graphql.anilist.co';

  static const _query = r'''
    query ($perPage: Int) {
      Page(page: 1, perPage: $perPage) {
        media(type: MANGA, sort: POPULARITY_DESC) {
          title {
            romaji
            english
          }
          coverImage {
            large
          }
          averageScore
          description(asHtml: false)
          siteUrl
        }
      }
    }
  ''';

  static Future<List<Map<String, dynamic>>> fetchPopularManga({
    int limit = 10,
  }) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': _query,
        'variables': {'perPage': limit},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('โหลดข้อมูลจาก AniList ไม่สำเร็จ (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final mediaList =
        (body['data']?['Page']?['media'] as List<dynamic>?) ?? [];

    return mediaList.map((item) {
      final title = item['title'] as Map<String, dynamic>? ?? {};
      final coverImage = item['coverImage'] as Map<String, dynamic>? ?? {};
      final description = (item['description'] as String?) ?? 'ไม่มีเรื่องย่อ';

      return {
        'title': title['english'] ?? title['romaji'] ?? 'ไม่มีชื่อเรื่อง',
        'cover_url': coverImage['large'] ?? '',
        'score': item['averageScore'],
        'synopsis': _stripHtmlTags(description),
        'url': item['siteUrl'] ?? '',
      };
    }).toList();
  }

  static String _stripHtmlTags(String input) =>
      input.replaceAll(RegExp(r'<[^>]*>'), '');
}
