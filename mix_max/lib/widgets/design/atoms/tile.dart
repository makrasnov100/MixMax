import 'package:flutter/widgets.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';

/// Color voices for a [MixMaxTile], ported from `ui.jsx` `TILE_TONES`. Each
/// pairs a soft tinted fill with a saturated icon ink:
///   • [sage]    parameters   • [violet] outcomes   • [gold] signature/run
///   • [neutral] quiet/meta    • [ink]    inverted (dark fill, gold glyph)
///   • [danger]  destructive (soft red fill, deep red glyph)
enum MixMaxTileTone { sage, violet, gold, neutral, ink, danger }

/// A tinted rounded square holding a single [MixMaxIcon] — the system's way of
/// giving a list row or affordance a colored "type" glyph.
///
/// Source: `ui.jsx` `Tile`. Defaults to a 44px square at the 13px `rTile`
/// radius with the icon at half the tile size, matching the design.
class MixMaxTile extends StatelessWidget {
  final MixMaxGlyph glyph;
  final MixMaxTileTone tone;
  final double size;

  /// Corner radius. Defaults to the `rTile` token (13).
  final double radius;

  const MixMaxTile({
    Key? key,
    required this.glyph,
    this.tone = MixMaxTileTone.sage,
    this.size = 44,
    this.radius = 13,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = _tonePalette(tone);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: MixMaxIcon(glyph, size: size * 0.5, color: palette.fg),
    );
  }
}

class _TonePalette {
  final Color bg;
  final Color fg;
  const _TonePalette(this.bg, this.fg);
}

_TonePalette _tonePalette(MixMaxTileTone tone) {
  switch (tone) {
    case MixMaxTileTone.sage:
      return const _TonePalette(AppColors.sageTint, AppColors.sage);
    case MixMaxTileTone.violet:
      return const _TonePalette(AppColors.violetTint, AppColors.violet);
    case MixMaxTileTone.gold:
      return const _TonePalette(AppColors.goldTint, AppColors.gold);
    case MixMaxTileTone.neutral:
      return const _TonePalette(AppColors.bgAlt, AppColors.inkSoft);
    case MixMaxTileTone.ink:
      // Inverted: dark fill (not a named token) with the gold-tint glyph.
      return const _TonePalette(Color(0xFF2A2632), AppColors.goldTint);
    case MixMaxTileTone.danger:
      return const _TonePalette(AppColors.dangerTint, AppColors.danger);
  }
}
