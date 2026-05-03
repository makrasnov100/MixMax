import 'package:flutter/material.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/widgets/text/headline_text.dart';
import 'package:mix_max/widgets/text/normal_text.dart';
import 'package:mix_max/widgets/text/recognizer_text.dart';

enum CenterMessagePosition { center, above }

class CenterMessage extends StatelessWidget {
  final EdgeInsets? margin;
  final CenterMessagePosition position;
  final List<Widget>? prefixChildren;
  final List<Widget>? suffixChildren;
  final String headline;
  final double? headlineFontSize;
  final String subtitle;
  final double? subtitleFontSize;
  final Color color;
  final bool isLoader;
  final Widget? loaderWidget;
  final bool doesExpand;
  final double? progress;

  final String? actionText;
  final double? actionFontSize;
  final Function? onActionPressed;

  const CenterMessage({
    Key? key,
    this.margin,
    this.position = CenterMessagePosition.above,
    this.prefixChildren,
    this.suffixChildren,
    required this.headline,
    this.headlineFontSize,
    required this.subtitle,
    this.subtitleFontSize,
    this.color = Colors.white,
    this.isLoader = false,
    this.loaderWidget,
    this.progress,
    this.actionText,
    this.onActionPressed,
    this.actionFontSize,
    this.doesExpand = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.safeBlockHorizontal * 8),
      margin: margin ?? EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (doesExpand) Spacer(flex: 1),
          if (prefixChildren != null) ...prefixChildren!,
          HeadlineText(
            text: headline,
            maxLines: 2,
            textAlign: TextAlign.center,
            fontSize: headlineFontSize ?? SizeConfig.safeBlockHorizontal * 5.3,
            color: color,
          ),
          SizedBox(height: SizeConfig.safeBlockVertical * 2),
          NormalText(
            text: subtitle,
            textAlign: TextAlign.center,
            fontSize: subtitleFontSize ?? SizeConfig.safeBlockHorizontal * 4,
            color: color,
          ),
          if (actionText != null) SizedBox(height: SizeConfig.safeBlockVertical * 2),
          if (actionText != null)
            RecognizerText(
              onPressed: () => onActionPressed?.call(),
              text: actionText!,
              fontSize: actionFontSize ?? SizeConfig.safeBlockHorizontal * 5,
            ),
          if (isLoader) SizedBox(height: SizeConfig.safeBlockVertical * 4),
          if (isLoader && loaderWidget != null) loaderWidget!,
          if (isLoader && loaderWidget == null) CircularProgressIndicator(value: progress == 0 ? null : progress),
          if (suffixChildren != null) ...suffixChildren!,
          if (doesExpand) Spacer(flex: position == CenterMessagePosition.above ? 2 : 1),
        ],
      ),
    );
  }
}
