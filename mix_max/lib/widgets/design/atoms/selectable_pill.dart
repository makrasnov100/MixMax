import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tap_ripple.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';

/// A single selectable icon + label pill — the building block of a tap-to-pick
/// button group (e.g. the parameter-type picker).
///
/// Source: `drawers.jsx` `TypePicker` button. Hugs its content at the 13px
/// `rTile` radius with `11 / 12 / 11 / 15` padding. Two states:
///   • [selected]  — ink fill, white label, gold-tint glyph
///   • unselected  — surface fill with a hairline ring, ink label, sage glyph
///
/// The two glyph tints are overridable via [iconColorActive] / [iconColorIdle]
/// so the same pill can front a non-sage picker; the fill / label treatment is
/// fixed to keep the group reading as one control.
class MixMaxSelectablePill extends StatelessWidget {
  final MixMaxGlyph icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Glyph tint when [selected]. Defaults to the design's gold tint.
  final Color iconColorActive;

  /// Glyph tint when idle. Defaults to the design's sage.
  final Color iconColorIdle;

  const MixMaxSelectablePill({
    Key? key,
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
    this.iconColorActive = AppColors.goldTint,
    this.iconColorIdle = AppColors.sage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: selected ? AppColors.ink : AppColors.hairline,
          width: 1.5,
        ),
      ),
      child: MixMaxInk(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 15, 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MixMaxIcon(
                icon,
                size: 17,
                color: selected ? iconColorActive : iconColorIdle,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.sans,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                  color: selected ? Colors.white : AppColors.ink,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
