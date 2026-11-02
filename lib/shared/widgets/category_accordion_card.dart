import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CategoryAccordionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final int activeCount;
  final int totalCount;
  final bool initiallyExpanded;
  final List<Widget> children;

  const CategoryAccordionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.activeCount,
    required this.totalCount,
    this.initiallyExpanded = false,
    required this.children,
  });

  @override
  State<CategoryAccordionCard> createState() => _CategoryAccordionCardState();
}

class _CategoryAccordionCardState extends State<CategoryAccordionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final iconColor = isDark ? AppColors.primaryContainer : const Color(0xFF6C5CE7);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(widget.icon, color: iconColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    children: [
                      _ActiveBadge(activeCount: widget.activeCount, totalCount: widget.totalCount, isDark: isDark),
                      const SizedBox(width: 6),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563),
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(color: borderColor, height: 1),
            ...widget.children,
          ],
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final int activeCount, totalCount;
  final bool isDark;
  const _ActiveBadge({required this.activeCount, required this.totalCount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    final activeBg = isDark
        ? AppColors.primaryContainer.withValues(alpha: 0.15)
        : const Color(0xFF10B981).withValues(alpha: 0.12);
    final inactiveBg = isDark ? AppColors.surfaceContainer : const Color(0xFFF3F4F6);
    final activeColor = isDark ? AppColors.primaryContainer : const Color(0xFF047857);
    final inactiveColor = isDark ? AppColors.outline : const Color(0xFF6B7280);
    final borderColor = isActive
        ? (isDark ? AppColors.primaryContainer.withValues(alpha: 0.4) : const Color(0xFF10B981).withValues(alpha: 0.4))
        : (isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? activeBg : inactiveBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '$activeCount/$totalCount ACTIVE',
        style: TextStyle(
          color: isActive ? activeColor : inactiveColor,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
