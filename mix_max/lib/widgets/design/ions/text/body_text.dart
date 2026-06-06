import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/text/text.dart';

/// Running body copy — descriptions, helper paragraphs, empty-state blurbs.
///
/// Source: `screens.jsx` descriptive copy (sans 400 / 14px / leading 1.5 /
/// soft ink). The default reading voice: relaxed line-height for multi-line
/// passages, muted color so it recedes behind labels and titles.
class BodyText extends StatelessWidget {
  final String? text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const BodyText({
    Key? key,
    required this.text,
    this.fontSize = 14,
    this.color = AppColors.inkSoft,
    this.fontWeight = FontWeight.w400,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  /// Composable style (e.g. for [TextSpan]s).
  static TextStyle styleOf({
    double fontSize = 14,
    Color color = AppColors.inkSoft,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: AppFonts.sans,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: 1.5,
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
