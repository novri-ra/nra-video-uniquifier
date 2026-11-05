import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/microstock_news_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../services/user_news_bookmark_service.dart';
import '../utils/html_sanitizer.dart';
import 'microstock_article_sheet.dart';

/// News article card with inline auto-translation, source badges, and tag chips.
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
                : 'Failed to translate news',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _cleanDate(String dateStr) {
    final clean = HtmlSanitizer.clean(dateStr);
    if (clean.length <= 12) return clean;
    final rfcMatch = RegExp(
      r'(\d{1,2}\s+[A-Za-z]{3}\s+\d{4})',
    ).firstMatch(clean);
    if (rfcMatch != null) {
      return rfcMatch.group(1)!;
    }
    final parts = clean.split(' ');
    if (parts.length >= 4 && parts[0].endsWith(',')) {
      return '${parts[1]} ${parts[2]} ${parts[3]}';
    }
    return clean.length > 16 ? '${clean.substring(0, 16)}..' : clean;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? AppColors.obsidianDark : AppColors.white;
    final borderColor = widget.isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;
    final titleColor = widget.isDark
        ? AppColors.onSurface
        : AppColors.lightOnSurface;
    final summaryColor = widget.isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final cardAccent = widget.isDark
        ? AppColors.mintSage
        : AppColors.forestDeep;

    final displayTitle = HtmlSanitizer.clean(
      (_isTranslated && _translatedTitle != null)
          ? _translatedTitle!
          : widget.article.title,
    );
    final displaySummary = HtmlSanitizer.clean(
      (_isTranslated && _translatedSummary != null)
          ? _translatedSummary!
          : widget.article.summary,
    );

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
          onTap: () => MicrostockArticleSheet.show(
            context,
            widget.article,
            widget.isDark,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((widget.article.localImagePath != null &&
                        widget.article.localImagePath!.isNotEmpty) ||
                    (widget.article.imageUrl != null &&
                        widget.article.imageUrl!.isNotEmpty)) ...[
                  _CardImageThumbnail(
                    article: widget.article,
                    isDark: widget.isDark,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    _CategoryBadge(
                      category: widget.article.category,
                      isDark: widget.isDark,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: _SourceBadge(
                        source: widget.article.source,
                        isDark: widget.isDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _ReadTimeBadge(
                      readTime: widget.article.readTime,
                      isDark: widget.isDark,
                    ),
                    const Spacer(),
                    Text(
                      _cleanDate(widget.article.publishedDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.isDark
                            ? AppColors.outline
                            : AppColors.lightOnSurfaceVariant,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 6),
                    _BookmarkButton(
                      articleId: widget.article.id,
                      isDark: widget.isDark,
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
                          color: widget.isDark
                              ? AppColors.outline
                              : AppColors.lightOnSurfaceVariant,
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
                      accentColor: cardAccent,
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
    final accent = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final cleanCategory = HtmlSanitizer.clean(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        cleanCategory.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: accent,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String source;
  final bool isDark;

  const _SourceBadge({required this.source, required this.isDark});

  Color _getSourceColor() {
    if (source.contains('Reddit')) return AppColors.persimmonOrange;
    if (source.contains('Shutterstock')) return AppColors.electricIce;
    if (source.contains('Adobe')) return AppColors.vividCoral;
    return AppColors.mintSage;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSourceColor();
    final cleanSource = HtmlSanitizer.clean(source);
    final isReddit = cleanSource.contains('Reddit');
    final label = isReddit
        ? 'Reddit Community'
        : (cleanSource.length > 18
              ? '${cleanSource.substring(0, 16)}..'
              : cleanSource);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReddit ? Icons.forum_rounded : Icons.verified_rounded,
            size: 9,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
    final chipBg = isDark
        ? AppColors.surfaceContainer
        : AppColors.hairlineBorder;
    final textColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.map((tag) {
        final cleanTag = HtmlSanitizer.clean(tag);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            cleanTag.startsWith('#') ? cleanTag : '#$cleanTag',
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
              Flexible(
                child: Text(
                  isTranslated ? 'Show Original' : 'Translate (ID)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardImageThumbnail extends StatelessWidget {
  final MicrostockNewsArticle article;
  final bool isDark;

  const _CardImageThumbnail({required this.article, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final localPath = article.localImagePath;
    final hasLocal =
        localPath != null &&
        localPath.isNotEmpty &&
        File(localPath).existsSync();

    Widget imageWidget;
    if (hasLocal) {
      imageWidget = Image.file(
        File(localPath),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        article.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
      );
    } else {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(aspectRatio: 16 / 9, child: imageWidget),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: isDark
          ? AppColors.surfaceContainerHigh
          : AppColors.lightSurfaceContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 28,
        color: isDark ? AppColors.outline : AppColors.lightOnSurfaceVariant,
      ),
    );
  }
}

class _ReadTimeBadge extends StatelessWidget {
  final String readTime;
  final bool isDark;

  const _ReadTimeBadge({required this.readTime, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.outline
        : AppColors.lightOnSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceContainer : AppColors.hairlineBorder)
            .withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 9, color: textColor),
          const SizedBox(width: 3),
          Text(
            readTime,
            style: TextStyle(
              color: textColor,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  final String articleId;
  final bool isDark;

  const _BookmarkButton({required this.articleId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: UserNewsBookmarkService.bookmarkedIdsNotifier,
      builder: (context, bookmarkedIds, _) {
        final isBookmarked = bookmarkedIds.contains(articleId);
        final activeColor = isDark ? AppColors.mintSage : AppColors.forestDeep;
        final inactiveColor = isDark
            ? AppColors.outline
            : AppColors.lightOutline;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => UserNewsBookmarkService.toggleBookmark(articleId),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 16,
                color: isBookmarked ? activeColor : inactiveColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
