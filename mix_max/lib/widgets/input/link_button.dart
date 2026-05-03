import 'package:flutter/material.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/widgets/text/normal_text.dart';

class LinkButton extends StatelessWidget {
  final String? labelText;
  final String buttonText;
  final Color? buttonColor;
  final Function? onPress;
  final double? maxWidth;

  final String? analyticsEvent;
  final Map<String, String?>? analyticsParams;

  const LinkButton({
    Key? key,
    this.labelText,
    required this.buttonText,
    this.buttonColor,
    this.onPress,
    this.analyticsEvent,
    this.maxWidth,
    this.analyticsParams,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double finalMaxWidth = SizeConfig.safeBlockHorizontal * 100;
    if (maxWidth != null) {
      finalMaxWidth = maxWidth!;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (labelText != null)
          NormalText(
            textAlign: TextAlign.center,
            text: labelText,
            fontSize: SizeConfig.getFontSize(3.2),
            fontWeight: FontWeight.w600,
          ),
        if (labelText != null) SizedBox(width: SizeConfig.safeBlockHorizontal * 3),
        TextButton(
          onPressed: () {
            onPress?.call();
          },
          style: TextButton.styleFrom(
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2)),
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.safeBlockHorizontal * 2,
              vertical: SizeConfig.safeBlockHorizontal * 1,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: finalMaxWidth),
            child: NormalText(
              text: buttonText,
              color: AppColors.grey,
              fontSize: SizeConfig.getFontSize(3),
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              textAlign: TextAlign.center,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
