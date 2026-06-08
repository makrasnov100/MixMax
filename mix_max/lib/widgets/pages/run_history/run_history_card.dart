import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/format.dart';

/// One run in the Run History list — a tappable card showing when the run
/// happened, its rating, the outcome values recorded, and a one-line summary of
/// the mix that produced them.
///
/// Source: `design_app/screens.jsx` `RunHistoryCard`. The leading (highest
/// rated) run is highlighted: it takes a gold-tinted fill, a gold border and a
/// warmer shadow, swaps the "RUN n" kicker for a "BEST RUN" trophy badge, and
/// recolors its rating, chips and footer to the gold family. Every other run
/// reads as a calm white card.
class RunHistoryCard extends StatelessWidget {
  /// The experiment this run belongs to — supplies the parameter and outcome
  /// definitions used to label and score the run.
  final SchemaExperiment experiment;

  /// The run to render.
  final SchemaRun run;

  /// 1-based chronological position, shown as the "RUN n" kicker on non-best
  /// runs.
  final int number;

  /// Whether this is the experiment's highest-rated run (the gold treatment).
  final bool isBest;

  /// Opens this run's details.
  final VoidCallback onOpen;

  const RunHistoryCard({
    Key? key,
    required this.experiment,
    required this.run,
    required this.number,
    required this.isBest,
    required this.onOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final outcomes = experiment.outcomes ?? const [];
    final when = run.completedAt ?? run.createdAt;
    final score = run.finalRating(outcomes) * 10;
    final mix = _mixSummary();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
          decoration: BoxDecoration(
            color: isBest ? AppColors.goldTint : AppColors.surface,
            borderRadius: BorderRadius.circular(20), // rCard
            border: Border.all(
              color: isBest ? AppColors.gold : AppColors.hairline,
              width: isBest ? 1.5 : 1,
            ),
            boxShadow: isBest ? _bestShadow : _cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: when + kicker on the left, big rating on the right.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _whenColumn(when)),
                  const SizedBox(width: 12),
                  _ratingColumn(score),
                ],
              ),

              // Outcome value chips.
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final o in outcomes)
                    _OutcomeValueChip(
                      outcome: o,
                      value: run.outcomeValues?[o.id],
                      best: isBest,
                    ),
                ],
              ),

              // The mix that produced this run.
              if (mix != null) ...[
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.only(top: 13),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.hairline, width: 1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: MixMaxIcon(
                          MixMaxGlyph.beaker,
                          size: 15,
                          color: AppColors.inkFaint,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mix,
                          style: const TextStyle(
                            fontFamily: AppFonts.sans,
                            fontWeight: FontWeight.w500,
                            fontSize: 12.5,
                            height: 1.45,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // "View details" affordance.
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View details',
                    style: TextStyle(
                      fontFamily: AppFonts.sans,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1,
                      color: isBest ? AppColors.goldText : AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(width: 4),
                  MixMaxIcon(
                    MixMaxGlyph.chevRight,
                    size: 15,
                    color: isBest ? AppColors.goldText : AppColors.inkFaint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _whenColumn(int? when) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBest)
          _BestBadge()
        else
          Text(
            'RUN $number',
            style: const TextStyle(
              fontFamily: AppFonts.sans,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              letterSpacing: 11.5 * 0.08,
              height: 1,
              color: AppColors.inkFaint,
            ),
          ),
        SizedBox(height: isBest ? 9 : 6),
        Text(
          _relTime(when),
          style: const TextStyle(
            fontFamily: AppFonts.sans,
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
            height: 1.1,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _absStamp(when),
          style: TextStyle(
            fontFamily: AppFonts.sans,
            fontWeight: FontWeight.w500,
            fontSize: 12.5,
            height: 1.1,
            color: isBest ? AppColors.goldText : AppColors.inkFaint,
          ),
        ),
      ],
    );
  }

  Widget _ratingColumn(double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          MixMaxFormat.number(score, decimals: 1),
          style: TextStyle(
            fontFamily: AppFonts.serif,
            fontWeight: FontWeight.w500,
            fontSize: 30,
            height: 1,
            letterSpacing: 30 * -0.01,
            color: isBest ? AppColors.goldDeep : AppColors.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'RATING',
          style: TextStyle(
            fontFamily: AppFonts.sans,
            fontWeight: FontWeight.w600,
            fontSize: 10,
            letterSpacing: 10 * 0.08,
            height: 1,
            color: isBest ? AppColors.goldText : AppColors.inkFaint,
          ),
        ),
      ],
    );
  }

  /// One-line summary of the run's mix — each parameter's recorded value, joined
  /// by middots. Mirrors `screens.jsx` `MixSummary` / `fmtSuggested`. Returns
  /// null when no parameter values are present (the design hides the row).
  String? _mixSummary() {
    final params = experiment.parameters ?? const [];
    final values = run.parameterValues ?? const {};
    final parts = <String>[];
    for (final p in params) {
      final v = values[p.id];
      if (v == null) continue;
      parts.add(_formatParamValue(p, v));
    }
    return parts.isEmpty ? null : parts.join('   ·   ');
  }
}

/// The gold "BEST RUN" pill on the leading run (source: `RunHistoryCard`).
class _BestBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 4, 11, 4),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          MixMaxIcon(MixMaxGlyph.trophy, size: 13, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'BEST RUN',
            style: TextStyle(
              fontFamily: AppFonts.sans,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 11 * 0.06,
              height: 1,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single recorded outcome — its name and value as a soft pill. On the best
/// run it switches to a translucent-white-on-gold treatment (source:
/// `screens.jsx` `OutcomeValueChip`).
class _OutcomeValueChip extends StatelessWidget {
  final SchemaOutcome outcome;
  final double? value;
  final bool best;

  const _OutcomeValueChip({
    required this.outcome,
    required this.value,
    required this.best,
  });

  @override
  Widget build(BuildContext context) {
    final nameColor = best ? AppColors.goldText : AppColors.violetText;
    final valueColor = best ? AppColors.goldDeep : AppColors.violetText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: best ? const Color(0xB3FFFFFF) : AppColors.violetTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: [
          Text(
            outcome.name ?? '',
            style: TextStyle(
              fontFamily: AppFonts.sans,
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
              height: 1,
              color: nameColor,
            ),
          ),
          const SizedBox(width: 6),
          Text.rich(
            TextSpan(
              text: MixMaxFormat.number(value),
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                height: 1,
                color: valueColor,
              ),
              children: [
                if (outcome.unit?.isNotEmpty == true)
                  TextSpan(
                    text: ' ${outcome.unit}',
                    style: TextStyle(
                      fontFamily: AppFonts.sans,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                      height: 1,
                      color: valueColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats a parameter value the way the design's `fmtSuggested` does — a plain
/// string for the one-line mix summary.
String _formatParamValue(SchemaParameter p, dynamic v) {
  switch (p.type) {
    case ParameterType.toggle:
      return v == true ? p.resolvedOnLabel : p.resolvedOffLabel;
    case ParameterType.choice:
      return v.toString();
    case ParameterType.order:
      return v is List ? v.map((e) => e.toString()).join('  →  ') : '';
    case ParameterType.number:
    case ParameterType.duration:
    case null:
      final s = v is num
          ? MixMaxFormat.number(v.toDouble(), decimals: 3)
          : v.toString();
      return p.unit?.isNotEmpty == true ? '$s ${p.unit}' : s;
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

// Best run — '0 1px 2px rgba(120,90,20,0.12), 0 16px 32px -18px rgba(150,110,30,0.5)'
const List<BoxShadow> _bestShadow = [
  BoxShadow(color: Color(0x1F785A14), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(
    color: Color(0x80966E1E),
    offset: Offset(0, 16),
    blurRadius: 32,
    spreadRadius: -18,
  ),
];

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Coarse "x ago" relative time (source: `screens.jsx` `relTime`). Input is
/// seconds since the Unix epoch.
String _relTime(int? sec) {
  if (sec == null) return '';
  final d = DateTime.now().millisecondsSinceEpoch / 1000 - sec;
  if (d < 90) return 'just now';
  if (d < 3600) return '${(d / 60).floor()} min ago';
  if (d < 86400) {
    final h = (d / 3600).floor();
    return '$h hr${h > 1 ? 's' : ''} ago';
  }
  final days = (d / 86400).round();
  if (days < 7) return '$days day${days > 1 ? 's' : ''} ago';
  if (days < 28) {
    final w = (days / 7).round();
    return '$w week${w > 1 ? 's' : ''} ago';
  }
  final mo = (days / 30).round();
  return '$mo month${mo > 1 ? 's' : ''} ago';
}

/// Absolute "Jun 7 · 3:42 PM" stamp (source: `screens.jsx` `absStamp`).
String _absStamp(int? sec) {
  if (sec == null) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  var hour = dt.hour % 12;
  if (hour == 0) hour = 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  return '${_months[dt.month - 1]} ${dt.day} · $hour:$minute $ampm';
}
