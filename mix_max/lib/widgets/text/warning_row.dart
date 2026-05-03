import 'package:flutter/material.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/widgets/text/normal_text.dart';

class WarningInfo {
  bool? isGood;
  bool isLoading;
  String? text;

  WarningInfo({this.isGood, this.text, this.isLoading = false});
}

class WarningRow extends StatelessWidget {
  final WarningInfo? warning;
  final EdgeInsets? margin;
  final double? fontSize;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  const WarningRow({
    Key? key,
    this.warning,
    this.margin,
    this.fontSize,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double defaultFontSize = SizeConfig.safeBlockHorizontal * 3;

    Widget picaText = NormalText(text: warning!.text ?? "", fontSize: fontSize ?? defaultFontSize, color: Colors.grey);
    return Container(
      margin: margin ?? EdgeInsets.zero,
      child: Row(
        mainAxisSize: mainAxisSize,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          warning?.isLoading == true
              ? SizedBox(
                width: SizeConfig.safeBlockHorizontal * 5,
                height: SizeConfig.safeBlockHorizontal * 5,
                child: CircularProgressIndicator(),
              )
              : Icon(
                warning!.isGood == true ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                color: warning!.isGood == true ? Colors.greenAccent : Colors.amberAccent,
                size: (SizeConfig.safeBlockHorizontal * 5) * ((fontSize ?? defaultFontSize) / defaultFontSize),
              ),
          SizedBox(width: SizeConfig.safeBlockHorizontal * 2),
          Visibility(
            visible: mainAxisSize == MainAxisSize.max,
            replacement: picaText,
            child: Expanded(child: picaText),
          ),
        ],
      ),
    );
  }
}
