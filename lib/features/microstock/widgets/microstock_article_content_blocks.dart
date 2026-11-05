import 'package:flutter/material.dart';
import '../../../core/services/microstock_news_service.dart';
import '../../../core/theme/app_colors.dart';

/// Metadata tags row showing category, reading time, date, and source.
class ArticleMetaTagsRow extends StatelessWidget {
  final MicrostockNewsArticle article;
  final bool isDark;
  const ArticleMetaTagsRow({
    super.key,
    required this.article,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final catAccent = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final metaColor = isDark
        ? AppColors.outline
        : AppColors.lightOnSurfaceVariant;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: catAccent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            article.category,
            style: TextStyle(
              color: catAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceContainer
                : AppColors.hairlineBorder,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, size: 11, color: metaColor),
              const SizedBox(width: 4),
              Text(
                article.readTime,
                style: TextStyle(
                  color: isDark
                      ? AppColors.onSurface
                      : AppColors.lightOnSurface,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Text(
          '• ${article.publishedDate}',
          style: TextStyle(color: metaColor, fontSize: 11),
        ),
        Text(
          '• ${article.source}',
          style: TextStyle(
            color: metaColor,
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
  const ArticleKeyTakeawaysBox({
    super.key,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'KEY TAKEAWAYS / QUICK RECOMMENDATIONS',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: isDark ? AppColors.onSurface : AppColors.lightOnSurface,
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
  const ArticleTechnicalSpecsBox({
    super.key,
    required this.specs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final specAccent = isDark ? AppColors.skyPastel : AppColors.forestDeep;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.obsidianDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.outlineVariant
              : AppColors.lightOutlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 15, color: specAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'RECOMMENDED TECHNICAL PARAMETERS',
                  style: TextStyle(
                    color: specAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                  Text(
                    '• ',
                    style: TextStyle(
                      color: specAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      spec,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.onSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
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
  const ArticleContributorChecklistBox({
    super.key,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final checkAccent = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: checkAccent.withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: checkAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 15,
                color: checkAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'CONTRIBUTOR CHECKLIST (100% CURATION PASS)',
                  style: TextStyle(
                    color: checkAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                  Icon(Icons.check_rounded, size: 14, color: checkAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.onSurface
                            : AppColors.lightOnSurface,
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
