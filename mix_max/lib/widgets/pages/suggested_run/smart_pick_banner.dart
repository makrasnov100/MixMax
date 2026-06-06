import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';

/// The gold-tinted explainer on the Suggested Run page — a spark glyph beside a
/// one-line note that these parameters were tuned from the experiment's past
/// runs.
///
/// Source: `design_app/screens.jsx` `RunSuggestionScreen` smart-pick explainer.
class SmartPickBanner extends StatelessWidget {
  final String message;

  const SmartPickBanner({
    Key? key,
    this.message = 'Tuned from your past runs to learn the most this time.',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const MixMaxIcon(MixMaxGlyph.spark2, size: 19, color: AppColors.gold),
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
    );
  }
}
