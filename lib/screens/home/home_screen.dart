import 'package:flutter/material.dart';
import 'package:web_toon/core/auth_service.dart';
import 'package:web_toon/core/external_manga_service.dart';
import 'package:web_toon/core/supabase_client.dart';
import 'package:web_toon/core/theme_controller.dart';

import '../../theme/app_theme.dart';
import '../../widgets/comic_poster_card.dart';
import '../../widgets/section_header.dart';
import '../comic/comic_detail_screen.dart';

/// หน้าแรก: การ์ตูนยอดนิยม, แนะนำจาก AniList (API ภายนอก), หมวดหมู่, กริดการ์ตูนทั้งหมด
/// และเมนูเพิ่ม/แก้ไข/ลบการ์ตูนสำหรับ admin
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'ทั้งหมด';
  Map<String, dynamic>? _selectedExternalManga;

  // รายการหมวดหมู่การ์ตูน (อัปเดตหมวดหมู่ครบตามต้องการ)
  final List<String> _categories = [
    'ทั้งหมด',
    'แอคชั่น',
    'แฟนตาซี',
    'โรแมนติก',
    'โรแมนซ์แฟนตาซี',
    'ดราม่า',
    'ตลก',
    'ชีวิตประจำวัน',
    'สยองขวัญ',
    'ทริลเลอร์',
    'กีฬา',
    'มูริม / ยุทธภพ',
  ];

  // ดึงข้อมูลการ์ตูน กรองตามหมวดหมู่ที่เลือก
  Future<List<dynamic>> _getComics() async {
    if (_selectedCategory != 'ทั้งหมด') {
      final data = await supabase
          .from('comics')
          .select()
          .ilike('category', '%$_selectedCategory%');
      return data as List<dynamic>;
    }
    final data = await supabase.from('comics').select();
    return data as List<dynamic>;
  }

  // ดึงข้อมูลการ์ตูนที่ยอดวิวสูงสุด 5 อันดับแรก
  Future<List<dynamic>> _getPopularComics() async {
    final data = await supabase
        .from('comics')
        .select()
        .order('view_count', ascending: false)
        .limit(5);
    return data as List<dynamic>;
  }

  // ฟังก์ชันเมื่อกดเข้าดูรายละเอียดการ์ตูน -> บันทึกยอดวิว +1 (ผ่าน RPC แบบ atomic กันนับชน)
  Future<void> _openComicDetail(Map<String, dynamic> comic) async {
    try {
      await supabase.rpc(
        'increment_view_count',
        params: {'comic_id_input': comic['id']},
      );
    } catch (_) {
      // ถ้ายังไม่ได้สร้างฟังก์ชัน increment_view_count ใน Supabase
      // ก็ข้ามการนับยอดวิวไปก่อน ไม่บล็อกการเปิดอ่านการ์ตูน
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ComicDetailScreen(comic: comic)),
    );

    if (!mounted) return;
    setState(() {});
  }

  // dialog เดียวกันใช้ร่วมกันทั้งเพิ่ม/แก้ไขการ์ตูน เพื่อไม่ให้ UI ซ้ำกันสองชุด
  Future<void> _comicFormDialog({
    required String dialogTitle,
    required String submitLabel,
    String initialTitle = '',
    String initialDescription = '',
    String initialCoverUrl = '',
    List<String> initialCategories = const ['แอคชั่น'],
    required Future<void> Function(
      String title,
      String description,
      String coverUrl,
      List<String> categories,
    )
    onSubmit,
  }) async {
    final titleController = TextEditingController(text: initialTitle);
    final descController = TextEditingController(text: initialDescription);
    final coverUrlController = TextEditingController(text: initialCoverUrl);
    List<String> selectedCategoriesInDialog = List.of(initialCategories);
    if (selectedCategoriesInDialog.isEmpty) {
      selectedCategoriesInDialog = ['แอคชั่น'];
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(dialogTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อเรื่อง (Title)',
                    ),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'เรื่องย่อ (Description)',
                    ),
                    maxLines: 3,
                  ),
                  TextField(
                    controller: coverUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL รูปภาพปก (Cover URL)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'หมวดหมู่ (เลือกได้หลายรายการ):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _categories.where((cat) => cat != 'ทั้งหมด').map((
                      cat,
                    ) {
                      final isSelected = selectedCategoriesInDialog.contains(
                        cat,
                      );
                      return FilterChip(
                        label: Text(cat, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedCategoriesInDialog.add(cat);
                            } else {
                              if (selectedCategoriesInDialog.length > 1) {
                                selectedCategoriesInDialog.remove(cat);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
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
                  if (titleController.text.isNotEmpty) {
                    await onSubmit(
                      titleController.text.trim(),
                      descController.text.trim(),
                      coverUrlController.text.trim(),
                      selectedCategoriesInDialog,
                    );
                    if (mounted) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      setState(() {});
                    }
                  }
                },
                child: Text(submitLabel),
              ),
            ],
          );
        },
      ),
    );

    titleController.dispose();
    descController.dispose();
    coverUrlController.dispose();
  }

  // ฟังก์ชันสำหรับเพิ่มการ์ตูนเรื่องใหม่
  Future<void> _addComicDialog() {
    return _comicFormDialog(
      dialogTitle: 'เพิ่มการ์ตูนเรื่องใหม่',
      submitLabel: 'บันทึก',
      onSubmit: (title, description, coverUrl, categories) async {
        await supabase.from('comics').insert({
          'title': title,
          'description': description,
          'cover_url': coverUrl,
          'category': categories.join(','),
          'view_count': 0,
        });
      },
    );
  }

  // ฟังก์ชันสำหรับแก้ไขข้อมูลการ์ตูน
  Future<void> _editComicDialog(Map<String, dynamic> comic) {
    final currentCategories = (comic['category'] ?? '')
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return _comicFormDialog(
      dialogTitle: 'แก้ไขข้อมูลการ์ตูน',
      submitLabel: 'บันทึกการแก้ไข',
      initialTitle: comic['title'] ?? '',
      initialDescription: comic['description'] ?? '',
      initialCoverUrl: comic['cover_url'] ?? '',
      initialCategories: currentCategories,
      onSubmit: (title, description, coverUrl, categories) async {
        await supabase
            .from('comics')
            .update({
              'title': title,
              'description': description,
              'cover_url': coverUrl,
              'category': categories.join(','),
            })
            .eq('id', comic['id']);
      },
    );
  }

  // ฟังก์ชันสำหรับลบการ์ตูน
  Future<void> _deleteComic(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบเรื่อง "$title" หรือไม่?'),
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
      await supabase.from('comics').delete().eq('id', id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildBrandHeader(context)),

            // --- 1. ส่วนการ์ตูนเข้าชมมากที่สุด (Most Viewed) ---
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'เข้าชมมากที่สุด', emoji: '🔥'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: FutureBuilder<List<dynamic>>(
                  future: _getPopularComics(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final populars = snapshot.data ?? [];
                    if (populars.isEmpty) {
                      return const Center(child: Text('ยังไม่มีข้อมูลการ์ตูน'));
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: populars.length,
                      itemBuilder: (context, index) {
                        final comic = populars[index];
                        final coverUrl = (comic['cover_url'] ?? '')
                            .toString()
                            .trim();
                        final int viewCount = comic['view_count'] ?? 0;

                        return Container(
                          width: 140,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: ComicPosterCard(
                            title: comic['title'] ?? '',
                            coverUrl: coverUrl,
                            viewCount: viewCount,
                            rank: index + 1,
                            onTap: () => _openComicDetail(comic),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // --- 1.5 มังงะยอดนิยมจาก AniList (เรียก API ภายนอกจริงๆ) ---
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'แนะนำจาก AniList', emoji: '🌐'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: ExternalMangaService.fetchPopularManga(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('โหลดข้อมูลจากภายนอกไม่สำเร็จ'),
                      );
                    }

                    final mangaList = snapshot.data ?? [];
                    if (mangaList.isEmpty) {
                      return const Center(child: Text('ไม่มีข้อมูล'));
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: mangaList.length,
                      itemBuilder: (context, index) {
                        final manga = mangaList[index];
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: ComicPosterCard(
                            title: manga['title'] ?? '',
                            coverUrl: (manga['cover_url'] ?? '').toString(),
                            onTap: () =>
                                setState(() => _selectedExternalManga = manga),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // แผงรายละเอียดของเรื่องที่กดเลือกจากแถว AniList ด้านบน
            // (แสดงอยู่ในหน้าแรกเลย ไม่ใช่ dialog ลอย)
            if (_selectedExternalManga != null)
              SliverToBoxAdapter(
                child: _ExternalMangaDetailPanel(
                  manga: _selectedExternalManga!,
                  onClose: () => setState(() => _selectedExternalManga = null),
                ),
              ),

            // --- 2. แถบเลือกหมวดหมู่ ---
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'หมวดหมู่', emoji: '🏷️'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SectionHeader(title: 'การ์ตูนทั้งหมด', emoji: '📚'),
            ),

            // --- 3. รายการการ์ตูนทั้งหมดตามหมวดหมู่ที่เลือก ---
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: FutureBuilder<List<dynamic>>(
                future: _getComics(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                      ),
                    );
                  }

                  final comics = snapshot.data ?? [];

                  if (comics.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('ไม่พบการ์ตูนในหมวดหมู่นี้')),
                      ),
                    );
                  }

                  return SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final comic = comics[index];
                      final String coverUrl = (comic['cover_url'] ?? '')
                          .toString()
                          .trim();
                      final int viewCount = comic['view_count'] ?? 0;

                      return Stack(
                        children: [
                          ComicPosterCard(
                            title: comic['title'] ?? 'ไม่มีชื่อเรื่อง',
                            coverUrl: coverUrl,
                            category: comic['category'],
                            viewCount: viewCount,
                            onTap: () => _openComicDetail(comic),
                          ),
                          // ปุ่มแก้ไขและปุ่มลบการ์ตูนที่มุมขวาบน (เฉพาะ admin เท่านั้น)
                          ValueListenableBuilder<bool>(
                            valueListenable: AuthService.instance.isAdmin,
                            builder: (context, isAdmin, _) {
                              if (!isAdmin) return const SizedBox.shrink();
                              return Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blueAccent,
                                          size: 18,
                                        ),
                                        onPressed: () => _editComicDialog(comic),
                                      ),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(6),
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                        onPressed: () => _deleteComic(
                                          comic['id'].toString(),
                                          comic['title'] ?? '',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }, childCount: comics.length),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: AuthService.instance.isAdmin,
        builder: (context, isAdmin, _) {
          if (!isAdmin) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: _addComicDialog,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  // แถบหัวเรื่องแบรนด์ด้านบนของหน้าแรก พร้อมปุ่มสลับธีมสว่าง/มืดที่มุมขวาบน
  Widget _buildBrandHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.heroGradient.createShader(bounds),
            child: const Text(
              'WEBTOON',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'อ่านมันฮวาออนไลน์',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Spacer(),
          const _ThemeToggleButton(),
        ],
      ),
    );
  }
}

/// ปุ่มไอคอนเล็กๆ ไว้สลับธีมสว่าง/มืดของทั้งแอป (มีผลทันทีและจำค่าไว้ในเครื่อง)
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, mode, _) {
        final isLight = mode == ThemeMode.light;
        return IconButton(
          tooltip: isLight ? 'สลับเป็นธีมมืด' : 'สลับเป็นธีมสว่าง',
          icon: Icon(
            isLight ? Icons.dark_mode : Icons.light_mode,
            color: AppColors.textSecondary,
          ),
          onPressed: () => ThemeController.instance.setLight(!isLight),
        );
      },
    );
  }
}

/// แผงแสดงรายละเอียดมังงะจาก AniList อยู่ในหน้าแรกเลย (ไม่เปิดเป็น dialog ลอย)
/// โผล่ต่อจากแถวการ์ดเมื่อผู้ใช้กดเลือกเรื่องใดเรื่องหนึ่ง
class _ExternalMangaDetailPanel extends StatelessWidget {
  final Map<String, dynamic> manga;
  final VoidCallback onClose;

  const _ExternalMangaDetailPanel({required this.manga, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  manga['title'] ?? '',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: onClose,
              ),
            ],
          ),
          if (manga['score'] != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  'คะแนน AniList: ${manga['score']}/100',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            manga['synopsis'] ?? 'ไม่มีเรื่องย่อ',
            style: TextStyle(color: AppColors.textPrimary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
