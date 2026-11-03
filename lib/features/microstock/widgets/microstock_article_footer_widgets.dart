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
    return GestureDetector(
      onTap: isTranslating ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isTranslated
              ? const Color(0xFF6C5CE7).withValues(alpha: 0.15)
              : const Color(0xFF6C5CE7).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTranslated
                ? const Color(0xFF6C5CE7).withValues(alpha: 0.4)
                : const Color(0xFF6C5CE7).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTranslating)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF6C5CE7)),
              )
            else
              Icon(
                Icons.translate_rounded,
                size: 14,
                color: isTranslated ? const Color(0xFF9D8DF1) : const Color(0xFF6C5CE7),
              ),
            const SizedBox(width: 6),
            Text(
              isTranslating
                  ? 'Menerjemahkan...'
                  : (isTranslated ? 'Tampilkan Asli' : 'Terjemahkan Artikel (ID)'),
              style: TextStyle(
                color: isTranslated ? const Color(0xFF9D8DF1) : const Color(0xFF6C5CE7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
  const ArticleFooterSourceBox({super.key, required this.article, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181824) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verified Microstock Guideline • ${article.source}',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
