import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/text/text.dart';

/// Oversized serif numeral — the headline metric / suggested-value readout.
///
/// Source: `screens.jsx` big stat display (serif 500 / 84px / leading 1 /
/// tracking -0.02em). This is the "instrument dial" — a single number or short
/// value shown large. Leading is collapsed to 1.0 so it sits tight in its slot.
class MetricText extends StatelessWidget {
  final String? text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const MetricText({
    Key? key,
    required this.text,
    this.fontSize = 84,
    this.color = AppColors.ink,
    this.fontWeight = FontWeight.w500,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  /// Composable style (e.g. for a unit [TextSpan] beside the numeral).
  /// Tracking scales with [fontSize].
  static TextStyle styleOf({
    double fontSize = 84,
    Color color = AppColors.ink,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: AppFonts.serif,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: 1,
      letterSpacing: fontSize * -0.02,
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
