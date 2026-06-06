import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/text/text.dart';

/// Semibold sans label — list-item names, field titles, row headings.
///
/// Source: `screens.jsx` item/field titles (sans 600 / 14.5–16px / ink). The
/// workhorse "name this row" style: heavier than [BodyText] so a label reads as
/// the anchor of its row, but in the functional sans voice rather than serif.
class LabelText extends StatelessWidget {
  final String? text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LabelText({
    Key? key,
    required this.text,
    this.fontSize = 16,
    this.color = AppColors.ink,
    this.fontWeight = FontWeight.w600,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  /// Composable style (e.g. for [TextSpan]s).
  static TextStyle styleOf({
    double fontSize = 16,
    Color color = AppColors.ink,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: AppFonts.sans,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: 1.25,
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
