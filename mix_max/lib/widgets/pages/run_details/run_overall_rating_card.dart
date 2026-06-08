import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/format.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/eyebrow_text.dart';

/// The hero rating panel at the top of the Run Details page — a single big
/// serif number with a short note on how it was reached.
///
/// Source: `design_app/screens.jsx` `RunDetailsScreen` "overall rating hero".
/// The number is the run's [SchemaRun.finalRating] scaled to a 0–10 scale (the
/// same value the run-history card and rating breakdown show), so the three
/// stay in lockstep.
class RunOverallRatingCard extends StatelessWidget {
  final SchemaExperiment experiment;
  final SchemaRun run;

  const RunOverallRatingCard({
    Key? key,
    required this.experiment,
    required this.run,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final outcomes = experiment.outcomes ?? const [];
    final rating = run.finalRating(outcomes) * 10;
    final count = outcomes.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20), // rCard
        border: Border.all(color: AppColors.hairline, width: 1),
        boxShadow: _cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            MixMaxFormat.number(rating, decimals: 1),
            style: const TextStyle(
              fontFamily: AppFonts.serif,
              fontWeight: FontWeight.w500,
              fontSize: 56,
              height: 1,
              letterSpacing: 56 * -0.02,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const EyebrowText(
                  text: 'Overall rating',
                  color: AppColors.inkFaint,
                ),
                const SizedBox(height: 4),
                BodyText(
                  text:
                      'Averaged across $count outcome${count == 1 ? '' : 's'}.',
                  fontSize: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// CARD_SHADOW — '0 1px 2px rgba(34,31,42,0.04), 0 8px 22px -12px rgba(34,31,42,0.10)'
const List<BoxShadow> _cardShadow = [
  BoxShadow(color: Color(0x0A221F2A), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(
    color: Color(0x1A221F2A),
    offset: Offset(0, 8),
    blurRadius: 22,
    spreadRadius: -12,
  ),
];
