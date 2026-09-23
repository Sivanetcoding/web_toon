import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// หัวข้อหมวดพร้อมแถบสีเน้นด้านซ้าย ใช้ซ้ำได้ทุกหน้าให้ดูเป็นสไตล์เดียวกัน
class SectionHeader extends StatelessWidget {
  final String title;
  final String? emoji;

  const SectionHeader({super.key, required this.title, this.emoji});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
