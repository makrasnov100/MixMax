import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/format.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/label_text.dart';
import 'package:mix_max/widgets/design/molecules/mini_switch.dart';
import 'package:mix_max/widgets/design/molecules/option_preview.dart';
import 'package:mix_max/widgets/design/molecules/order_preview.dart';
import 'package:mix_max/widgets/design/molecules/range_pips.dart';

/// One parameter row on the Experiment Details page — a sage type-glyph, the
/// parameter's name, and a value preview that adapts to its [ParameterType].
///
/// Source: `screens.jsx` `ParamRow` + `ParamValue`. Designed to sit inside the
/// [ParameterListCard] group, so it carries no border or background of its own —
/// just the design's `15 / 16` row padding. The value visual is chosen per type:
///   • number / duration → [RangePips] when bounded, else a `≥ / ≤ / any value`
///                          caption
///   • toggle            → a [MiniSwitch] beside an `on / off` caption
///   • choice            → an [OptionPreview] of the options
///   • order             → an [OrderPreview] of the sequence
class ParameterDisplay extends StatelessWidget {
  final SchemaParameter parameter;

  /// Tapping the row opens its edit drawer. Null leaves the row inert.
  final VoidCallback? onTap;

  const ParameterDisplay({Key? key, required this.parameter, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MixMaxTile(glyph: _glyphForType(parameter.type), tone: MixMaxTileTone.sage),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LabelText(
                  text: parameter.name?.isNotEmpty == true
                      ? parameter.name
                      : 'Untitled parameter',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _ParameterValue(parameter: parameter),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.bgAlt,
        highlightColor: AppColors.bgAlt,
        child: row,
      ),
    );
  }
}

/// The per-type value preview for a parameter (source: `screens.jsx`
/// `ParamValue`).
class _ParameterValue extends StatelessWidget {
  final SchemaParameter parameter;

  const _ParameterValue({required this.parameter});

  @override
  Widget build(BuildContext context) {
    final p = parameter;
    switch (p.type) {
      case ParameterType.number:
      case ParameterType.duration:
        final isDuration = p.type == ParameterType.duration;
        if (p.min != null && p.max != null) {
          return RangePips(
            min: p.min,
            max: p.max,
            // Durations fold the unit into each cap (`1m` / `10m`).
            unit: isDuration ? null : p.unit,
            format: isDuration ? p.formatDuration : null,
          );
        }
        return CaptionText(text: _boundsLabel(p), fontSize: 13.5);

      case ParameterType.toggle:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniSwitch(on: true),
            const SizedBox(width: 9),
            CaptionText(
              text: '${p.resolvedOnLabel} / ${p.resolvedOffLabel}',
              color: AppColors.inkFaint,
            ),
          ],
        );

      case ParameterType.choice:
        return OptionPreview(options: p.options ?? const []);

      case ParameterType.order:
        return OrderPreview(items: p.items ?? const []);

      case null:
        return const SizedBox.shrink();
    }
  }

  /// Text fallback for an unbounded number/duration: the unit and whichever
  /// single bound exists, or "any value" when neither does. Mirrors the JS
  /// `[unit, ≥min | ≤max | 'any value'].join('  ·  ')`. Duration bounds are
  /// rendered as `1h 30m`, with the unit already folded in.
  String _boundsLabel(SchemaParameter p) {
    final isDuration = p.type == ParameterType.duration;
    String fmt(double? v) =>
        isDuration ? p.formatDuration(v) : MixMaxFormat.number(v);
    final parts = <String>[
      if (!isDuration && p.unit?.isNotEmpty == true) p.unit!,
      if (p.min != null)
        '≥ ${fmt(p.min)}'
      else if (p.max != null)
        '≤ ${fmt(p.max)}'
      else
        'any value',
    ];
    return parts.join('  ·  ');
  }
}

/// Parameter type → sage list glyph. Mirrors `theme.jsx` `PARAM_TYPES`.
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
