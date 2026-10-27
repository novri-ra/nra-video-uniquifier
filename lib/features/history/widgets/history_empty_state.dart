import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HistoryEmptyView extends StatelessWidget {
  const HistoryEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.video_library_outlined, size: 48, color: AppColors.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'No exported videos yet',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Processed videos will appear here.',
              style: TextStyle(color: AppColors.outline, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
