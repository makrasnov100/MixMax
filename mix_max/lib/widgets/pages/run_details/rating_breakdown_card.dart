import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/format.dart';
import 'package:mix_max/widgets/pages/experiment_details/weight_math.dart';

/// One outcome's contribution to a run's final rating.
class _RatingRow {
  final SchemaOutcome outcome;

  /// The recorded value, or null when this outcome wasn't measured.
  final double? value;

  /// Goal-aware score in [0, 1] (1 = best) — `0` when there's no value.
  final double norm;

  /// Share of the rating this outcome carries, in [0, 1].
  final double weight;

  /// Points contributed toward the 0–10 rating (`weight * norm * 10`).
  final double points;

  bool get hasValue => value != null;

  const _RatingRow({
    required this.outcome,
    required this.value,
    required this.norm,
    required this.weight,
    required this.points,
  });
}

/// The self-explaining rating math for a run: a weight-aware composition bar
/// over a row per outcome, closing on the gold "Final rating" total.
///
/// Source: `design_app/screens.jsx` `RatingBreakdown`. Each outcome is scored
/// 0–1 (goal-aware) exactly the way [SchemaRun.finalRating] normalises it, so
/// the per-row points sum to the same 0–10 rating shown in the hero card. Each
/// outcome's share comes from its [SchemaOutcome.weight] (the Priorities split
/// captured on the run), falling back to an equal share when the run carries no
/// weights. The composition bar is a color-coded stacked chart: each segment
/// spans its outcome's contribution to the rating (`points × 10`% of the track,
/// labelled with the points), and the rows beneath are keyed to it by the same
/// per-outcome [kWeightColors] swatch — so no separate legend is needed.
class RatingBreakdownCard extends StatelessWidget {
  final SchemaExperiment experiment;
  final SchemaRun run;

  const RatingBreakdownCard({
    Key? key,
    required this.experiment,
    required this.run,
  }) : super(key: key);

  /// Builds the per-outcome contribution rows. Each measured outcome's share is
  /// its [SchemaOutcome.weight] over the total weight of all measured outcomes —
  /// the same weighting [SchemaRun.computeFinalRating] applies — so the per-row
  /// points sum to [SchemaRun.finalRating] × 10. When every measured outcome is
  /// unweighted the shares fall back to an equal split, matching finalRating.
  /// The outcome definitions this run was scored against — its own captured
  /// snapshot, falling back to the experiment's current outcomes for legacy
  /// runs without one.
  List<SchemaOutcome> get _outcomeDefs =>
      run.outcomes ?? experiment.outcomes ?? const [];

  List<_RatingRow> _rows() {
    final outcomes = _outcomeDefs;
    final values = run.outcomeValues ?? const <String, double>{};

    // Mirror computeFinalRating: weight only the measured outcomes, falling back
    // to an equal split when their weights are all zero/absent.
    final measured = outcomes.where((o) => values[o.id] != null).toList();
    final weightSum = measured.fold<double>(
      0.0,
      (a, o) => a + (o.weight ?? 0.0),
    );
    final useEqualWeights = weightSum <= 0;
    final denom = useEqualWeights ? measured.length.toDouble() : weightSum;

    return outcomes.map((o) {
      final v = values[o.id];
      double norm = 0.0;
      if (v != null) {
        final lo = o.min, hi = o.max;
        if (lo != null && hi != null && hi > lo) {
          norm = ((v - lo) / (hi - lo)).clamp(0.0, 1.0);
        } else {
          norm = v; // No usable bounds — mirror finalRating's raw fallback.
        }
        if (o.goal == OutcomeGoal.minimize) norm = 1.0 - norm;
      }
      final raw = useEqualWeights ? 1.0 : (o.weight ?? 0.0);
      final weight = (v != null && denom > 0) ? raw / denom : 0.0;
      return _RatingRow(
        outcome: o,
        value: v,
        norm: norm,
        weight: weight,
        points: weight * norm * 10,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    // Use finalRating directly for the headline total so it is exactly the
    // number shown by the hero card and run-history list, scored against the
    // run's own outcome snapshot.
    final rating =
        (run.outcomes != null
            ? run.computeFinalRating()
            : run.computeFinalRating(experiment.outcomes ?? const [])) *
        10;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20), // rCard
        border: Border.all(color: AppColors.hairline, width: 1),
        boxShadow: _cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Composition bar: a color-coded stacked chart whose segments each
          // span their outcome's contribution to the rating.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: _CompositionBar(rows: rows),
          ),
          const _Hairline(),

          // Per-outcome contribution rows, keyed to the bar by swatch colour.
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: _Hairline(),
              ),
            _OutcomeRow(row: rows[i], color: weightColorAt(i)),
          ],

          // Final rating total.
          _TotalRow(rating: rating),
        ],
      ),
    );
  }
}

/// The color-coded stacked rating bar: one rounded track whose colored segments
/// each span their outcome's contribution to the 0–10 rating (`points × 10`% of
/// the full width), labelled with that contribution. Outcomes that add nothing
/// (unmeasured, or scoring zero) contribute no segment; the unfilled warm
/// remainder reads as the rating's distance from a perfect 10.
///
/// Source: `design_app/screens.jsx` `RatingBreakdown` composition bar.
class _CompositionBar extends StatelessWidget {
  final List<_RatingRow> rows;
  const _CompositionBar({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.bgAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      // Measure the track so segments get real pixel widths: any nonzero
      // contribution renders at least [_kMinSegmentPx] wide, so even a sliver
      // is visible. The unfilled remainder reads as the warm track background.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final track = constraints.maxWidth;
          final segments = <Widget>[];
          for (var i = 0; i < rows.length; i++) {
            if (rows[i].points <= 0) continue; // adds nothing — no segment.
            final ideal = (rows[i].points / 10).clamp(0.0, 1.0) * track;
            final width = ideal < _kMinSegmentPx ? _kMinSegmentPx : ideal;
            segments.add(
              SizedBox(
                width: width,
                child: _BarSegment(
                  color: weightColorAt(i),
                  // Only label a segment wide enough to actually read it.
                  label:
                      ideal >= _kLabelMinPx
                          ? MixMaxFormat.number(rows[i].points, decimals: 1)
                          : null,
                ),
              ),
            );
          }
          // Stretch so each segment fills the track height — a label-less
          // sliver's ColoredBox would otherwise collapse to zero height.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: segments,
          );
        },
      ),
    );
  }
}

/// Minimum rendered width (px) for any segment carrying a real contribution, so
/// a tiny share still shows as a visible colored sliver. Tweak to taste.
const double _kMinSegmentPx = 1;

/// A segment must be at least this wide (px) before its points number is drawn.
const double _kLabelMinPx = 26;

/// One stacked-bar segment: a solid [color] block, captioned with its points
/// [label] in white when it is wide enough to read.
class _BarSegment extends StatelessWidget {
  final Color color;
  final String? label;
  const _BarSegment({required this.color, this.label});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child:
          label == null
              ? null
              : Center(
                child: Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: const TextStyle(
                    fontFamily: AppFonts.sans,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    height: 1,
                    letterSpacing: 11 * -0.01,
                    color: Colors.white,
                  ),
                ),
              ),
    );
  }
}

/// One outcome row: a swatch dot matching its bar segment, the name + weight
/// share, the recorded value pill, and the points it adds to the rating.
class _OutcomeRow extends StatelessWidget {
  final _RatingRow row;
  final Color color;
  const _OutcomeRow({required this.row, required this.color});

  @override
  Widget build(BuildContext context) {
    final o = row.outcome;
    final maximize = o.goal != OutcomeGoal.minimize;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  o.name?.isNotEmpty == true ? o.name! : 'Untitled outcome',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.sans,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    height: 1.1,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MixMaxIcon(
                      maximize ? MixMaxGlyph.up : MixMaxGlyph.down,
                      size: 12,
                      color: AppColors.inkFaint,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${(row.weight * 100).round()}% weight',
                      style: const TextStyle(
                        fontFamily: AppFonts.sans,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        height: 1,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ValuePill(
            value: row.value,
            max: o.max ?? 10,
            unit: o.unit,
            step: o.step,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Text(
              '+${MixMaxFormat.number(row.points, decimals: 1)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: AppFonts.sans,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                height: 1,
                color: AppColors.goldText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The recorded value as a soft violet pill, shown as `value / max` so the
/// total possible is visible alongside what was scored (mirrors the share
/// card's value pill), with the outcome's unit trailing.
class _ValuePill extends StatelessWidget {
  final double? value;
  final double max;
  final String? unit;
  final double? step;

  const _ValuePill({
    required this.value,
    required this.max,
    required this.unit,
    this.step,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.violetTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text.rich(
        TextSpan(
          text: value == null ? '—' : MixMaxFormat.number(value, step: step),
          style: const TextStyle(
            fontFamily: AppFonts.sans,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            height: 1,
            color: AppColors.violetText,
          ),
          children: [
            TextSpan(
              text: ' / ${MixMaxFormat.number(max)}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: AppColors.inkFaint,
              ),
            ),
            if (unit?.isNotEmpty == true)
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: AppColors.violetText,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The closing gold row summing every outcome's points into the run's rating.
class _TotalRow extends StatelessWidget {
  final double rating;
  const _TotalRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.goldTint,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          const MixMaxIcon(MixMaxGlyph.trophy, size: 16, color: AppColors.gold),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'Final rating',
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1,
                color: AppColors.goldText,
              ),
            ),
          ),
          Text(
            MixMaxFormat.number(rating, decimals: 1),
            style: const TextStyle(
              fontFamily: AppFonts.serif,
              fontWeight: FontWeight.w500,
              fontSize: 22,
              height: 1,
              letterSpacing: 22 * -0.01,
              color: AppColors.goldDeep,
            ),
          ),
        ],
      ),
    );
  }
}

/// A 1px warm hairline rule.
class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.hairline);
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
