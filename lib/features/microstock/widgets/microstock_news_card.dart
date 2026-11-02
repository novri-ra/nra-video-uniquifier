import 'package:flutter/material.dart';
import '../../../core/services/microstock_news_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/theme/app_colors.dart';
import 'microstock_article_sheet.dart';

/// News article card with inline auto-translation and tag chips.
class MicrostockNewsCard extends StatefulWidget {
  final MicrostockNewsArticle article;
  final bool isDark;
  final bool isOnline;

  const MicrostockNewsCard({
    super.key,
    required this.article,
    required this.isDark,
    required this.isOnline,
  });

  @override
  State<MicrostockNewsCard> createState() => _MicrostockNewsCardState();
}

class _MicrostockNewsCardState extends State<MicrostockNewsCard> {
  bool _isTranslated = false;
  bool _isTranslating = false;
  String? _translatedTitle;
  String? _translatedSummary;

  Future<void> _toggleTranslation() async {
    if (_isTranslated) {
      setState(() => _isTranslated = false);
      return;
    }

    if (_translatedTitle != null && _translatedSummary != null) {
      setState(() => _isTranslated = true);
      return;
    }

    setState(() => _isTranslating = true);
    try {
      final tTitle = await TranslationService.translateText(
        widget.article.title,
        targetLang: 'id',
        isOnline: widget.isOnline,
      );
      final tSummary = await TranslationService.translateText(
        widget.article.summary,
        targetLang: 'id',
        isOnline: widget.isOnline,
      );

      if (!mounted) return;
      setState(() {
        _translatedTitle = tTitle;
        _translatedSummary = tSummary;
        _isTranslated = true;
        _isTranslating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTranslating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is TranslationOfflineException
                ? e.message
                : 'Gagal menerjemahkan berita',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = widget.isDark
        ? AppColors.surfaceContainerHighest
        : AppColors.lightOutlineVariant;
    final titleColor = widget.isDark ? AppColors.onSurface : const Color(0xFF111827);
    final summaryColor = widget.isDark
        ? AppColors.onSurfaceVariant
        : const Color(0xFF4B5563);
    const purpleAccent = Color(0xFF6C5CE7);

    final displayTitle = (_isTranslated && _translatedTitle != null)
        ? _translatedTitle!
        : widget.article.title;
    final displaySummary = (_isTranslated && _translatedSummary != null)
        ? _translatedSummary!
        : widget.article.summary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!widget.isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => MicrostockArticleSheet.show(context, widget.article, widget.isDark),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CategoryBadge(
                      category: widget.article.category,
                      isDark: widget.isDark,
                    ),
                    Text(
                      widget.article.publishedDate,
                      style: TextStyle(
                        color: widget.isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  displayTitle,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displaySummary,
                  style: TextStyle(
                    color: summaryColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _TagsRow(tags: widget.article.tags, isDark: widget.isDark),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.article.source,
                        style: TextStyle(
                          color: widget.isDark ? AppColors.outline : const Color(0xFF6B7280),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TranslateButton(
                      isTranslated: _isTranslated,
                      isTranslating: _isTranslating,
                      isDark: widget.isDark,
                      accentColor: purpleAccent,
                      onTap: _toggleTranslation,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  final bool isDark;

  const _CategoryBadge({required this.category, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6C5CE7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: accent,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _TagsRow extends StatelessWidget {
  final List<String> tags;
  final bool isDark;

  const _TagsRow({required this.tags, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final chipBg = isDark ? AppColors.surfaceContainer : const Color(0xFFF3F4F6);
    final textColor = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tag,
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TranslateButton extends StatelessWidget {
  final bool isTranslated;
  final bool isTranslating;
  final bool isDark;
  final Color accentColor;
  final VoidCallback onTap;

  const _TranslateButton({
    required this.isTranslated,
    required this.isTranslating,
    required this.isDark,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isTranslating ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isTranslating)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                )
              else
                Icon(
                  isTranslated ? Icons.undo_rounded : Icons.translate_rounded,
                  size: 13,
                  color: accentColor,
                ),
              const SizedBox(width: 4),
              Text(
                isTranslated ? 'Tampilkan Asli' : 'Terjemahkan (ID)',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
