import 'package:flutter/material.dart';

/// Top floating capsule toast helper to avoid covering Android gesture navigation bar.
class AppToast {
  const AppToast._();

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final mediaQuery = MediaQuery.maybeOf(context);
    final screenHeight = mediaQuery?.size.height ?? 800.0;
    final bottomMargin = (screenHeight - 130.0).clamp(0.0, double.infinity);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          bottom: bottomMargin,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            width: 1,
          ),
        ),
        backgroundColor: const Color(0xFF161B22),
        duration: duration,
        content: Row(
          children: [
            Icon(
              icon ??
                  (isError
                      ? Icons.delete_outline
                      : Icons.notifications_active_outlined),
              color: isError
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
