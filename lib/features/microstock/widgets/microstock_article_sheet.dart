import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/microstock_news_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/services/user_interest_service.dart';
import '../../../core/theme/app_colors.dart';
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

  String get _displayTitle => HtmlSanitizer.clean(
    (_isTranslated && _translatedTitle != null)
        ? _translatedTitle!
        : widget.article.title,
  );

  String get _displayContent => HtmlSanitizer.clean(
    (_isTranslated && _translatedContent != null)
        ? _translatedContent!
        : (widget.article.fullContent.isNotEmpty
              ? widget.article.fullContent
              : widget.article.summary),
  );

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
    final uri = Uri.tryParse(widget.article.sourceUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
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
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _DragHandle(isDark: isDark),
            _HeaderBar(isDark: isDark, onClose: () => Navigator.of(ctx).pop()),
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
                onTranslateToggle: _toggleTranslation,
                onOpenBrowser: _launchUrl,
              ),
            ),
          ],
        ),
      ),
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
  final VoidCallback onTranslateToggle;
  final VoidCallback onOpenBrowser;

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
    required this.onTranslateToggle,
    required this.onOpenBrowser,
  });

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
            (article.imageUrl != null && article.imageUrl!.isNotEmpty)) ...[
          _ArticleHeroBanner(article: article, isDark: isDark),
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
        if (displayTakeaways.isNotEmpty) ...[
          ArticleKeyTakeawaysBox(text: displayTakeaways, isDark: isDark),
          const SizedBox(height: 18),
        ],
        Text(
          displayContent,
          style: TextStyle(color: bodyColor, fontSize: 15, height: 1.6),
        ),
        if (displaySpecs.isNotEmpty) ...[
          const SizedBox(height: 22),
          ArticleTechnicalSpecsBox(specs: displaySpecs, isDark: isDark),
        ],
        if (displayChecklist.isNotEmpty) ...[
          const SizedBox(height: 18),
          ArticleContributorChecklistBox(
            items: displayChecklist,
            isDark: isDark,
          ),
        ],
        const SizedBox(height: 24),
        ArticleFooterSourceBox(article: article, isDark: isDark),
      ],
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClose;
  const _HeaderBar({required this.isDark, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 18,
                  color: isDark ? AppColors.mintSage : AppColors.forestDeep,
                ),
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
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: isDark
                ? AppColors.onSurfaceVariant
                : AppColors.lightOnSurfaceVariant,
            onPressed: onClose,
            tooltip: 'Close reader',
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

  const _ArticleHeroBanner({required this.article, required this.isDark});

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
