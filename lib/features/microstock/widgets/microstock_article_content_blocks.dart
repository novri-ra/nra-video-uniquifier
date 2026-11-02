import 'package:flutter/material.dart';
import '../../../core/services/microstock_news_service.dart';
import '../../../core/theme/app_colors.dart';

/// Metadata tags row showing category, reading time, date, and source.
class ArticleMetaTagsRow extends StatelessWidget {
  final MicrostockNewsArticle article;
  final bool isDark;
  const ArticleMetaTagsRow({super.key, required this.article, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            article.category,
            style: const TextStyle(
              color: Color(0xFF9D8DF1),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A3C) : const Color(0xFFEEF2F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              const SizedBox(width: 4),
              Text(
                article.readTime,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Text(
          '• ${article.publishedDate}',
          style: TextStyle(
            color: isDark ? AppColors.outline : const Color(0xFF9CA3AF),
            fontSize: 11,
          ),
        ),
        Text(
          '• ${article.source}',
          style: TextStyle(
            color: isDark ? AppColors.outline : const Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Highlight box for key takeaways / recommendations.
class ArticleKeyTakeawaysBox extends StatelessWidget {
  final String text;
  final bool isDark;
  const ArticleKeyTakeawaysBox({super.key, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF6C5CE7).withValues(alpha: 0.12)
            : const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF9D8DF1)),
              SizedBox(width: 6),
              Text(
                'KEY TAKEAWAYS / REKOMENDASI CEPAT',
                style: TextStyle(
                  color: Color(0xFF9D8DF1),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Container for technical parameter specifications.
class ArticleTechnicalSpecsBox extends StatelessWidget {
  final List<String> specs;
  final bool isDark;
  const ArticleTechnicalSpecsBox({super.key, required this.specs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14141E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 15, color: Color(0xFF38BDF8)),
              SizedBox(width: 6),
              Text(
                'PARAMETER TEKNIS REKOMENDASI',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final spec in specs)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      spec,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Checklist container for contributor curation compliance.
class ArticleContributorChecklistBox extends StatelessWidget {
  final List<String> items;
  final bool isDark;
  const ArticleContributorChecklistBox({super.key, required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF10B981).withValues(alpha: 0.08)
            : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 15, color: Color(0xFF10B981)),
              SizedBox(width: 6),
              Text(
                'CHECKLIST KONTRIBUTOR (100% LOLOS KURASI)',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_rounded, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
