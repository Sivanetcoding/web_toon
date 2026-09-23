import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:web_toon/core/navigation.dart';

import '../../theme/app_theme.dart';

/// หน้าอ่านตอน: เลื่อนดูรูปภาพของตอนตามลำดับแนวตั้ง พร้อมเลขหน้าปัจจุบัน/ทั้งหมด
class ReaderScreen extends StatefulWidget {
  final String chapterTitle;
  final List<dynamic> imageUrls;

  const ReaderScreen({
    super.key,
    required this.chapterTitle,
    required this.imageUrls,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (widget.imageUrls.isEmpty) return;
    final estimatedPage = (_scrollController.offset / 900).floor().clamp(
      0,
      widget.imageUrls.length - 1,
    );
    if (estimatedPage != _currentPage) {
      setState(() => _currentPage = estimatedPage);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.55),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'กลับหน้าแรก',
          onPressed: () => goToHome(context),
        ),
        title: Text(
          widget.chapterTitle,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          if (widget.imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPage + 1}/${widget.imageUrls.length}',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: widget.imageUrls.isEmpty
          ? const Center(
              child: Text(
                'ไม่มีภาพในตอนนี้',
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: widget.imageUrls.length,
              itemBuilder: (context, index) {
                final String url = widget.imageUrls[index].toString().trim();

                if (url.isEmpty) {
                  return _imageError('ไม่พบ URL ของภาพหน้านี้');
                }

                return CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    height: 300,
                    color: Colors.grey[900],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) {
                    return _imageError('โหลดภาพหน้านี้ไม่สำเร็จ');
                  },
                );
              },
            ),
    );
  }

  Widget _imageError(String message) {
    return Container(
      height: 200,
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.white, size: 50),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
