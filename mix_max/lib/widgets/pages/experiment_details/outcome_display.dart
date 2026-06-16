import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/widgets/design/atoms/chip.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tap_ripple.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/format.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/label_text.dart';

/// One outcome row on the Experiment Details page — a violet target glyph, the
/// outcome's name, a meta line of its range/increment, and a goal chip.
///
/// Source: `screens.jsx` `OutcomeRow`. Like [ParameterDisplay] it is built to
/// live inside its group card ([OutcomeListCard]) and so carries only the
/// design's `15 / 16` row padding. The trailing chip reads gold "maximize" or
/// violet "minimize" depending on [SchemaOutcome.goal].
class OutcomeDisplay extends StatelessWidget {
  final SchemaOutcome outcome;

  /// Tapping the row opens its edit drawer. Null leaves the row inert.
  final VoidCallback? onTap;

  const OutcomeDisplay({Key? key, required this.outcome, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final o = outcome;
    final maximize = o.goal == OutcomeGoal.maximize;
    final meta = _metaLabel(o);

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const MixMaxTile(glyph: MixMaxGlyph.target, tone: MixMaxTileTone.violet),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LabelText(
                  text: o.name?.isNotEmpty == true ? o.name : 'Untitled outcome',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  CaptionText(text: meta, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          MixMaxChip(
            label: maximize ? 'maximize' : 'minimize',
            tone: maximize ? MixMaxChipTone.gold : MixMaxChipTone.violet,
            icon: maximize ? MixMaxGlyph.up : MixMaxGlyph.down,
          ),
        ],
      ),
    );

    return MixMaxInk(onTap: onTap, child: row);
  }

  /// `unit · min–max · increment N`, dropping any part that isn't set. Mirrors
  /// the JS `[unit, min–max, increment].filter(Boolean).join('  ·  ')`.
  String _metaLabel(SchemaOutcome o) {
    final parts = <String>[
      if (o.unit?.isNotEmpty == true) o.unit!,
      if (o.min != null && o.max != null)
        '${MixMaxFormat.number(o.min)}–${MixMaxFormat.number(o.max)}',
      if (o.step != null) 'increment ${MixMaxFormat.number(o.step)}',
    ];
    return parts.join('  ·  ');
  }
}
