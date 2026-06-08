import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/widgets/design/atoms/chip.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/round_button.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/display_text.dart';
import 'package:mix_max/widgets/design/ions/text/eyebrow_text.dart';
import 'package:mix_max/widgets/design/ions/text/section_label_text.dart';
import 'package:mix_max/widgets/design/ions/time_format.dart';
import 'package:mix_max/widgets/pages/run_details/rating_breakdown_card.dart';
import 'package:mix_max/widgets/pages/run_details/run_overall_rating_card.dart';
import 'package:mix_max/widgets/pages/suggested_run/suggestion_card.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';

/// The Run Details screen — a single completed run, reached from the Run
/// History list or from the "Best mix so far" banner on Experiment Details.
///
/// Source: `design_app/screens.jsx` `RunDetailsScreen`. It opens on a header
/// (an optional "Best run" chip, the run's number + relative/absolute time, the
/// experiment name), then the [RunOverallRatingCard] hero, the
/// [RatingBreakdownCard] that shows how the rating was reached, and finally the
/// exact mix of parameter values the run used (reusing [SuggestionCard]).
class RunDetailsPage extends StatelessWidget {
  /// The experiment the run belongs to — supplies parameter and outcome
  /// definitions used to label and score the run.
  final SchemaExperiment experiment;

  /// The run to detail.
  final SchemaRun run;

  /// 1-based chronological position, shown in the eyebrow. Null when the caller
  /// doesn't know it (e.g. opening the cached best run from Experiment Details,
  /// where the full run list isn't loaded).
  final int? number;

  /// Whether this is the experiment's highest-rated run — shows the gold chip.
  final bool isBest;

  const RunDetailsPage({
    super.key,
    required this.experiment,
    required this.run,
    this.number,
    this.isBest = false,
  });

  @override
  Widget build(BuildContext context) {
    final params = experiment.parameters ?? const [];
    final outcomes = experiment.outcomes ?? const [];
    final values = run.parameterValues ?? const <String, dynamic>{};
    final when = run.completedAt ?? run.createdAt;
    final name = experiment.name?.isNotEmpty == true
        ? experiment.name!
        : 'Untitled experiment';
    final eyebrow = _eyebrow(when);

    return OrientationScaffold(
      body: ColoredBox(
        color: AppColors.bg,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: back on the left, the "Best run" chip on the right.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MixMaxRoundButton(
                    glyph: MixMaxGlyph.arrowLeft,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  if (isBest)
                    const MixMaxChip(
                      label: 'Best run',
                      tone: MixMaxChipTone.gold,
                      icon: MixMaxGlyph.trophy,
                    ),
                ],
              ),

              const SizedBox(height: 18),
              EyebrowText(text: eyebrow, color: AppColors.gold),
              const SizedBox(height: 8),
              DisplayText(
                text: name,
                fontSize: 34,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const MixMaxIcon(
                    MixMaxGlyph.clock,
                    size: 14,
                    color: AppColors.inkFaint,
                  ),
                  const SizedBox(width: 6),
                  BodyText(
                    text: MixMaxTimeFormat.stamp(when),
                    fontSize: 13,
                  ),
                ],
              ),

              // Overall rating hero.
              const SizedBox(height: 20),
              RunOverallRatingCard(experiment: experiment, run: run),

              // Rating breakdown.
              const SizedBox(height: 28),
              _SectionHeader(
                label: 'Rating breakdown',
                count: outcomes.isEmpty ? null : outcomes.length,
              ),
              const SizedBox(height: 4),
              const BodyText(
                text: "Each outcome's score, by weight, adds up to the rating.",
                fontSize: 13,
              ),
              const SizedBox(height: 13),
              RatingBreakdownCard(experiment: experiment, run: run),

              // Parameters used.
              const SizedBox(height: 26),
              _SectionHeader(
                label: 'Parameters used',
                count: params.isEmpty ? null : params.length,
              ),
              const SizedBox(height: 4),
              const BodyText(
                text: 'The exact mix of values you tried.',
                fontSize: 13,
              ),
              const SizedBox(height: 13),
              if (params.isEmpty)
                const BodyText(text: 'No parameters set.', fontSize: 13)
              else
                for (var i = 0; i < params.length; i++) ...[
                  if (i > 0) const SizedBox(height: 11),
                  SuggestionCard(
                    parameter: params[i],
                    value: values[params[i].id],
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }

  /// The gold kicker over the title: the run number (when known) and how long
  /// ago it happened — e.g. "Run 3 · 2 days ago". Falls back to "Best run" or
  /// just the relative time when no number is available.
  String _eyebrow(int? when) {
    final rel = MixMaxTimeFormat.relative(when);
    final lead = number != null
        ? 'Run $number'
        : (isBest ? 'Best run' : null);
    if (lead == null) return rel;
    return rel.isEmpty ? lead : '$lead · $rel';
  }
}

/// The italic serif section heading with an optional faint count beside it.
///
/// Source: `ui.jsx` `SectionLabel` (serif italic label + sans count, baseline
/// aligned). Mirrors the same helper on the Experiment Details page.
class _SectionHeader extends StatelessWidget {
  final String label;
  final int? count;

  const _SectionHeader({required this.label, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SectionLabelText(text: label),
        if (count != null) ...[
          const SizedBox(width: 9),
          CaptionText(
            text: '$count',
            color: AppColors.inkFaint,
            fontWeight: FontWeight.w600,
          ),
        ],
      ],
    );
  }
}
