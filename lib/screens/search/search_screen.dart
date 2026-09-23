import 'package:flutter/material.dart';
import 'package:web_toon/core/supabase_client.dart';
import 'package:web_toon/core/navigation.dart';

import '../../theme/app_theme.dart';
import '../../widgets/comic_poster_card.dart';
import '../comic/comic_detail_screen.dart';

/// หน้าค้นหาการ์ตูนจากชื่อเรื่อง (ilike กับตาราง comics ใน Supabase)
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ฟังก์ชันค้นหาการ์ตูนใน Supabase
  Future<void> _searchComics(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      // ค้นหาการ์ตูนที่ชื่อเรื่องตรงกับคำค้นหา (ilike = ไม่สนตัวพิมพ์เล็ก-ใหญ่)
      final data = await supabase
          .from('comics')
          .select()
          .ilike('title', '%${query.trim()}%');

      if (!mounted) return;
      setState(() {
        _searchResults = data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ค้นหาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'กลับหน้าแรก',
          onPressed: () => goToHome(context),
        ),
        title: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true, // เปิดหน้านี้มาแล้วพร้อมพิมพ์ได้ทันที
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              icon: Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 20,
              ),
              hintText: 'พิมพ์ชื่อเรื่องที่ต้องการค้นหา...',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _searchComics('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => _searchComics(value),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasSearched
          ? const Center(child: Text('พิมพ์ชื่อเรื่องเพื่อเริ่มค้นหาการ์ตูน'))
          : _searchResults.isEmpty
          ? const Center(child: Text('ไม่พบการ์ตูนที่ตรงกับคำค้นหา'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.68,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final comic = _searchResults[index];
                final String coverUrl = (comic['cover_url'] ?? '')
                    .toString()
                    .trim();

                return ComicPosterCard(
                  title: comic['title'] ?? 'ไม่มีชื่อเรื่อง',
                  coverUrl: coverUrl,
                  category: comic['category'],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComicDetailScreen(comic: comic),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
