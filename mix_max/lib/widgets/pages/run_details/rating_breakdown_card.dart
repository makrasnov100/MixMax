import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/format.dart';

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
/// the per-row points sum to the same 0–10 rating shown in the hero card. The
/// app has no per-outcome weight yet, so every measured outcome carries an equal
/// share; the composition bar still reads as "width = weight, fill = score".
class RatingBreakdownCard extends StatelessWidget {
  final SchemaExperiment experiment;
  final SchemaRun run;

  const RatingBreakdownCard({
    Key? key,
    required this.experiment,
    required this.run,
  }) : super(key: key);

  /// Builds the per-outcome contribution rows. Weights are split equally across
  /// the outcomes that actually carry a recorded value, so the points total
  /// matches [SchemaRun.finalRating] × 10.
  List<_RatingRow> _rows() {
    final outcomes = experiment.outcomes ?? const [];
    final values = run.outcomeValues ?? const <String, double>{};

    final measured = outcomes.where((o) => values[o.id] != null).length;
    final share = measured > 0 ? 1.0 / measured : 0.0;

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
      final weight = v != null ? share : 0.0;
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
    final outcomes = experiment.outcomes ?? const [];
    final rows = _rows();
    // Use finalRating directly for the headline total so it is exactly the
    // number shown by the hero card and run-history list.
    final rating = run.finalRating(outcomes) * 10;
    final measured = rows.where((r) => r.hasValue).toList();

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
          // Composition bar: segment width = weight, fill = score.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (measured.isNotEmpty)
                  SizedBox(
                    height: 16,
                    child: Row(
                      children: [
                        for (var i = 0; i < measured.length; i++) ...[
                          if (i > 0) const SizedBox(width: 3),
                          Expanded(
                            flex: (measured[i].weight * 1000).round().clamp(1, 1 << 20),
                            child: _BarSegment(fill: measured[i].norm),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _Legend(),
                    Text(
                      'width = weight',
                      style: TextStyle(
                        fontFamily: AppFonts.sans,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                        height: 1,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const _Hairline(),

          // Per-outcome contribution rows.
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: _Hairline(),
              ),
            _OutcomeRow(row: rows[i]),
          ],

          // Final rating total.
          _TotalRow(rating: rating),
        ],
      ),
    );
  }
}

/// A single composition-bar segment: a violet-tint track filled to [fill] (the
/// outcome's 0–1 score) in solid violet.
class _BarSegment extends StatelessWidget {
  final double fill;
  const _BarSegment({required this.fill});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: ColoredBox(
        color: AppColors.violetTint,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fill.clamp(0.0, 1.0),
            heightFactor: 1,
            child: const ColoredBox(color: AppColors.violet),
          ),
        ),
      ),
    );
  }
}

/// The "■ score  ■ weight" key beneath the composition bar.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _Swatch(color: AppColors.violet),
        SizedBox(width: 6),
        _LegendLabel('score'),
        SizedBox(width: 10),
        _Swatch(color: AppColors.violetTint),
        SizedBox(width: 6),
        _LegendLabel('weight'),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  const _Swatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _LegendLabel extends StatelessWidget {
  final String text;
  const _LegendLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppFonts.sans,
        fontWeight: FontWeight.w500,
        fontSize: 11.5,
        height: 1,
        color: AppColors.inkFaint,
      ),
    );
  }
}

/// One outcome row: a violet dot, the name + weight share, the recorded value
/// pill, and the points it adds to the rating.
class _OutcomeRow extends StatelessWidget {
  final _RatingRow row;
  const _OutcomeRow({required this.row});

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
            decoration: const BoxDecoration(
              color: AppColors.violet,
              shape: BoxShape.circle,
            ),
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
          _ValuePill(value: row.value, unit: o.unit),
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

/// The recorded value as a soft violet pill, with the outcome's unit trailing.
class _ValuePill extends StatelessWidget {
  final double? value;
  final String? unit;

  const _ValuePill({required this.value, required this.unit});

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
          text: MixMaxFormat.number(value),
          style: const TextStyle(
            fontFamily: AppFonts.sans,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            height: 1,
            color: AppColors.violetText,
          ),
          children: [
            if (unit?.isNotEmpty == true)
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
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
