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
/// describing the leading run. Render it only when a best run exists; the
/// caller supplies the [label] from the experiment's cached best run and skips
/// the card when there is none.
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

  /// One-line summary of [run] — its first three recorded outcomes as
  /// "name value", joined by a middot (e.g. `Sweetness 8  ·  Bitterness 2`).
  ///
  /// Returns null when there's nothing to describe (no outcomes defined, or the
  /// run carries no outcome values) — the signal to hide the banner.
  static String? labelFor(List<SchemaOutcome> outcomes, SchemaRun run) {
    final values = run.outcomeValues;
    if (outcomes.isEmpty || values == null) return null;

    final parts = outcomes
        .take(3)
        .where((o) => values[o.id] != null)
        .map((o) => '${o.name} ${MixMaxFormat.number(values[o.id])}')
        .toList();

    return parts.isEmpty ? null : parts.join('  ·  ');
  }
}
