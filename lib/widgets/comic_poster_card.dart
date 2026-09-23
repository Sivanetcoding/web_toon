import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// การ์ดปกการ์ตูนสไตล์เว็บมันฮวา: ภาพเต็มการ์ด + ไล่เฉดสีทับด้านล่างเพื่อวางชื่อเรื่อง
class ComicPosterCard extends StatelessWidget {
  final String title;
  final String coverUrl;
  final String? category;
  final int? viewCount;
  final int? rank;
  final VoidCallback onTap;

  const ComicPosterCard({
    super.key,
    required this.title,
    required this.coverUrl,
    required this.onTap,
    this.category,
    this.viewCount,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              // จำกัดขนาดตอน decode ไม่ให้โหลดภาพความละเอียดเต็มพร้อมกันหลายสิบรูป
              memCacheWidth: 400,
              placeholder: (context, url) =>
                  Container(color: AppColors.surfaceVariant),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surfaceVariant,
                child: Icon(
                  Icons.broken_image,
                  color: AppColors.textSecondary,
                  size: 32,
                ),
              ),
            ),
            // ไล่เฉดมืดจากล่างขึ้นบนให้ตัวหนังสือชื่อเรื่องอ่านง่าย
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.4, 0.65, 1.0],
                  ),
                ),
              ),
            ),
            if (rank != null)
              Positioned(top: 8, left: 8, child: _RankBadge(rank: rank!)),
            if (viewCount != null)
              Positioned(
                top: 8,
                right: 8,
                child: _PillBadge(
                  icon: Icons.remove_red_eye,
                  label: _formatCount(viewCount!),
                ),
              ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      height: 1.2,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                  if (category != null && category!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      category!.split(',').first.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: isTopThree ? AppTheme.heroGradient : null,
        color: isTopThree ? null : Colors.black.withValues(alpha: 0.75),
        shape: BoxShape.circle,
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: Text(
        '$rank',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PillBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.secondary),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
