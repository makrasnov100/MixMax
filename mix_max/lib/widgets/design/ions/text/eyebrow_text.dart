import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/text/text.dart';

/// Tiny tracked uppercase kicker that sits above a heading.
///
/// Source: `ui.jsx` `Eyebrow`. Sans / weight 600 / 11.5px / wide 0.12em
/// tracking / UPPERCASE / faint ink. Flutter has no `text-transform`, so the
/// string is upper-cased at build time — pass natural casing and let the atom
/// shout it. Color is overridable to tint the kicker (gold/sage/violet).
class EyebrowText extends StatelessWidget {
  final String? text;
  final double fontSize;
  final Color color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const EyebrowText({
    Key? key,
    required this.text,
    this.fontSize = 11.5,
    this.color = AppColors.inkFaint,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  /// Composable style (e.g. for [TextSpan]s). Tracking scales with [fontSize].
  static TextStyle styleOf({
    double fontSize = 11.5,
    Color color = AppColors.inkFaint,
  }) {
    return TextStyle(
      fontFamily: AppFonts.sans,
      fontWeight: FontWeight.w600,
      fontSize: fontSize,
      letterSpacing: fontSize * 0.12,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MixMaxText(
      text: text?.toUpperCase(),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: styleOf(fontSize: fontSize, color: color),
    );
  }
}
