import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/pages/record_outcomes_page.dart';
import 'package:mix_max/services/ui/navigation_service.dart';
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
import 'package:mix_max/widgets/pages/run_details/confirm_delete_run_drawer.dart';
import 'package:mix_max/widgets/pages/run_details/rating_breakdown_card.dart';
import 'package:mix_max/widgets/pages/run_details/run_actions_drawer.dart';
import 'package:mix_max/widgets/pages/run_details/run_overall_rating_card.dart';
import 'package:mix_max/widgets/pages/share/share_run_launcher.dart';
import 'package:mix_max/widgets/pages/suggested_run/suggestion_card.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';
import 'package:mix_max/widgets/wrappers/sticky_top_bar.dart';

/// The Run Details screen — a single completed run, reached from the Run
/// History list or from the "Best mix so far" banner on Experiment Details.
///
/// Source: `design_app/screens.jsx` `RunDetailsScreen`. It opens on a header
/// (an optional "Best run" chip, the run's number + relative/absolute time, the
/// experiment name), then the [RunOverallRatingCard] hero, the
/// [RatingBreakdownCard] that shows how the rating was reached, and finally the
/// exact mix of parameter values the run used (reusing [SuggestionCard]).
///
/// The top bar's "more" button opens a [RunActionsDrawer] to rescore the run
/// (re-rating its outcomes through the [RecordOutcomesPage]) or delete it (via a
/// [ConfirmDeleteRunDrawer]). Both keep the experiment's cached best run correct
/// — a delete re-crowns from the database, a rescore re-evaluates against it.
class RunDetailsPage extends StatefulWidget {
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
  State<RunDetailsPage> createState() => _RunDetailsPageState();
}

class _RunDetailsPageState extends State<RunDetailsPage> {
  /// Tracks whether this run is currently the experiment's best. Seeded from the
  /// caller and re-derived after a rescore (which can crown or dethrone it).
  late bool _isBest = widget.isBest;

  SchemaExperiment get _experiment => widget.experiment;
  SchemaRun get _run => widget.run;

  /// Opens the "Manage this run" actions drawer (rescore / delete).
  void _showActionsDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => RunActionsDrawer(
            number: widget.number,
            onShare: _share,
            onRescore: _rescore,
            onDelete: _showConfirmDelete,
          ),
    );
  }

  /// Captures this run as a shareable image and opens the native share sheet.
  void _share() {
    RunShareLauncher.launch(
      context: context,
      experiment: _experiment,
      run: _run,
    );
  }

  /// Re-rates the run's outcomes through the record flow in rescore mode. On
  /// return the run's values are updated in place, so refresh the rating cards
  /// and re-derive whether it is still the best run.
  Future<void> _rescore() async {
    await Navigation.goTo(
      context: context,
      page: RecordOutcomesPage(
        experiment: _experiment,
        run: _run,
        rescore: true,
      ),
    );
    if (!mounted) return;
    setState(() => _isBest = _experiment.bestRun?.id == _run.id);
  }

  /// Opens the destructive confirm-delete drawer.
  void _showConfirmDelete() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => ConfirmDeleteRunDrawer(
            experiment: _experiment,
            run: _run,
            number: widget.number,
            isBest: _isBest,
            onConfirm: _delete,
          ),
    );
  }

  /// Deletes the run and returns to the previous screen. [SchemaExperiment.deleteRun]
  /// decrements the run count and, when this was the best run, re-crowns the
  /// next-highest run from the database.
  Future<void> _delete() async {
    await _experiment.deleteRun(_run);
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final experiment = _experiment;
    final run = _run;
    // Read the run from its own captured snapshot (point-in-time parameters and
    // outcomes), falling back to the experiment's current setup for legacy runs.
    final params = run.parameters ?? experiment.parameters ?? const [];
    final outcomes = run.outcomes ?? experiment.outcomes ?? const [];
    final values = run.parameterValues ?? const <String, dynamic>{};
    final when = run.completedAt ?? run.createdAt;
    final name =
        experiment.name?.isNotEmpty == true
            ? experiment.name!
            : 'Untitled experiment';
    final eyebrow = _eyebrow(when);

    return OrientationScaffold(
      body: ColoredBox(
        color: AppColors.bg,
        child: StickyTopBar(
          onBack: () => Navigator.of(context).maybePop(),
          // The "Best run" chip (when this is it) beside the "manage" button.
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isBest) ...[
                const MixMaxChip(
                  label: 'Best run',
                  tone: MixMaxChipTone.gold,
                  icon: MixMaxGlyph.trophy,
                ),
                const SizedBox(width: 10),
              ],
              MixMaxRoundButton(
                glyph: MixMaxGlyph.more,
                onTap: _showActionsDrawer,
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              StickyTopBar.contentInset,
              20,
              40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    BodyText(text: MixMaxTimeFormat.stamp(when), fontSize: 13),
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
                  text:
                      "Each outcome's score, by weight, adds up to the rating.",
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
      ),
    );
  }

  /// The gold kicker over the title: the run number (when known) and how long
  /// ago it happened — e.g. "Run 3 · 2 days ago". Falls back to "Best run" or
  /// just the relative time when no number is available.
  String _eyebrow(int? when) {
    final rel = MixMaxTimeFormat.relative(when);
    final lead =
        widget.number != null
            ? 'Run ${widget.number}'
            : (_isBest ? 'Best run' : null);
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
