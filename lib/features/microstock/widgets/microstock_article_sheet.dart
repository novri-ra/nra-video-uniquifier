import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/microstock_news_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/services/user_interest_service.dart';
import '../../../core/theme/app_colors.dart';
import '../services/article_reader_extractor.dart';
import '../services/user_news_bookmark_service.dart';
import '../utils/html_sanitizer.dart';
import 'microstock_article_content_blocks.dart';
import 'microstock_article_footer_widgets.dart';

/// Full article reader modal bottom sheet for Microstock Intel & Trends.
class MicrostockArticleSheet extends StatefulWidget {
  final MicrostockNewsArticle article;
  final bool isDark;

  const MicrostockArticleSheet({
    super.key,
    required this.article,
    required this.isDark,
  });

  static void show(
    BuildContext context,
    MicrostockNewsArticle article,
    bool isDark,
  ) {
    UserInterestService.recordArticleRead(article);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          MicrostockArticleSheet(article: article, isDark: isDark),
    );
  }

  @override
  State<MicrostockArticleSheet> createState() => _MicrostockArticleSheetState();
}

class _MicrostockArticleSheetState extends State<MicrostockArticleSheet> {
  bool _isTranslated = false;
  bool _isTranslating = false;
  String? _translatedTitle;
  String? _translatedContent;
  String? _translatedTakeaways;
  List<String>? _translatedSpecs;
  List<String>? _translatedChecklist;

  double _fontSizeMultiplier = 1.0;
  double _scrollProgress = 0.0;
  ScrollController? _activeScrollController;

  // On-demand reader extraction state
  bool _isExtracting = false;
  String? _extractedContent;
  String? _extractedImageUrl;
  bool _extractionAttempted = false;

  void _onScroll() {
    if (_activeScrollController == null ||
        !_activeScrollController!.hasClients) {
      return;
    }
    final maxScroll = _activeScrollController!.position.maxScrollExtent;
    final currentScroll = _activeScrollController!.offset;
    if (maxScroll > 0) {
      final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      if ((progress - _scrollProgress).abs() > 0.01) {
        setState(() => _scrollProgress = progress);
      }
    }
  }

  void _increaseFontSize() {
    setState(() {
      _fontSizeMultiplier = (_fontSizeMultiplier + 0.1).clamp(0.85, 1.35);
    });
  }

  void _decreaseFontSize() {
    setState(() {
      _fontSizeMultiplier = (_fontSizeMultiplier - 0.1).clamp(0.85, 1.35);
    });
  }

  bool get _needsExtraction {
    final fc = widget.article.fullContent;
    return fc.trim() == widget.article.title.trim() ||
        fc.length < 120 ||
        fc.contains('[Read More]') ||
        fc.contains('Read more...');
  }

  bool get _isSyntheticArticle =>
      widget.article.id.startsWith('rss-') ||
      widget.article.id.startsWith('reddit-');

  @override
  void initState() {
    super.initState();
    if (_isSyntheticArticle && _needsExtraction) {
      _tryExtractContent();
    }
  }

  Future<void> _tryExtractContent() async {
    if (_extractionAttempted || !mounted) return;
    _extractionAttempted = true;
    setState(() => _isExtracting = true);

    final url = widget.article.sourceUrl;
    if (url.isEmpty) {
      if (mounted) setState(() => _isExtracting = false);
      return;
    }

    final result = await ArticleReaderExtractor.extract(url);
    if (!mounted) return;

    if (result != null && result.paragraphs.isNotEmpty) {
      _extractedContent = result.paragraphs;
      _extractedImageUrl = result.heroImageUrl;

      // Persist extracted content to cache
      final updated = widget.article.copyWith(
        fullContent: result.paragraphs,
        imageUrl: result.heroImageUrl ?? widget.article.imageUrl,
      );
      MicrostockNewsService.saveNewsToCache([updated]);
    }
    setState(() => _isExtracting = false);
  }

  String get _displayTitle => HtmlSanitizer.clean(
    (_isTranslated && _translatedTitle != null)
        ? _translatedTitle!
        : widget.article.title,
  );

  String get _displayContent {
    // Use extracted on-demand content if available
    final base =
        _extractedContent ??
        (widget.article.fullContent.isNotEmpty
            ? widget.article.fullContent
            : widget.article.summary);
    final raw = (_isTranslated && _translatedContent != null)
        ? _translatedContent!
        : base;
    return HtmlSanitizer.clean(raw);
  }

  String get _displayTakeaways => HtmlSanitizer.clean(
    (_isTranslated && _translatedTakeaways != null)
        ? _translatedTakeaways!
        : widget.article.keyTakeaways,
  );

  List<String> get _displaySpecs => (_isTranslated && _translatedSpecs != null)
      ? _translatedSpecs!.map(HtmlSanitizer.clean).toList()
      : widget.article.technicalSpecs.map(HtmlSanitizer.clean).toList();

  List<String> get _displayChecklist =>
      (_isTranslated && _translatedChecklist != null)
      ? _translatedChecklist!.map(HtmlSanitizer.clean).toList()
      : widget.article.contributorChecklist.map(HtmlSanitizer.clean).toList();

  Future<void> _toggleTranslation() async {
    if (_isTranslated) {
      setState(() => _isTranslated = false);
      return;
    }
    if (_translatedTitle != null && _translatedContent != null) {
      setState(() => _isTranslated = true);
      return;
    }

    setState(() => _isTranslating = true);
    try {
      await _executeTranslation();
    } catch (_) {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _executeTranslation() async {
    final tTitle = await TranslationService.translateText(
      widget.article.title,
      targetLang: 'id',
    );
    final raw = widget.article.fullContent.isNotEmpty
        ? widget.article.fullContent
        : widget.article.summary;
    final tContent = await TranslationService.translateLongText(
      raw,
      targetLang: 'id',
    );

    final tTakeaways = widget.article.keyTakeaways.isNotEmpty
        ? await TranslationService.translateText(
            widget.article.keyTakeaways,
            targetLang: 'id',
          )
        : null;

    final tSpecs = widget.article.technicalSpecs.isNotEmpty
        ? await Future.wait(
            widget.article.technicalSpecs.map(
              (s) => TranslationService.translateText(s, targetLang: 'id'),
            ),
          )
        : <String>[];

    final tCheck = widget.article.contributorChecklist.isNotEmpty
        ? await Future.wait(
            widget.article.contributorChecklist.map(
              (c) => TranslationService.translateText(c, targetLang: 'id'),
            ),
          )
        : <String>[];

    if (mounted) {
      setState(() {
        _translatedTitle = tTitle;
        _translatedContent = tContent;
        _translatedTakeaways = tTakeaways;
        _translatedSpecs = tSpecs;
        _translatedChecklist = tCheck;
        _isTranslated = true;
        _isTranslating = false;
      });
      UserInterestService.recordTranslateToggle(widget.article, 'id');
    }
  }

  Future<void> _launchUrl() async {
    UserInterestService.recordOpenSourceUrl(widget.article);
    final uri = Uri.tryParse(widget.article.sourceUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _activeScrollController?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? AppColors.obsidianDark : AppColors.white;
    final borderColor = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        if (_activeScrollController != scrollController) {
          _activeScrollController?.removeListener(_onScroll);
          _activeScrollController = scrollController;
          _activeScrollController!.addListener(_onScroll);
        }

        final progressAccent = isDark
            ? AppColors.mintSage
            : AppColors.forestDeep;
        final progressTrack = isDark
            ? AppColors.surfaceContainer
            : AppColors.hairlineBorder;

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _DragHandle(isDark: isDark),
              _HeaderBar(
                articleId: widget.article.id,
                isDark: isDark,
                onClose: () => Navigator.of(ctx).pop(),
                fontSizeMultiplier: _fontSizeMultiplier,
                onIncreaseFont: _increaseFontSize,
                onDecreaseFont: _decreaseFontSize,
              ),
              LinearProgressIndicator(
                value: _scrollProgress,
                minHeight: 2.5,
                backgroundColor: progressTrack,
                valueColor: AlwaysStoppedAnimation<Color>(progressAccent),
              ),
              const Divider(height: 1, thickness: 0.5),
              Expanded(
                child: _ArticleContentList(
                  scrollController: scrollController,
                  article: widget.article,
                  displayTitle: _displayTitle,
                  displayContent: _displayContent,
                  displayTakeaways: _displayTakeaways,
                  displaySpecs: _displaySpecs,
                  displayChecklist: _displayChecklist,
                  isTranslated: _isTranslated,
                  isTranslating: _isTranslating,
                  isDark: isDark,
                  fontSizeMultiplier: _fontSizeMultiplier,
                  onTranslateToggle: _toggleTranslation,
                  onOpenBrowser: _launchUrl,
                  isExtracting: _isExtracting,
                  extractedImageUrl: _extractedImageUrl,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  final bool isDark;
  const _DragHandle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.outlineVariant
            : AppColors.lightOutlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _ArticleContentList extends StatelessWidget {
  final ScrollController scrollController;
  final MicrostockNewsArticle article;
  final String displayTitle;
  final String displayContent;
  final String displayTakeaways;
  final List<String> displaySpecs;
  final List<String> displayChecklist;
  final bool isTranslated;
  final bool isTranslating;
  final bool isDark;
  final double fontSizeMultiplier;
  final VoidCallback onTranslateToggle;
  final VoidCallback onOpenBrowser;
  final bool isExtracting;
  final String? extractedImageUrl;

  const _ArticleContentList({
    required this.scrollController,
    required this.article,
    required this.displayTitle,
    required this.displayContent,
    required this.displayTakeaways,
    required this.displaySpecs,
    required this.displayChecklist,
    required this.isTranslated,
    required this.isTranslating,
    required this.isDark,
    required this.fontSizeMultiplier,
    required this.onTranslateToggle,
    required this.onOpenBrowser,
    this.isExtracting = false,
    this.extractedImageUrl,
  });

  bool get _isSyntheticArticle =>
      article.id.startsWith('rss-') || article.id.startsWith('reddit-');

  /// Effective image URL: original or on-demand extracted og:image fallback.
  String? get _effectiveImageUrl =>
      (article.imageUrl != null && article.imageUrl!.isNotEmpty)
      ? article.imageUrl
      : extractedImageUrl;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final bodyColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        ArticleMetaTagsRow(article: article, isDark: isDark),
        const SizedBox(height: 14),
        if ((article.localImagePath != null &&
                article.localImagePath!.isNotEmpty) ||
            _effectiveImageUrl != null) ...[
          _ArticleHeroBanner(
            article: article,
            isDark: isDark,
            fallbackImageUrl: extractedImageUrl,
          ),
          const SizedBox(height: 14),
        ],
        Text(
          displayTitle,
          style: TextStyle(
            color: titleColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        _ActionToolbar(
          isTranslated: isTranslated,
          isTranslating: isTranslating,
          onTranslateToggle: onTranslateToggle,
          onOpenBrowser: onOpenBrowser,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        if (!_isSyntheticArticle && displayTakeaways.isNotEmpty) ...[
          ArticleKeyTakeawaysBox(text: displayTakeaways, isDark: isDark),
          const SizedBox(height: 18),
        ],
        if (isExtracting) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? AppColors.mintSage : AppColors.forestDeep,
                ),
              ),
            ),
          ),
        ] else ...[
          for (final paragraph in displayContent.split(RegExp(r'\n{1,2}')))
            if (paragraph.trim().isNotEmpty) ...[
              Text(
                paragraph.trim(),
                style: TextStyle(
                  color: bodyColor,
                  fontSize: 15 * fontSizeMultiplier,
                  height: 1.6,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 14),
            ],
          // Fallback hint for thin RSS content
          if (_isSyntheticArticle &&
              displayContent.trim() == article.title.trim()) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (isDark
                            ? AppColors.surfaceContainer
                            : AppColors.hairlineBorder)
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Ringkasan singkat. Ketuk "Buka Sumber" untuk membaca artikel lengkap di ${article.source}.',
                style: TextStyle(
                  color: isDark
                      ? AppColors.outline
                      : AppColors.lightOnSurfaceVariant,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
        if (!_isSyntheticArticle && displaySpecs.isNotEmpty) ...[
          const SizedBox(height: 8),
          ArticleTechnicalSpecsBox(specs: displaySpecs, isDark: isDark),
          const SizedBox(height: 14),
        ],
        if (!_isSyntheticArticle && displayChecklist.isNotEmpty) ...[
          const SizedBox(height: 4),
          ArticleContributorChecklistBox(
            items: displayChecklist,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 10),
        ArticleFooterSourceBox(
          article: article,
          isDark: isDark,
          isExternalSource: _isSyntheticArticle,
        ),
      ],
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final String articleId;
  final bool isDark;
  final VoidCallback onClose;
  final double fontSizeMultiplier;
  final VoidCallback onIncreaseFont;
  final VoidCallback onDecreaseFont;

  const _HeaderBar({
    required this.articleId,
    required this.isDark,
    required this.onClose,
    required this.fontSizeMultiplier,
    required this.onIncreaseFont,
    required this.onDecreaseFont,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final activeAccent = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, size: 18, color: activeAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'MICROSTOCK INTEL READER',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark
                    ? AppColors.outline
                    : AppColors.lightOnSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          // Font size controls (A- / A+)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color:
                  (isDark
                          ? AppColors.surfaceContainer
                          : AppColors.hairlineBorder)
                      .withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onDecreaseFont,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: Text(
                      'A-',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: fontSizeMultiplier <= 0.86
                            ? iconColor.withValues(alpha: 0.4)
                            : iconColor,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 10,
                  color: isDark
                      ? AppColors.outlineVariant
                      : AppColors.lightOutlineVariant,
                ),
                InkWell(
                  onTap: onIncreaseFont,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: Text(
                      'A+',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: fontSizeMultiplier >= 1.34
                            ? iconColor.withValues(alpha: 0.4)
                            : iconColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Bookmark toggle
          ValueListenableBuilder<Set<String>>(
            valueListenable: UserNewsBookmarkService.bookmarkedIdsNotifier,
            builder: (context, bookmarkedIds, _) {
              final isBookmarked = bookmarkedIds.contains(articleId);
              return IconButton(
                icon: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 20,
                  color: isBookmarked ? activeAccent : iconColor,
                ),
                onPressed: () =>
                    UserNewsBookmarkService.toggleBookmark(articleId),
                tooltip: isBookmarked ? 'Hapus simpanan' : 'Simpan artikel',
                visualDensity: VisualDensity.compact,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: iconColor,
            onPressed: onClose,
            tooltip: 'Close reader',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ActionToolbar extends StatelessWidget {
  final bool isTranslated;
  final bool isTranslating;
  final VoidCallback onTranslateToggle;
  final VoidCallback onOpenBrowser;
  final bool isDark;

  const _ActionToolbar({
    required this.isTranslated,
    required this.isTranslating,
    required this.onTranslateToggle,
    required this.onOpenBrowser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        ArticleTranslateButton(
          isTranslated: isTranslated,
          isTranslating: isTranslating,
          onTap: onTranslateToggle,
        ),
        TextButton.icon(
          onPressed: onOpenBrowser,
          icon: const Icon(Icons.open_in_browser_rounded, size: 15),
          label: const Text('Buka Sumber', style: TextStyle(fontSize: 11)),
          style: TextButton.styleFrom(
            foregroundColor: isDark ? AppColors.mintSage : AppColors.forestDeep,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _ArticleHeroBanner extends StatelessWidget {
  final MicrostockNewsArticle article;
  final bool isDark;
  final String? fallbackImageUrl;

  const _ArticleHeroBanner({
    required this.article,
    required this.isDark,
    this.fallbackImageUrl,
  });

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
    } else if (fallbackImageUrl != null && fallbackImageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        fallbackImageUrl!,
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
      borderRadius: BorderRadius.circular(12),
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
        size: 36,
        color: isDark ? AppColors.outline : AppColors.lightOnSurfaceVariant,
      ),
    );
  }
}
