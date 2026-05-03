import 'package:flutter/material.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/widgets/input/icon_button/icon_button.dart';
import 'package:mix_max/widgets/text/headline_text.dart';
import 'package:mix_max/widgets/text/normal_text.dart';
import 'package:mix_max/widgets/wrappers/bottom_drawer/bottom_drawer.dart';

class ConfirmBottomDrawer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double? subtitleFontSize;
  final String? yesText;
  final String? noText;
  final bool showYesButton;
  final bool showNoButton;
  final Function? yesCallback;
  final Function? noCallback;
  final String? confirmAction;
  final Widget? child;
  final bool showMarginBetweenContentAndActions;
  final bool spaceOutsideActions;

  const ConfirmBottomDrawer({
    Key? key,
    required this.title,
    this.subtitle,
    this.subtitleFontSize,
    this.yesText,
    this.noText,
    this.showYesButton = true,
    this.showNoButton = true,
    this.yesCallback,
    this.noCallback,
    this.confirmAction,
    this.child,
    this.showMarginBetweenContentAndActions = true,
    this.spaceOutsideActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomDrawer(
      children: [
        HeadlineText(text: title, maxLines: 3, fontSize: SizeConfig.getFontSize(5)),
        SizedBox(height: SizeConfig.safeBlockVertical),
        if (subtitle != null)
          NormalText(
            text: subtitle,
            textAlign: TextAlign.center,
            fontSize: SizeConfig.getFontSize(subtitleFontSize ?? 4.5),
          ),
        if (child != null) SizedBox(height: SizeConfig.safeBlockVertical),
        if (child != null) child!,
        if (showMarginBetweenContentAndActions) SizedBox(height: SizeConfig.safeBlockVertical * 2),
        Container(
          margin: EdgeInsets.only(bottom: SizeConfig.safeBlockHorizontal * 2),
          child: Row(
            children: [
              if (showYesButton)
                Expanded(
                  child: AppIconButton(
                    onPressed:
                        yesCallback ??
                        () {
                          Navigator.pop(context, true);
                        },
                    svgIconStart: "assets/svg/icons/checkmark_icon.svg",
                    text: yesText ?? 'Yes',
                    color: AppColors.addGreen,
                    spaceOutside: spaceOutsideActions,
                  ),
                ),
              if (showNoButton && showYesButton) SizedBox(width: SizeConfig.safeBlockHorizontal * 2),
              if (showNoButton)
                Expanded(
                  child: AppIconButton(
                    onPressed:
                        noCallback ??
                        () {
                          Navigator.pop(context, false);
                        },
                    svgIconStart: "assets/svg/icons/cancel_icon.svg",
                    text: noText ?? 'No',
                    color: AppColors.dangerRed,
                    spaceOutside: spaceOutsideActions,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
