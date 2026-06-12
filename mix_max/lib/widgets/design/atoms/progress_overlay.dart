import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';

/// A dimmed, tap-blocking full-screen progress overlay: scrim over the whole
/// screen (including any open drawer) with a centered spinner-and-message
/// card. Extracted from the share launcher's "Preparing your image…" overlay
/// so every long-running action blocks and reads the same way.
class MixMaxProgressOverlay extends StatelessWidget {
  final String message;

  const MixMaxProgressOverlay({super.key, required this.message});

  /// Inserts the overlay above everything (root overlay, so it covers modal
  /// sheets too) and returns the entry; the caller removes it when done.
  static OverlayEntry show(BuildContext context, {required String message}) {
    final entry = OverlayEntry(
      builder: (_) => MixMaxProgressOverlay(message: message),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    return entry;
  }

  /// Runs [operation] under the overlay — shown before the first await,
  /// removed when the future settles (success or error).
  static Future<T> during<T>({
    required BuildContext context,
    required String message,
    required Future<T> Function() operation,
  }) async {
    final entry = show(context, message: message);
    try {
      return await operation();
    } finally {
      entry.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: AppColors.scrim),
        Center(
          // A Material ancestor so the caption renders cleanly (without one,
          // debug builds paint the yellow "missing Material" underline).
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.hairline, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(AppColors.gold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  BodyText(text: message, color: AppColors.ink),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
