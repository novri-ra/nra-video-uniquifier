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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(widget.icon, color: AppColors.primaryContainer, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: AppColors.onSurface,
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
                      _ActiveBadge(activeCount: widget.activeCount, totalCount: widget.totalCount),
                      const SizedBox(width: 6),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.onSurfaceVariant,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(color: AppColors.surfaceContainerHighest, height: 1),
            ...widget.children,
          ],
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final int activeCount, totalCount;
  const _ActiveBadge({required this.activeCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryContainer.withValues(alpha: 0.15) : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: isActive ? AppColors.primaryContainer.withValues(alpha: 0.4) : AppColors.surfaceContainerHighest,
        ),
      ),
      child: Text(
        '$activeCount/$totalCount ACTIVE',
        style: TextStyle(
          color: isActive ? AppColors.primaryContainer : AppColors.outline,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
