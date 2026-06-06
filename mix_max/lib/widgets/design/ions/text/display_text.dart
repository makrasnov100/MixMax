import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/text/text.dart';

/// Hero page title — the largest serif voice in the system.
///
/// Source: `ui.jsx` `Display` (h1). Serif / weight 500 / ~38px, tight leading
/// and slightly negative tracking for an editorial masthead feel. Reserve for
/// the single dominant heading of a screen.
class DisplayText extends StatelessWidget {
  final String? text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const DisplayText({
    Key? key,
    required this.text,
    this.fontSize = 38,
    this.color = AppColors.ink,
    this.fontWeight = FontWeight.w500,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  /// Composable style (e.g. for [TextSpan]s). Tracking scales with [fontSize].
  static TextStyle styleOf({
    double fontSize = 38,
    Color color = AppColors.ink,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: AppFonts.serif,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: 1.04,
      letterSpacing: fontSize * -0.015,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MixMaxText(
      text: text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: styleOf(fontSize: fontSize, color: color, fontWeight: fontWeight),
    );
  }
}
