import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/format.dart';
import 'package:mix_max/widgets/pages/experiment_details/weight_math.dart';

/// One parameter, reduced to the few strings the share card draws: the sage
/// type glyph, the parameter's name, its value and an optional unit.
class ShareMixEntry {
  final MixMaxGlyph glyph;
  final String name;
  final String value;
  final String? unit;

  const ShareMixEntry({
    required this.glyph,
    required this.name,
    required this.value,
    this.unit,
  });
}

/// One recorded outcome reduced to what the "How it scored" breakdown draws:
/// its name, recorded [value] and upper bound [max] (shown as a `value / max`
/// pill), plus the weight-aware [weight] share and [points] contribution to the
/// 0–10 rating — the same figures the in-app Rating breakdown shows, so the
/// color-coded stacked bar and the rows agree.
class ShareOutcomeEntry {
  final String name;
  final double? value;
  final double max;

  /// Share of the rating this outcome carries, in [0, 1].
  final double weight;

  /// Points contributed toward the 0–10 rating (`weight × norm × 10`).
  final double points;

  const ShareOutcomeEntry({
    required this.name,
    required this.value,
    required this.max,
    required this.weight,
    required this.points,
  });
}

/// The shareable run card — a fixed-width editorial image of a single run's
/// mix and how it scored.
///
/// Source: `design_app/share-card.js` + `share-card.css` ("Quiet Instrument"
/// share card). Rendered at its native [designWidth] (436px) so a
/// `ScreenshotController` can rasterise it crisply — `RunShareLauncher` mounts it
/// off-screen, captures it and hands the PNG to the share sheet. Pulls its
/// palette and type from the design ions (`AppColors`, `AppFonts`) and its glyphs
/// from [MixMaxIcon].
class ShareCard extends StatelessWidget {
  /// The experiment name — the card's serif masthead.
  final String experimentName;

  /// Overall rating on the 0–10 scale shown in the gold panel.
  final double rating;

  /// Whether this is the experiment's highest-rated run. Shows the "Top-rated
  /// mix" note under the rating when set.
  final bool isBest;

  /// The run's mix — one entry per parameter.
  final List<ShareMixEntry> mix;

  /// The run's recorded outcomes.
  final List<ShareOutcomeEntry> outcomes;

  /// Native design width, in logical pixels. Matches `.mmcard { width: 436px }`.
  static const double designWidth = 436;

  const ShareCard({
    super.key,
    required this.experimentName,
    required this.rating,
    required this.isBest,
    required this.mix,
    required this.outcomes,
  });

  /// Builds the card's [mix] entries from a run's parameter definitions and
  /// recorded values. Mirrors `main.jsx` `shareRun`'s value formatting:
  /// toggles read as their on/off label, choices as the picked option, orders
  /// as an arrow-joined chain, and numbers/durations as a 3-decimal metric with
  /// the parameter's unit.
  static List<ShareMixEntry> mixFrom(
    List<SchemaParameter> parameters,
    Map<String, dynamic> values,
  ) {
    return parameters.map((p) {
      final raw = values[p.id];
      String value;
      String? unit;
      switch (p.type) {
        case ParameterType.toggle:
          value = raw == true ? p.resolvedOnLabel : p.resolvedOffLabel;
          break;
        case ParameterType.choice:
          value = raw != null ? raw.toString() : '—';
          break;
        case ParameterType.order:
          value =
              raw is List
                  ? raw.map((e) => e.toString()).join('  →  ')
                  : '—';
          break;
        case ParameterType.duration:
          // The unit is folded into the `1h 30m` value, so none is shown apart.
          value = raw is num ? p.formatDuration(raw) : '—';
          break;
        case ParameterType.temperature:
          // The degree symbol is folded into the `212 °F` value.
          value = raw is num ? p.formatTemperature(raw) : '—';
          break;
        case ParameterType.number:
        case null:
          value = raw is num
              ? MixMaxFormat.number(raw.toDouble(), decimals: 3)
              : '—';
          unit = p.unit?.isNotEmpty == true ? p.unit : null;
          break;
      }
      if (value.isEmpty) value = '—';
      return ShareMixEntry(
        glyph: _glyphForType(p.type),
        name: p.name?.isNotEmpty == true ? p.name! : 'Untitled',
        value: value,
        unit: unit,
      );
    }).toList();
  }

  /// Builds the card's [outcomes] entries from a run's outcome definitions and
  /// recorded values, computing each one's weight share and points contribution
  /// the same way `RatingBreakdownCard` (and `SchemaRun.computeFinalRating`)
  /// does: only measured outcomes are weighted, falling back to an equal split
  /// when their weights are all zero, and the score is goal-aware. The per-row
  /// points therefore sum to the run's 0–10 rating.
  static List<ShareOutcomeEntry> outcomesFrom(
    List<SchemaOutcome> outcomes,
    Map<String, double> values,
  ) {
    final measured = outcomes.where((o) => values[o.id] != null).toList();
    final weightSum =
        measured.fold<double>(0.0, (a, o) => a + (o.weight ?? 0.0));
    final useEqualWeights = weightSum <= 0;
    final denom =
        useEqualWeights ? measured.length.toDouble() : weightSum;

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
      return ShareOutcomeEntry(
        name: o.name?.isNotEmpty == true ? o.name! : 'Outcome',
        value: v,
        max: o.max ?? 10,
        weight: weight,
        points: weight * norm * 10,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 5+ parameters switch to the ultra-compact two-column list.
    final listMode = mix.length > 4;

    return SizedBox(
      width: designWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.hairline, width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x0D221F2A), offset: Offset(0, 1), blurRadius: 2),
            BoxShadow(
              color: Color(0x66221F2A),
              offset: Offset(0, 40),
              blurRadius: 80,
              spreadRadius: -36,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Faint gold signature watermark in the top-right corner.
              Positioned(
                right: -60,
                top: -60,
                child: IgnorePointer(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment(-0.4, -0.4),
                        radius: 0.7,
                        colors: [Color(0x12B5872B), Color(0x00B5872B)],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _head(),
                  // Title.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 16, 30, 0),
                    child: Text(
                      experimentName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.serif,
                        fontWeight: FontWeight.w500,
                        fontSize: 48,
                        height: 1.0,
                        letterSpacing: 48 * -0.02,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  _ratingPanel(),
                  // The mix.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 26, 30, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('The mix', mix.length),
                        const SizedBox(height: 3),
                        _sub(isBest
                            ? 'The exact values that won.'
                            : 'The full mix, exactly as set.'),
                        const SizedBox(height: 14),
                        if (listMode) _MixList(mix: mix) else _MixGrid(mix: mix),
                      ],
                    ),
                  ),
                  // How it scored.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 24, 30, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('How it scored', outcomes.length),
                        const SizedBox(height: 3),
                        _sub("Each outcome's score, by weight, adds up to the rating."),
                        const SizedBox(height: 15),
                        _CompositionBar(outcomes: outcomes),
                        const SizedBox(height: 8),
                        _OutcomeRows(outcomes: outcomes),
                      ],
                    ),
                  ),
                  _footer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── top band: "Mix Max" eyebrow ───────────────────────────────────────────
  Widget _head() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(30, 28, 30, 0),
      child: Text(
        'MIX MAX',
        style: TextStyle(
          fontFamily: AppFonts.sans,
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
          letterSpacing: 11.5 * 0.14,
          color: AppColors.gold,
        ),
      ),
    );
  }

  // ── rating panel: big serif number + label ────────────────────────────────
  Widget _ratingPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(30, 22, 30, 0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text.rich(
            TextSpan(
              text: MixMaxFormat.number(rating, decimals: 1),
              style: const TextStyle(
                fontFamily: AppFonts.serif,
                fontWeight: FontWeight.w500,
                fontSize: 62,
                height: 0.86,
                letterSpacing: 62 * -0.02,
                color: AppColors.goldDeep,
              ),
              children: const [
                TextSpan(
                  text: '/10',
                  style: TextStyle(
                    fontFamily: AppFonts.serif,
                    fontWeight: FontWeight.w500,
                    fontSize: 25,
                    color: AppColors.goldText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OVERALL RATING',
                  style: TextStyle(
                    fontFamily: AppFonts.sans,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    letterSpacing: 11.5 * 0.14,
                    color: AppColors.goldText,
                  ),
                ),
                if (isBest) ...[
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      MixMaxIcon(
                        MixMaxGlyph.sparkle,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Top-rated mix',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.sans,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                            color: AppColors.goldText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── footer ────────────────────────────────────────────────────────────────
  Widget _footer() {
    return Container(
      margin: const EdgeInsets.only(top: 26),
      padding: const EdgeInsets.fromLTRB(30, 18, 30, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.hairline, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MixMaxIcon(
                  MixMaxGlyph.flask,
                  size: 16,
                  color: AppColors.gold,
                ),
                SizedBox(width: 9),
                Flexible(
                  child: Text(
                    'Find the best version of anything',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.sans,
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Mix',
                  style: TextStyle(color: AppColors.gold),
                ),
                TextSpan(text: ' Max'),
              ],
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 13 * 0.01,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── shared bits ───────────────────────────────────────────────────────────
  Widget _sectionLabel(String label, int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.serif,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            fontSize: 21,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          '$count',
          style: const TextStyle(
            fontFamily: AppFonts.sans,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.inkFaint,
          ),
        ),
      ],
    );
  }

  Widget _sub(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppFonts.sans,
        fontWeight: FontWeight.w400,
        fontSize: 12.5,
        color: AppColors.inkSoft,
      ),
    );
  }
}

/// Parameter type → sage list glyph. Mirrors `theme.jsx` `PARAM_TYPES`.
MixMaxGlyph _glyphForType(ParameterType? type) {
  switch (type) {
    case ParameterType.number:
      return MixMaxGlyph.hash;
    case ParameterType.duration:
      return MixMaxGlyph.timer;
    case ParameterType.temperature:
      return MixMaxGlyph.ruler;
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

/// The two-column chip grid used for 1–4 parameters (`.mixgrid` / `.pchip`).
class _MixGrid extends StatelessWidget {
  final List<ShareMixEntry> mix;

  const _MixGrid({required this.mix});

  @override
  Widget build(BuildContext context) {
    // A lone parameter spans both columns; otherwise pack into rows of two.
    if (mix.length == 1) {
      return _MixChip(entry: mix.first);
    }

    final rows = <Widget>[];
    for (var i = 0; i < mix.length; i += 2) {
      final left = _MixChip(entry: mix[i]);
      final hasRight = i + 1 < mix.length;
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: left),
            const SizedBox(width: 8),
            Expanded(
              child: hasRight ? _MixChip(entry: mix[i + 1]) : const SizedBox(),
            ),
          ],
        ),
      ));
      if (i + 2 < mix.length) rows.add(const SizedBox(height: 8));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _MixChip extends StatelessWidget {
  final ShareMixEntry entry;

  const _MixChip({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.sageTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: MixMaxIcon(entry.glyph, size: 15, color: AppColors.sage),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.sans,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: entry.value,
              children: [
                if (entry.unit != null)
                  TextSpan(
                    text: ' ${entry.unit}',
                    style: const TextStyle(
                      fontFamily: AppFonts.sans,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
              ],
              style: const TextStyle(
                fontFamily: AppFonts.serif,
                fontWeight: FontWeight.w500,
                fontSize: 21,
                height: 1.1,
                letterSpacing: 21 * -0.01,
                color: AppColors.ink,
              ),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// The ultra-compact two-column list used for 5+ parameters (`.mixlist`).
class _MixList extends StatelessWidget {
  final List<ShareMixEntry> mix;

  const _MixList({required this.mix});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < mix.length; i += 2) {
      final hasRight = i + 1 < mix.length;
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _MixListRow(entry: mix[i])),
          const SizedBox(width: 28),
          Expanded(
            child: hasRight ? _MixListRow(entry: mix[i + 1]) : const SizedBox(),
          ),
        ],
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _MixListRow extends StatelessWidget {
  final ShareMixEntry entry;

  const _MixListRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.hairline, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 19,
            height: 19,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sageTint,
              borderRadius: BorderRadius.circular(6),
            ),
            child: MixMaxIcon(entry.glyph, size: 12, color: AppColors.sage),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppFonts.sans,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 90),
            child: Text.rich(
              TextSpan(
                text: entry.value,
                children: [
                  if (entry.unit != null)
                    TextSpan(
                      text: ' ${entry.unit}',
                      style: const TextStyle(
                        fontFamily: AppFonts.sans,
                        fontWeight: FontWeight.w500,
                        fontSize: 10.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                ],
                style: const TextStyle(
                  fontFamily: AppFonts.serif,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.5,
                  letterSpacing: 16.5 * -0.01,
                  color: AppColors.ink,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// The color-coded stacked rating bar (`.compbar`): one rounded track whose
/// colored segments each span their outcome's contribution to the 0–10 rating
/// (`points × 10`% of the track, labelled with the points). Outcomes that add
/// nothing contribute no segment; the warm remainder reads as the distance to a
/// perfect 10. Keyed to the rows beneath by the same [kWeightColors] swatch.
class _CompositionBar extends StatelessWidget {
  final List<ShareOutcomeEntry> outcomes;

  const _CompositionBar({required this.outcomes});

  @override
  Widget build(BuildContext context) {
    // Each segment's flex is its share of a 100-wide track (×100 for rounding
    // headroom); the trailing spacer holds the gap up to a perfect rating.
    final segments = <Widget>[];
    var used = 0;
    for (var i = 0; i < outcomes.length; i++) {
      final w = (outcomes[i].points * 10).clamp(0.0, 100.0);
      final flex = (w * 100).round();
      if (flex <= 0) continue;
      used += flex;
      segments.add(
        Expanded(
          flex: flex,
          child: _BarSegment(
            color: weightColorAt(i),
            label: w >= 11
                ? MixMaxFormat.number(outcomes[i].points, decimals: 1)
                : null,
          ),
        ),
      );
    }
    final remaining = 10000 - used;
    if (remaining > 0) {
      segments.add(Expanded(flex: remaining, child: const SizedBox()));
    }

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.bgAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(children: segments),
    );
  }
}

/// One stacked-bar segment (`.seg`): a solid [color] block, captioned with its
/// points [label] in white when it is wide enough to read.
class _BarSegment extends StatelessWidget {
  final Color color;
  final String? label;

  const _BarSegment({required this.color, this.label});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: label == null
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

/// The per-outcome contribution rows (`.orows` / `.orow`): a swatch dot keyed to
/// the bar, the name + weight share, a violet value pill and the points added.
class _OutcomeRows extends StatelessWidget {
  final List<ShareOutcomeEntry> outcomes;

  const _OutcomeRows({required this.outcomes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < outcomes.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: i == 0
                ? null
                : const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.hairline, width: 1),
                    ),
                  ),
            child: _OutcomeRow(outcome: outcomes[i], color: weightColorAt(i)),
          ),
      ],
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  final ShareOutcomeEntry outcome;
  final Color color;

  const _OutcomeRow({required this.outcome, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
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
                outcome.name,
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
              Text(
                '${(outcome.weight * 100).round()}% weight',
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
        ),
        const SizedBox(width: 12),
        _ValuePill(value: outcome.value, max: outcome.max),
        const SizedBox(width: 12),
        SizedBox(
          width: 42,
          child: Text(
            '+${MixMaxFormat.number(outcome.points, decimals: 1)}',
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
    );
  }
}

/// The recorded value as a soft violet pill (`.ochip`), with a faint `/ max`.
class _ValuePill extends StatelessWidget {
  final double? value;
  final double max;

  const _ValuePill({required this.value, required this.max});

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
          text: value == null ? '—' : MixMaxFormat.number(value),
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
          ],
        ),
      ),
    );
  }
}
