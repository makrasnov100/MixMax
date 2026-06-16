import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/widgets/design/atoms/card.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tap_ripple.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/pages/experiment_details/weight_math.dart';

/// The Priorities card: a weight donut over a normalize banner, then one
/// coloured weight slider per outcome. Lets the user split a 100% budget across
/// the experiment's outcomes; each weight is saved to the outcome itself and
/// tunes how much it counts toward a run's rating.
///
/// Source: `design_app/screens.jsx` `PrioritiesSection` (+ `WeightDonut`,
/// `RemainingBanner`, `WeightSlider`). Reports each drag through [onSetWeight]
/// (the page debounces the save) and the one-tap rebalance through
/// [onNormalize].
class PrioritiesSection extends StatelessWidget {
  final List<SchemaOutcome> outcomes;

  /// Called as a slider is dragged with the outcome id and its new 0–100 weight.
  final void Function(String outcomeId, double weight) onSetWeight;

  /// Called when the "Normalize to 100%" banner is tapped.
  final VoidCallback onNormalize;

  const PrioritiesSection({
    Key? key,
    required this.outcomes,
    required this.onSetWeight,
    required this.onNormalize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final weights =
        outcomes.map((o) => o.weight ?? 0.0).toList(growable: false);
    final sum = weights.fold<double>(0.0, (a, b) => a + b);
    final remaining = 100 - sum;

    return MixMaxCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Donut + normalize banner.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WeightDonut(
                  slices: [
                    for (var i = 0; i < outcomes.length; i++)
                      _DonutSlice(color: weightColorAt(i), value: weights[i]),
                  ],
                  total: sum,
                ),
                const SizedBox(height: 14),
                _RemainingBanner(
                  remaining: remaining,
                  onNormalize: onNormalize,
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.hairline),

          // One weighted slider per outcome.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < outcomes.length; i++)
                  _OutcomeWeightRow(
                    outcome: outcomes[i],
                    color: weightColorAt(i),
                    weight: weights[i],
                    remaining: remaining,
                    showDivider: i > 0,
                    onChanged: (v) => onSetWeight(outcomes[i].id, v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One outcome's row: a colour dot, its name, the weight pill, and the slider.
class _OutcomeWeightRow extends StatelessWidget {
  final SchemaOutcome outcome;
  final Color color;
  final double weight;
  final double remaining;
  final bool showDivider;
  final ValueChanged<double> onChanged;

  const _OutcomeWeightRow({
    required this.outcome,
    required this.color,
    required this.weight,
    required this.remaining,
    required this.showDivider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        outcome.name?.isNotEmpty == true ? outcome.name! : 'Untitled outcome';

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 13, 0, 6),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(top: BorderSide(color: AppColors.hairline))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  name,
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
              ),
              const SizedBox(width: 9),
              _WeightPill(weight: weight, color: color),
            ],
          ),
          _WeightSlider(
            value: weight,
            color: color,
            remaining: remaining,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// The "42%" badge tinted in the outcome's slice colour.
class _WeightPill extends StatelessWidget {
  final double weight;
  final Color color;

  const _WeightPill({required this.weight, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${weight.round()}%',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.sans,
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
          height: 1,
          color: color,
        ),
      ),
    );
  }
}

/// A 0–100 weight slider whose track reads as a budget: a solid fill = this
/// outcome's share, a lighter fill = the headroom still free before the 100%
/// budget runs out, then the grey rail. The lighter band uses the slider's
/// secondary track so it always lines up under the thumb.
///
/// Source: `design_app/screens.jsx` `WeightSlider`.
class _WeightSlider extends StatelessWidget {
  final double value;
  final Color color;
  final double remaining;
  final ValueChanged<double> onChanged;

  const _WeightSlider({
    required this.value,
    required this.color,
    required this.remaining,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final headroomEnd =
        math.min(100.0, value + math.max(0.0, remaining));

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: color,
        inactiveTrackColor: AppColors.bgAlt,
        secondaryActiveTrackColor: color.withValues(alpha: 0.22),
        thumbColor: AppColors.ink,
        overlayColor: const Color(0x1A221F2A),
        thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 11, elevation: 2),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        trackShape: const RoundedRectSliderTrackShape(),
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 0),
      ),
      child: Slider(
        value: value.clamp(0, 100),
        min: 0,
        max: 100,
        divisions: 100,
        secondaryTrackValue: headroomEnd,
        onChanged: (v) => onChanged(v),
      ),
    );
  }
}

/// When balanced this is a quiet "fully allocated" confirmation; when over or
/// under budget it becomes the one-tap "Normalize to 100%" fix.
///
/// Source: `design_app/screens.jsx` `RemainingBanner`.
class _RemainingBanner extends StatelessWidget {
  final double remaining;
  final VoidCallback onNormalize;

  const _RemainingBanner({required this.remaining, required this.onNormalize});

  @override
  Widget build(BuildContext context) {
    if (remaining.round() == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.goldTint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            MixMaxIcon(MixMaxGlyph.check, size: 14, color: AppColors.goldText),
            SizedBox(width: 7),
            Text(
              'Fully allocated',
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1,
                color: AppColors.goldText,
              ),
            ),
          ],
        ),
      );
    }

    final over = remaining < 0;
    return Container(
      decoration: BoxDecoration(
        color: over ? AppColors.dangerTint : AppColors.bgAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: over ? AppColors.danger : AppColors.hairlineStrong,
        ),
      ),
      child: MixMaxInk(
        onTap: onNormalize,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MixMaxIcon(
                MixMaxGlyph.sparkle,
                size: 15,
                color: over ? AppColors.dangerText : AppColors.gold,
              ),
              const SizedBox(width: 7),
              Text(
                'Normalize to 100%',
                style: TextStyle(
                  fontFamily: AppFonts.sans,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1,
                  color: over ? AppColors.dangerText : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A weighted slice of the donut: its [color] and 0–100 [value].
class _DonutSlice {
  final Color color;
  final double value;
  const _DonutSlice({required this.color, required this.value});
}

/// The ring chart: each outcome's slice is sized by its weight, and any
/// unallocated budget shows as a muted slice so "space left up to 100%" reads
/// at a glance. The centre prints the total used and its budget state.
///
/// Source: `design_app/screens.jsx` `WeightDonut`.
class _WeightDonut extends StatelessWidget {
  final List<_DonutSlice> slices;
  final double total;

  static const double _size = 156;
  static const double _stroke = 26;

  const _WeightDonut({required this.slices, required this.total});

  @override
  Widget build(BuildContext context) {
    final rounded = total.round();
    final over = total > 100;
    final balanced = rounded == 100;

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(_size, _size),
            painter: _DonutPainter(slices: slices, total: total),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$rounded%',
                style: TextStyle(
                  fontFamily: AppFonts.serif,
                  fontWeight: FontWeight.w500,
                  fontSize: 32,
                  height: 1,
                  letterSpacing: 32 * -0.01,
                  color: over ? AppColors.dangerText : AppColors.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                balanced
                    ? 'BALANCED'
                    : over
                        ? 'OVER BUDGET'
                        : 'ALLOCATED',
                style: TextStyle(
                  fontFamily: AppFonts.sans,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                  height: 1,
                  letterSpacing: 10.5 * 0.06,
                  color: balanced ? AppColors.goldText : AppColors.inkFaint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSlice> slices;
  final double total;

  _DonutPainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = _WeightDonut._stroke;
    final r = (size.width - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    // ~2.2 circumference px of breathing room between segments.
    final gapAngle = 2.2 / r;

    // Build the ring's segments: weighted slices plus, when under budget, a
    // muted slice for the headroom; an empty/over budget collapses to a single
    // proportional set.
    final List<MapEntry<Color, double>> segs;
    if (total <= 0) {
      segs = [const MapEntry(AppColors.hairlineStrong, 1.0)];
    } else if (total < 100) {
      segs = [
        for (final s in slices)
          if (s.value > 0) MapEntry(s.color, s.value / 100),
        MapEntry(AppColors.hairlineStrong, (100 - total) / 100),
      ];
    } else {
      segs = [
        for (final s in slices)
          if (s.value > 0) MapEntry(s.color, s.value / total),
      ];
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    final rect = Rect.fromCircle(center: center, radius: r);
    final multiple = segs.length > 1;

    var startAngle = -math.pi / 2; // 12 o'clock
    for (final seg in segs) {
      final full = seg.value * 2 * math.pi;
      // Trim a gap off the end of each segment (in radians), keeping a hairline
      // minimum so a tiny slice still shows.
      final sweep =
          math.max(full - (multiple ? gapAngle : 0), 0.6 / r);
      paint.color = seg.key;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += full;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.total != total || !_sameSlices(old.slices, slices);

  bool _sameSlices(List<_DonutSlice> a, List<_DonutSlice> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].color != b[i].color) return false;
    }
    return true;
  }
}
