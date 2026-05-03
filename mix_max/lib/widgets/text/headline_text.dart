import 'package:flutter/material.dart';
import 'package:mix_max/services/ui/size_config.dart';

class HeadlineText extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextAlign textAlign;
  final Color? color;
  final int? maxLines;
  final TextOverflow overflow;
  const HeadlineText({
    Key? key,
    required this.text,
    this.fontSize = -1,
    this.textAlign = TextAlign.left,
    this.color,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: fontSize < 0 ? SizeConfig.safeBlockVertical * 4 : fontSize,
        color: color ?? Colors.white,
        fontWeight: FontWeight.w400,
        fontFamily: "Roboto",
        overflow: overflow,
        fontFamilyFallback: const ["Roboto"],
      ),
    );
  }
}
