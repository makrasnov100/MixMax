import 'package:flutter/widgets.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tap_ripple.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';

/// A circular icon button — the top-bar back affordance and other single-glyph
/// round actions.
///
/// Source: `ui.jsx` `RoundBtn` (neutral tone): a white `surface` disc with a
/// hairline ring and a soft drop shadow, holding one [MixMaxIcon].
class MixMaxRoundButton extends StatelessWidget {
  final MixMaxGlyph glyph;
  final VoidCallback onTap;

  /// Disc diameter. Defaults to the design's 40px.
  final double size;

  /// Glyph size. Defaults to 20px to match the 40px disc.
  final double glyphSize;

  /// Glyph tint. Defaults to primary ink.
  final Color color;

  const MixMaxRoundButton({
    Key? key,
    required this.glyph,
    required this.onTap,
    this.size = 40,
    this.glyphSize = 20,
    this.color = AppColors.ink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.hairline, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D221F2A),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: MixMaxInk(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Center(child: MixMaxIcon(glyph, size: glyphSize, color: color)),
      ),
    );
  }
}
