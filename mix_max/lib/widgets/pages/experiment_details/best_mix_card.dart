import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/format.dart';
import 'package:mix_max/widgets/design/ions/text/eyebrow_text.dart';
import 'package:mix_max/widgets/design/ions/text/label_text.dart';

/// The gold "Best mix so far" banner pinned to the top of the Experiment
/// Details page once a winning run has been determined.
///
/// Source: `screens.jsx` best-so-far block. A gold-tinted rounded panel with a
/// trophy tile, the "BEST MIX SO FAR" eyebrow, and a one-line [label]
/// describing the leading run. Render it only when a best run exists — compute
/// the description with [BestMixCard.bestLabel] and skip the card when it
/// returns null.
class BestMixCard extends StatelessWidget {
  /// One-line description of the best run (e.g. `Sweetness 8  ·  Bitterness 2`).
  final String label;

  const BestMixCard({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: BorderRadius.circular(20), // rCard
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const MixMaxTile(glyph: MixMaxGlyph.trophy, tone: MixMaxTileTone.gold),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const EyebrowText(text: 'Best mix so far', color: AppColors.goldText),
                const SizedBox(height: 3),
                LabelText(text: label, fontSize: 15, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One-line summary of the best run, or null when there's nothing to score.
  ///
  /// Source: `screens.jsx` `bestOutcomeLabel`. Scores each completed run as the
  /// sum of its outcomes normalised into [0,1] (inverted for `minimize` goals),
  /// then describes the winning run by its first three outcomes. Returns null
  /// when there are no completed runs or no outcomes — the signal to hide the
  /// card.
  static String? bestLabel(List<SchemaOutcome> outcomes, List<SchemaRun> runs) {
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
        .map((o) => '${o.name} ${MixMaxFormat.number(bestRun!.outcomeValues![o.id])}')
        .join('  ·  ');
  }
}
