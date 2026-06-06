import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/text/text.dart';

/// Object title — experiment names, card headers, drawer titles.
///
/// Source: `screens.jsx` experiment/card titles and `drawers.jsx` drawer title.
/// Serif / weight 500 / ~24px, tight leading and slightly negative tracking.
/// The everyday "name of this thing" heading, one step below [DisplayText].
class TitleText extends StatelessWidget {
  final String? text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TitleText({
    Key? key,
    required this.text,
    this.fontSize = 24,
    this.color = AppColors.ink,
    this.fontWeight = FontWeight.w500,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  /// Composable style (e.g. for [TextSpan]s). Tracking scales with [fontSize].
  static TextStyle styleOf({
    double fontSize = 24,
    Color color = AppColors.ink,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: AppFonts.serif,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: 1.1,
      letterSpacing: fontSize * -0.01,
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
