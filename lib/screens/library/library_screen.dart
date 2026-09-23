import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:web_toon/core/auth_service.dart';
import 'package:web_toon/core/library_service.dart';

import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../comic/comic_detail_screen.dart';
import '../reader/reader_screen.dart';

/// หน้าคลังของฉัน: แท็บรายการโปรด (ต้อง login) และแท็บประวัติอ่านล่าสุด
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<Map<String, dynamic>>> _favoritesFuture;
  late Future<List<Map<String, dynamic>>> _recentFuture;

  @override
  void initState() {
    super.initState();
    _reload();
    // รายการโปรดผูกกับบัญชี -> พอ login/logout ต้องโหลดใหม่ให้ตรงกับบัญชีปัจจุบัน
    AuthService.instance.currentUser.addListener(_reload);
  }

  @override
  void dispose() {
    AuthService.instance.currentUser.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _favoritesFuture = LibraryService.getFavorites();
      _recentFuture = LibraryService.getRecentChapters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('คลังของฉัน'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: 'รายการโปรด'),
              Tab(icon: Icon(Icons.history), text: 'อ่านต่อ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ValueListenableBuilder(
              valueListenable: AuthService.instance.currentUser,
              builder: (context, user, _) {
                if (user == null) {
                  return const _FavoritesLoginPrompt();
                }
                return _LibraryList(
                  future: _favoritesFuture,
                  emptyMessage: 'ยังไม่มีรายการโปรด',
                  onRefresh: _reload,
                  onTap: (comic) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComicDetailScreen(comic: comic),
                    ),
                  ),
                );
              },
            ),
            _LibraryList(
              future: _recentFuture,
              emptyMessage: 'ยังไม่มีประวัติการอ่าน',
              onRefresh: _reload,
              isRecent: true,
              onTap: (chapter) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReaderScreen(
                    chapterTitle: chapter['chapter_title'].toString(),
                    imageUrls: chapter['image_urls'] as List<dynamic>? ?? [],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryList extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onTap;
  final bool isRecent;

  const _LibraryList({
    required this.future,
    required this.emptyMessage,
    required this.onRefresh,
    required this.onTap,
    this.isRecent = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              children: [
                SizedBox(height: 360, child: Center(child: Text(emptyMessage))),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final coverUrl = item['cover_url'].toString();
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: coverUrl,
                      width: 48,
                      height: 64,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const SizedBox(
                        width: 48,
                        height: 64,
                        child: Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  title: Text(
                    item['title']?.toString() ?? 'ไม่มีชื่อเรื่อง',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    isRecent
                        ? item['chapter_title']?.toString() ?? ''
                        : item['category']?.toString() ?? 'ทั่วไป',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: Icon(
                    isRecent ? Icons.play_circle_fill : Icons.arrow_forward_ios,
                    color: AppColors.primary,
                  ),
                  onTap: () => onTap(item),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// การ์ดชวน login สำหรับแท็บรายการโปรด (ตอนยังไม่ได้เข้าสู่ระบบ)
class _FavoritesLoginPrompt extends StatelessWidget {
  const _FavoritesLoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'เข้าสู่ระบบเพื่อบันทึกและดูรายการโปรดของคุณ',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
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
}
