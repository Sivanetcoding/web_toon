import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:web_toon/core/auth_service.dart';
import 'package:web_toon/core/library_service.dart';
import 'package:web_toon/core/navigation.dart';
import 'package:web_toon/core/supabase_client.dart';

import '../../theme/app_theme.dart';
import '../reader/reader_screen.dart';

/// หน้ารายละเอียดการ์ตูน: ปก/เรื่องย่อ, รายการตอน, ปุ่มรายการโปรด
/// และเมนูเพิ่ม/แก้ไข/ลบตอนสำหรับ admin
class ComicDetailScreen extends StatefulWidget {
  final Map<String, dynamic> comic;

  const ComicDetailScreen({super.key, required this.comic});

  @override
  State<ComicDetailScreen> createState() => _ComicDetailScreenState();
}

class _ComicDetailScreenState extends State<ComicDetailScreen> {
  bool _isFavorite = false;
  late Future<List<dynamic>> _chaptersFuture;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _chaptersFuture = _fetchChapters();
    // ถ้าผู้ใช้ login/logout ระหว่างที่เปิดหน้านี้ค้างอยู่ ให้เช็คสถานะรายการโปรดใหม่
    AuthService.instance.currentUser.addListener(_loadFavoriteStatus);
  }

  @override
  void dispose() {
    AuthService.instance.currentUser.removeListener(_loadFavoriteStatus);
    super.dispose();
  }

  void _reloadChapters() {
    setState(() {
      _chaptersFuture = _fetchChapters();
    });
  }

  Future<void> _loadFavoriteStatus() async {
    final isFavorite = await LibraryService.isFavorite(
      widget.comic['id'].toString(),
    );
    if (mounted) {
      setState(() => _isFavorite = isFavorite);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      await LibraryService.toggleFavorite(widget.comic);
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนถึงจะกดรายการโปรดได้'),
        ),
      );
    }
  }

  Future<List<dynamic>> _fetchChapters() async {
    final data = await supabase
        .from('chapters')
        .select()
        .eq('comic_id', widget.comic['id'])
        .order('chapter_number', ascending: true);
    return data as List<dynamic>;
  }

  // ฟังก์ชันเพิ่มตอนใหม่
  Future<void> _addChapterDialog() async {
    final chapterNumController = TextEditingController();
    final titleController = TextEditingController();
    final urlsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มตอนใหม่'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: chapterNumController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ตอนที่ (เช่น 1, 2, 3)',
                ),
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อตอน (เช่น จุดเริ่มต้น)',
                ),
              ),
              TextField(
                controller: urlsController,
                decoration: const InputDecoration(
                  labelText: 'URL รูปภาพหน้าการ์ตูน',
                  hintText: 'วาง URL คั่นด้วย , หรือบรรทัดใหม่',
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (chapterNumController.text.isNotEmpty) {
                // แปลงข้อความ URL ให้เป็น List<String>
                final rawUrls = urlsController.text;
                List<String> imageUrls = rawUrls
                    .split(RegExp(r'[\n,]'))
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                await supabase.from('chapters').insert({
                  'comic_id': widget.comic['id'],
                  'chapter_number':
                      int.tryParse(chapterNumController.text.trim()) ?? 1,
                  'title': titleController.text.trim(),
                  'image_urls': imageUrls,
                });

                if (mounted) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _reloadChapters();
                }
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    chapterNumController.dispose();
    titleController.dispose();
    urlsController.dispose();
  }

  // ฟังก์ชันลบตอน
  Future<void> _deleteChapter(String chapterId, String chapterTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบ "$chapterTitle" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('chapters').delete().eq('id', chapterId);
      _reloadChapters();
    }
  }

  Future<void> _openChapter(Map<String, dynamic> chapter) async {
    final titleString =
        'ตอนที่ ${chapter['chapter_number']}: ${chapter['title']}';
    await LibraryService.saveRecentChapter(widget.comic, chapter);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(
          chapterTitle: titleString,
          imageUrls: chapter['image_urls'] ?? [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String coverUrl = (widget.comic['cover_url'] ?? '').toString().trim();
    final String category = widget.comic['category'] ?? 'ทั่วไป';
    final int viewCount = widget.comic['view_count'] ?? 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.home),
              tooltip: 'กลับหน้าแรก',
              onPressed: () => goToHome(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _FavoriteButton(
                  isFavorite: _isFavorite,
                  onPressed: _toggleFavorite,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        Container(color: AppColors.surfaceVariant),
                  ),
                  // เบลอภาพพื้นหลังให้ดูนุ่มนวลแบบเว็บมันฮวา
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          AppColors.background.withValues(alpha: 0.55),
                          AppColors.background,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  final cover = ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: coverUrl,
                      width: 120,
                      height: 164,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 120,
                        height: 164,
                        color: AppColors.surfaceVariant,
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 120,
                        height: 164,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  );
                  final summary = Column(
                    crossAxisAlignment: isNarrow
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.comic['title'] ?? '',
                        textAlign: isNarrow
                            ? TextAlign.center
                            : TextAlign.start,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // --- แสดงแท็กหมวดหมู่ และ จำนวนคนเข้าชม ---
                      Wrap(
                        alignment: isNarrow
                            ? WrapAlignment.center
                            : WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.heroGradient,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.remove_red_eye,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$viewCount วิว',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Text(
                        widget.comic['description'] ??
                            'ไม่มีรายละเอียดเรื่องย่อ',
                        textAlign: isNarrow
                            ? TextAlign.center
                            : TextAlign.start,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      children: [cover, const SizedBox(height: 16), summary],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      cover,
                      const SizedBox(width: 16),
                      Expanded(child: summary),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<dynamic>>(
                future: _chaptersFuture,
                builder: (context, snapshot) {
                  final chapters = snapshot.data ?? [];
                  if (chapters.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openChapter(chapters.last),
                      icon: const Icon(Icons.menu_book),
                      label: const Text(
                        'เริ่มอ่านตอนล่าสุด',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.format_list_bulleted,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'รายชื่อตอน',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<dynamic>>(
            future: _chaptersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                    ),
                  ),
                );
              }
              final chapters = snapshot.data ?? [];
              if (chapters.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'ยังไม่มีตอนให้อ่าน\nกดปุ่ม + ด้านล่างเพื่อเพิ่มตอนใหม่',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                sliver: SliverList.separated(
                  itemCount: chapters.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    final titleString =
                        'ตอนที่ ${chapter['chapter_number']}: ${chapter['title']}';

                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceVariant,
                          child: Text(
                            '${chapter['chapter_number']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        title: Text(
                          titleString,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: ValueListenableBuilder<bool>(
                          valueListenable: AuthService.instance.isAdmin,
                          builder: (context, isAdmin, _) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _deleteChapter(
                                      chapter['id'].toString(),
                                      titleString,
                                    ),
                                  ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            );
                          },
                        ),
                        onTap: () => _openChapter(chapter),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      // ปุ่ม + สำหรับเพิ่มตอนใหม่ (เฉพาะ admin เท่านั้น)
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: AuthService.instance.isAdmin,
        builder: (context, isAdmin, _) {
          if (!isAdmin) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: _addChapterDialog,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

/// ปุ่มรายการโปรดแบบเอกลักษณ์ของแอป: วงกลมไล่เฉดสีเมื่อกดถูกใจ
/// พร้อมแอนิเมชันเด้งแทนไอคอนหัวใจเปล่า ๆ ของ Flutter ปกติ
class _FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  const _FavoriteButton({required this.isFavorite, required this.onPressed});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    lowerBound: 0.85,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    widget.onPressed();
    await _controller.reverse();
    if (mounted) await _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFavorite = widget.isFavorite;
    return Tooltip(
      message: isFavorite ? 'ลบออกจากรายการโปรด' : 'เพิ่มรายการโปรด',
      child: GestureDetector(
        onTap: _handleTap,
        child: ScaleTransition(
          scale: _controller,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isFavorite ? AppTheme.heroGradient : null,
              color: isFavorite ? null : AppColors.surface.withValues(alpha: 0.7),
              border: Border.all(
                color: isFavorite
                    ? Colors.transparent
                    : AppColors.textSecondary.withValues(alpha: 0.4),
                width: 1.4,
              ),
              boxShadow: isFavorite
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color: isFavorite ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
