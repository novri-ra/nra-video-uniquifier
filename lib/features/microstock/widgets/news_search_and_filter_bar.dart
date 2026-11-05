import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/user_interest_service.dart';
import '../../../core/theme/app_colors.dart';

/// Search input bar with debouncing and horizontal YouTube-style keyword filter chips carousel.
class NewsSearchAndFilterBar extends StatefulWidget {
  final String selectedChip;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onChipSelected;
  final bool isDark;
  final List<String>? categories;

  const NewsSearchAndFilterBar({
    super.key,
    required this.selectedChip,
    required this.onSearchChanged,
    required this.onChipSelected,
    required this.isDark,
    this.categories,
  });

  @override
  State<NewsSearchAndFilterBar> createState() => _NewsSearchAndFilterBarState();
}

class _NewsSearchAndFilterBarState extends State<NewsSearchAndFilterBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<String> _adaptiveChips = [];

  @override
  void initState() {
    super.initState();
    _refreshChips();
  }

  @override
  void didUpdateWidget(covariant NewsSearchAndFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categories != oldWidget.categories) {
      _refreshChips();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshChips() {
    setState(() {
      final base = (widget.categories != null && widget.categories!.isNotEmpty)
          ? UserInterestService.getSortedDynamicCategories(widget.categories!)
          : UserInterestService.getAdaptiveKeywords();

      final list = <String>[];
      for (final item in base) {
        list.add(item);
        if (item.toLowerCase() == 'all') {
          list.add('Saved');
        }
      }
      if (!list.contains('Saved')) {
        list.insert(list.isNotEmpty ? 1 : 0, 'Saved');
      }
      _adaptiveChips = list;
    });
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onSearchChanged(query);
      if (query.trim().length >= 3) {
        UserInterestService.recordSearch(query);
        _refreshChips();
      }
    });
    setState(() {});
  }

  void _onClear() {
    _searchController.clear();
    widget.onSearchChanged('');
    setState(() {});
  }

  void _handleChipTap(String chip) {
    widget.onChipSelected(chip);
    UserInterestService.recordChipClick(chip);
    _refreshChips();
  }

  @override
  Widget build(BuildContext context) {
    final searchBg = widget.isDark ? AppColors.obsidianDark : AppColors.white;
    final borderColor = widget.isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;
    final hintColor = widget.isDark
        ? AppColors.outline
        : AppColors.lightOnSurfaceVariant;
    final textColor = widget.isDark
        ? AppColors.onSurface
        : AppColors.lightOnSurface;
    final searchAccent = widget.isDark
        ? AppColors.mintSage
        : AppColors.forestDeep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: searchBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onQueryChanged,
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                UserInterestService.recordSearch(val);
                _refreshChips();
              }
            },
            style: TextStyle(color: textColor, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Search 4K guides, trends, curation...',
              hintStyle: TextStyle(color: hintColor, fontSize: 13),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: searchAccent,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: hintColor,
                      onPressed: _onClear,
                      tooltip: 'Clear search',
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _adaptiveChips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final chip = _adaptiveChips[index];
              final isSelected =
                  widget.selectedChip.toLowerCase() == chip.toLowerCase();
              return _AdaptiveFilterChip(
                label: chip,
                isSelected: isSelected,
                isDark: widget.isDark,
                onTap: () => _handleChipTap(chip),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdaptiveFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _AdaptiveFilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final unselectedBg = isDark
        ? AppColors.obsidianDark
        : AppColors.hairlineBorder;
    final unselectedBorder = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;
    final unselectedText = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final selectedText = isDark ? AppColors.obsidianBase : AppColors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent : unselectedBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accent : unselectedBorder,
            width: isSelected ? 1.2 : 0.8,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: accent.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label == 'Saved') ...[
                Icon(
                  isSelected
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 13,
                  color: isSelected ? selectedText : unselectedText,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? selectedText : unselectedText,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
