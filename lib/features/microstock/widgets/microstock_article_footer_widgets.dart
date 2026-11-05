import 'package:flutter/material.dart';
import '../../../core/services/microstock_news_service.dart';
import '../../../core/theme/app_colors.dart';

class ArticleTranslateButton extends StatelessWidget {
  final bool isTranslating;
  final bool isTranslated;
  final VoidCallback onTap;

  const ArticleTranslateButton({
    super.key,
    required this.isTranslating,
    required this.isTranslated,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return GestureDetector(
      onTap: isTranslating ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isTranslated
              ? accent.withValues(alpha: 0.18)
              : accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTranslated
                ? accent.withValues(alpha: 0.45)
                : accent.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTranslating)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: accent,
                ),
              )
            else
              Icon(Icons.translate_rounded, size: 14, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isTranslating
                    ? 'Translating...'
                    : (isTranslated
                          ? 'Show Original'
                          : 'Translate Article (ID)'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArticleFooterSourceBox extends StatelessWidget {
  final MicrostockNewsArticle article;
  final bool isDark;
  final bool isExternalSource;
  const ArticleFooterSourceBox({
    super.key,
    required this.article,
    required this.isDark,
    this.isExternalSource = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconAccent = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final icon = isExternalSource
        ? Icons.public_outlined
        : Icons.verified_outlined;
    final label = isExternalSource
        ? 'Published by ${article.source} • External Source'
        : 'Verified Microstock Guideline • ${article.source}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.obsidianDark : AppColors.hairlineBorder,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.outlineVariant
              : AppColors.lightOutlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppColors.onSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
