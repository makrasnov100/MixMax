import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/text/text.dart';

/// Italic serif section heading — "Parameters", "Outcomes", etc.
///
/// Source: `ui.jsx` `SectionLabel`. Serif / italic / weight 500 / ~21px. The
/// italic gives groupings a soft editorial divider without the weight of a
/// full [TitleText]. Often paired with a count chip alongside it.
class SectionLabelText extends StatelessWidget {
  final String? text;
  final double fontSize;
  final Color color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const SectionLabelText({
    Key? key,
    required this.text,
    this.fontSize = 21,
    this.color = AppColors.ink,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  /// Composable style (e.g. for [TextSpan]s).
  static TextStyle styleOf({
    double fontSize = 21,
    Color color = AppColors.ink,
  }) {
    return TextStyle(
      fontFamily: AppFonts.serif,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w500,
      fontSize: fontSize,
      height: 1.15,
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
      style: styleOf(fontSize: fontSize, color: color),
    );
  }
}
