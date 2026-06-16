import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tap_ripple.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/label_text.dart';

/// A single tappable row in an actions bottom sheet: a tinted [MixMaxTile]
/// glyph, a label / sublabel stack, and a trailing chevron.
///
/// Source: `design_app/drawers.jsx` `ActionRow`, shared by the experiment- and
/// run-management sheets. The [danger] flag reddens the label and chevron for a
/// destructive option.
class MixMaxActionRow extends StatelessWidget {
  final MixMaxGlyph glyph;
  final MixMaxTileTone tone;
  final String label;
  final String sublabel;
  final bool danger;
  final VoidCallback onTap;

  const MixMaxActionRow({
    super.key,
    required this.glyph,
    required this.tone,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = danger ? AppColors.danger : AppColors.ink;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: MixMaxInk(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
          child: Row(
            children: [
              MixMaxTile(glyph: glyph, tone: tone, size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabelText(text: label, color: foreground),
                    const SizedBox(height: 2),
                    BodyText(text: sublabel, fontSize: 13),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              MixMaxIcon(
                MixMaxGlyph.chevRight,
                size: 19,
                color: danger ? AppColors.danger : AppColors.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
