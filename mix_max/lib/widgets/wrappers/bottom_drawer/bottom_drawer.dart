import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/widgets/functinal/pop_on_orientation_change.dart';
import 'package:mix_max/widgets/text/headline_text.dart';

class BottomDrawer extends StatelessWidget {
  final List<Widget>? children;
  final double height;
  final String? title;
  final double? horizontalMargins;
  final bool showHandle;
  final double borderRadius;
  const BottomDrawer({
    Key? key,
    this.children,
    this.height = -1,
    this.title,
    this.horizontalMargins,
    this.showHandle = true,
    this.borderRadius = 15,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double finalHeight = height == -1 ? SizeConfig.safeBlockVertical * 40 : height;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: SizeConfig.screenWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(SizeConfig.safeBlockHorizontal * borderRadius),
            topRight: Radius.circular(SizeConfig.safeBlockHorizontal * borderRadius),
          ),
        ),
        constraints: BoxConstraints(maxHeight: finalHeight + MediaQuery.of(context).viewInsets.bottom),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalMargins ?? SizeConfig.safeBlockHorizontal * 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopOnOrientationChange(),
              if (showHandle == true)
                Container(
                  height: SizeConfig.safeBlockVertical * 1.2,
                  width: SizeConfig.safeBlockHorizontal * 25,
                  margin: EdgeInsets.symmetric(vertical: SizeConfig.safeBlockVertical * 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.all(Radius.circular(SizeConfig.safeBlockHorizontal * 15)),
                  ),
                ),
              if (title != null && title != "")
                Container(
                  margin: EdgeInsets.only(bottom: SizeConfig.safeBlockVertical * 2),
                  child: HeadlineText(
                    text: title!,
                    fontSize: SizeConfig.getFontSize(4),
                    color: AppColors.dark,
                  ),
                ),
              ...children!,
              SizedBox(height: SizeConfig.safeBlockVertical),
            ],
          ),
        ),
      ),
    );
  }
}
