import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/text/text.dart';

/// Small secondary line — metadata, sub-labels, "X of Y", inline hints.
///
/// Source: `screens.jsx` meta/secondary lines (sans 500 / 13px / soft ink).
/// The smallest readable run in the system. Weight 500 keeps it legible at size
/// without competing with [LabelText]; recolor it (gold/sage/violet/faint) to
/// signal status against the muted default.
class CaptionText extends StatelessWidget {
  final String? text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const CaptionText({
    Key? key,
    required this.text,
    this.fontSize = 13,
    this.color = AppColors.inkSoft,
    this.fontWeight = FontWeight.w500,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  /// Composable style (e.g. for [TextSpan]s).
  static TextStyle styleOf({
    double fontSize = 13,
    Color color = AppColors.inkSoft,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: AppFonts.sans,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: 1.35,
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
