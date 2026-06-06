import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';

/// Color voices for a [MixMaxChip], ported from `ui.jsx` `CHIP_TONES`:
///   • [soft]    quiet meta (warm fill, no border)
///   • [gold]    signature        • [sage] parameters   • [violet] outcomes
///   • [outline] white with a hairline ring — the "tap to fill" inspiration chip
enum MixMaxChipTone { soft, gold, sage, violet, outline }

/// A small pill label — the "chip" of the "Quiet Instrument" system.
///
/// Source: `ui.jsx` `Chip`. A fully-rounded pill, sans / 600 / 12.5 with a hair
/// of positive tracking, an optional leading [icon], and an optional [onClose]
/// affordance (a faint round × button). In the create-experiment drawer's
/// "Need inspiration" section these render as [MixMaxChipTone.outline] chips with
/// a `flask` glyph; tapping one (via [onTap]) seeds the name field.
class MixMaxChip extends StatelessWidget {
  final String label;
  final MixMaxChipTone tone;

  /// Optional leading glyph, tinted to the chip's foreground.
  final MixMaxGlyph? icon;

  /// Whole-chip tap handler (e.g. pick this suggestion).
  final VoidCallback? onTap;

  /// When set, renders a trailing round × button that calls this — for
  /// removable chips (the design's chip editor).
  final VoidCallback? onClose;

  const MixMaxChip({
    Key? key,
    required this.label,
    this.tone = MixMaxChipTone.soft,
    this.icon,
    this.onTap,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = _tonePalette(tone);

    // Match the design's tighter right padding when a close button is shown.
    final padding = onClose != null
        ? const EdgeInsets.fromLTRB(12, 6, 8, 6)
        : const EdgeInsets.symmetric(horizontal: 11, vertical: 5);

    final pill = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.bd, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            MixMaxIcon(icon!, size: 13, color: palette.fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.sans,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              letterSpacing: 12.5 * 0.01,
              color: palette.fg,
              height: 1,
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 5),
            _CloseButton(color: palette.fg, onTap: onClose!),
          ],
        ],
      ),
    );

    if (onTap == null) return pill;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: pill),
    );
  }
}

/// The faint 18px round × at the trailing edge of a removable chip.
class _CloseButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _CloseButton({Key? key, required this.color, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0x0D000000), // rgba(0,0,0,0.05)
          shape: BoxShape.circle,
        ),
        child: MixMaxIcon(MixMaxGlyph.close, size: 11, color: color),
      ),
    );
  }
}

class _ChipPalette {
  final Color bg;
  final Color fg;
  final Color bd;
  const _ChipPalette(this.bg, this.fg, this.bd);
}

_ChipPalette _tonePalette(MixMaxChipTone tone) {
  switch (tone) {
    case MixMaxChipTone.soft:
      return const _ChipPalette(AppColors.bgAlt, AppColors.inkSoft, Colors.transparent);
    case MixMaxChipTone.gold:
      return const _ChipPalette(AppColors.goldTint, AppColors.goldText, Colors.transparent);
    case MixMaxChipTone.sage:
      return const _ChipPalette(AppColors.sageTint, AppColors.sageText, Colors.transparent);
    case MixMaxChipTone.violet:
      return const _ChipPalette(AppColors.violetTint, AppColors.violetText, Colors.transparent);
    case MixMaxChipTone.outline:
      return const _ChipPalette(AppColors.surface, AppColors.inkSoft, AppColors.hairlineStrong);
  }
}
