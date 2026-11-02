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

  const NewsSearchAndFilterBar({
    super.key,
    required this.selectedChip,
    required this.onSearchChanged,
    required this.onChipSelected,
    required this.isDark,
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
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshChips() {
    setState(() {
      _adaptiveChips = UserInterestService.getAdaptiveKeywords();
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
    final searchBg = widget.isDark ? AppColors.surfaceContainerLow : const Color(0xFFF3F4F6);
    final borderColor = widget.isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final hintColor = widget.isDark ? AppColors.outline : const Color(0xFF9CA3AF);
    final textColor = widget.isDark ? AppColors.onSurface : const Color(0xFF111827);

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
              hintText: 'Cari panduan 4K, tren, kurasi...',
              hintStyle: TextStyle(color: hintColor, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF6C5CE7)),
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
              final isSelected = widget.selectedChip.toLowerCase() == chip.toLowerCase();
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
    const accent = Color(0xFF6C5CE7);
    final unselectedBg = isDark ? const Color(0xFF232334) : const Color(0xFFF3F4F6);
    final unselectedBorder = isDark ? const Color(0xFF2E2E44) : const Color(0xFFE5E7EB);
    final unselectedText = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563);

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
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : unselectedText,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
