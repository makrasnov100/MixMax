import 'package:flutter/material.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/ui/size_config.dart';

class GoBackButton extends StatelessWidget {
  final bool isDark;
  final Function? onPressed;
  final Widget? rightSideChild;
  final Color backgroundColor;
  const GoBackButton({
    Key? key,
    this.isDark = false,
    this.onPressed,
    this.rightSideChild,
    this.backgroundColor = Colors.transparent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          margin: EdgeInsets.all(SizeConfig.safeBlockHorizontal),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 3),
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 3),
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 3)),
                width: SizeConfig.safeBlockHorizontal * 10,
                height: SizeConfig.safeBlockHorizontal * 10,
                child: InkWell(
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? AppColors.dark : AppColors.light,
                      size: SizeConfig.safeBlockHorizontal * 8,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      onPressed != null ? onPressed?.call() : Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: SizeConfig.safeBlockHorizontal * 2),
        if (rightSideChild != null) rightSideChild!,
      ],
    );
  }
}
