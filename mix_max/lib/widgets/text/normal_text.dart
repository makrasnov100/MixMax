import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mix_max/services/ui/size_config.dart';

TextStyle getNormalTextStyle() {
  return TextStyle(
    fontSize: SizeConfig.getFontSize(3),
    color: Colors.black,
    fontWeight: FontWeight.w400,
    fontFamily: "Roboto",
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
    fontFamilyFallback: const ["Roboto"],
  );
}

class NormalText extends StatelessWidget {
  final String? text;
  final double fontSize;
  final TextAlign textAlign;
  final FontWeight fontWeight;
  final TextDecoration decoration;
  final Color? color;
  final FontStyle fontStyle;
  final TapGestureRecognizer? recognizer;
  final TextOverflow? overflow;
  final int? maxLines;
  const NormalText({
    Key? key,
    this.text,
    this.fontSize = -1,
    this.textAlign = TextAlign.left,
    this.fontWeight = FontWeight.w400,
    this.fontStyle = FontStyle.normal,
    this.decoration = TextDecoration.none,
    this.color = Colors.white,
    this.recognizer,
    this.overflow,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle normalTextStyle = getNormalTextStyle();

    TextStyle textStyle = normalTextStyle.copyWith(
      fontSize: fontSize == -1 ? normalTextStyle.fontSize : fontSize,
      fontWeight: fontWeight,
      decoration: decoration,
      color: color,
      fontStyle: fontStyle,
    );

    if (recognizer != null) {
      return RichText(
        textAlign: textAlign,
        text: TextSpan(recognizer: recognizer, text: text, style: textStyle),
        overflow: overflow ?? TextOverflow.clip,
        maxLines: maxLines,
      );
    } else {
      return Text(text ?? "My Fortuna", textAlign: textAlign, overflow: overflow, maxLines: maxLines, style: textStyle);
    }
  }
}
