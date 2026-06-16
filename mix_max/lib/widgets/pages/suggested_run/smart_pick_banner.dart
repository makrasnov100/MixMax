import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tap_ripple.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';

/// The gold-tinted explainer on the Suggested Run page — a spark glyph beside a
/// one-line note that these parameters were tuned from the experiment's past
/// runs.
///
/// When the user has frozen any values (committed an edit that differs from the
/// optimizer's pick), the note instead mentions the frozen values — the frozen
/// cards themselves show *which* ones — and, if [onRetune] is supplied, a
/// centered "Retune parameters" action appears at the banner's bottom to
/// re-suggest everything else around them.
///
/// Source: `design_app/screens.jsx` `RunSuggestionScreen` smart-pick explainer.
class SmartPickBanner extends StatelessWidget {
  /// Whether any suggested values are currently frozen by the user.
  final bool hasFrozenValues;

  /// Re-runs the optimizer treating the frozen values as fixed. The action is
  /// shown only when non-null and at least one value is frozen.
  final VoidCallback? onRetune;

  const SmartPickBanner({Key? key, this.hasFrozenValues = false, this.onRetune})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final message =
        hasFrozenValues
            ? 'Tuned from your past runs, values frozen by you stay exactly as you set them.'
            : 'Tuned from your past runs to learn the most this time.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const MixMaxIcon(
                MixMaxGlyph.spark2,
                size: 19,
                color: AppColors.gold,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: BodyText(
                  text: message,
                  color: AppColors.goldText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (hasFrozenValues && onRetune != null) ...[
            const SizedBox(height: 12),
            Center(child: _RetuneButton(onTap: onRetune!)),
          ],
        ],
      ),
    );
  }
}

/// The gold pill at the banner's bottom center: a sparkle glyph and a label
/// that re-tunes the remaining parameters around the user's frozen values.
class _RetuneButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RetuneButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: MixMaxInk(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MixMaxIcon(MixMaxGlyph.sparkle, size: 15, color: Colors.white),
              SizedBox(width: 6),
              CaptionText(
                text: 'Retune values',
                fontSize: 12.5,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
