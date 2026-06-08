import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
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
class MixMaxActionRow extends StatefulWidget {
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
  State<MixMaxActionRow> createState() => _MixMaxActionRowState();
}

class _MixMaxActionRowState extends State<MixMaxActionRow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.danger ? AppColors.danger : AppColors.ink;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.bgAlt : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          child: Row(
            children: [
              MixMaxTile(glyph: widget.glyph, tone: widget.tone, size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabelText(text: widget.label, color: foreground),
                    const SizedBox(height: 2),
                    BodyText(text: widget.sublabel, fontSize: 13),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              MixMaxIcon(
                MixMaxGlyph.chevRight,
                size: 19,
                color: widget.danger ? AppColors.danger : AppColors.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
