import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/widgets/design/atoms/card.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';

/// One experiment row on the Experiments list — a tappable summary card.
///
/// Source: `screens.jsx` `ExperimentCard`. A white [MixMaxCard] holding the
/// experiment name (serif), a strip of "type" glyphs for its parameters and
/// outcomes, a meta line counting each, and — once runs exist — a gold
/// "Best so far" footer.
///
/// [runs] is optional because the Flutter `SchemaExperiment` does not embed its
/// runs (they live in their own collection keyed by `experimentId`). When a
/// caller has the runs in hand, pass them to light up the runs meta-bit and the
/// best-so-far footer; when omitted both are hidden, matching the design's
/// behaviour for an experiment with no runs.
class ExperimentListItem extends StatelessWidget {
  final SchemaExperiment experiment;
  final VoidCallback onTap;

  /// Recorded runs for this experiment, if known. Null/empty hides the runs
  /// count and the best-so-far footer.
  final List<SchemaRun>? runs;

  const ExperimentListItem({
    Key? key,
    required this.experiment,
    required this.onTap,
    this.runs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final params = experiment.parameters ?? const [];
    final outcomes = experiment.outcomes ?? const [];
    final runs = this.runs ?? const [];
    final best = _bestOutcomeLabel(outcomes, runs);

    return MixMaxCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + chevron.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TitleText(
                  text: experiment.name?.isNotEmpty == true
                      ? experiment.name
                      : 'Untitled experiment',
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 3, left: 12),
                child: MixMaxIcon(
                  MixMaxGlyph.chevRight,
                  size: 20,
                  color: AppColors.inkFaint,
                ),
              ),
            ],
          ),

          // Param/outcome type-glyph strip (up to 5 params + 2 outcomes).
          if (params.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final p in params.take(5))
                  MixMaxTile(
                    glyph: _glyphForType(p.type),
                    tone: MixMaxTileTone.sage,
                    size: 32,
                    radius: 9,
                  ),
                for (var i = 0; i < outcomes.length && i < 2; i++)
                  const MixMaxTile(
                    glyph: MixMaxGlyph.target,
                    tone: MixMaxTileTone.violet,
                    size: 32,
                    radius: 9,
                  ),
              ],
            ),
          ],

          // Meta counts.
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _MetaBit(
                glyph: MixMaxGlyph.hash,
                text: '${params.length} '
                    'parameter${params.length == 1 ? '' : 's'}',
              ),
              _MetaBit(
                glyph: MixMaxGlyph.target,
                text: '${outcomes.length} '
                    'outcome${outcomes.length == 1 ? '' : 's'}',
              ),
              if (this.runs != null)
                _MetaBit(
                  glyph: MixMaxGlyph.play,
                  text: '${runs.length} run${runs.length == 1 ? '' : 's'}',
                ),
            ],
          ),

          // Best-so-far footer.
          if (best != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: Row(
                children: [
                  const MixMaxIcon(
                    MixMaxGlyph.trophy,
                    size: 15,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  const CaptionText(text: 'Best so far'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CaptionText(
                      text: best,
                      color: AppColors.goldText,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single icon-plus-count fragment in the meta line.
///
/// Source: `screens.jsx` `MetaBit` (faint glyph + soft caption, weight 500).
class _MetaBit extends StatelessWidget {
  final MixMaxGlyph glyph;
  final String text;

  const _MetaBit({required this.glyph, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MixMaxIcon(glyph, size: 14, color: AppColors.inkFaint),
        const SizedBox(width: 5),
        CaptionText(text: text),
      ],
    );
  }
}

/// Parameter type → list glyph, mirroring `theme.jsx` `PARAM_TYPES`.
MixMaxGlyph _glyphForType(ParameterType? type) {
  switch (type) {
    case ParameterType.number:
      return MixMaxGlyph.hash;
    case ParameterType.duration:
      return MixMaxGlyph.timer;
    case ParameterType.toggle:
      return MixMaxGlyph.toggle;
    case ParameterType.choice:
      return MixMaxGlyph.list;
    case ParameterType.order:
      return MixMaxGlyph.order;
    case null:
      return MixMaxGlyph.hash;
  }
}

/// One-line summary of the best run, or null when there's nothing to score.
///
/// Source: `screens.jsx` `bestOutcomeLabel`. Scores each completed run as the
/// sum of its outcomes normalised into [0,1] (inverted for `minimize` goals),
/// then describes the winning run by its first three outcomes.
String? _bestOutcomeLabel(List<SchemaOutcome> outcomes, List<SchemaRun> runs) {
  final scored = runs.where((r) => r.outcomeValues != null).toList();
  if (scored.isEmpty || outcomes.isEmpty) return null;

  SchemaRun? bestRun;
  var bestScore = double.negativeInfinity;
  for (final run in scored) {
    var score = 0.0;
    for (final o in outcomes) {
      final v = run.outcomeValues![o.id];
      if (v == null) continue;
      final min = o.min ?? 0;
      final max = o.max ?? 10;
      final norm = max > min ? (v - min) / (max - min) : 0.0;
      score += o.goal == OutcomeGoal.minimize ? (1 - norm) : norm;
    }
    if (score > bestScore) {
      bestScore = score;
      bestRun = run;
    }
  }
  if (bestRun == null) return null;

  return outcomes
      .take(3)
      .map((o) => '${o.name} ${_fmt(bestRun!.outcomeValues![o.id])}')
      .join('  ·  ');
}

/// Format a number nicely, dropping a trailing `.0`. Source: `theme.jsx` `fmt`.
String _fmt(double? v) {
  if (v == null || v.isNaN) return '—';
  return v == v.truncateToDouble()
      ? v.truncate().toString()
      : v.toString();
}
