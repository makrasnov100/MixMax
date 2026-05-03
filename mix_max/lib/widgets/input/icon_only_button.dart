import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mix_max/services/ui/size_config.dart';

class AppIconOnlyButton extends StatelessWidget {
  final bool isLoading;
  final Function? onPressed;
  final String? svgIcon;
  final IconData? icon;
  final Color iconColor;
  final Color? backgroundColor;
  final EdgeInsets? margin;
  final bool isCircle;
  final Gradient? gradient;
  final BorderRadiusGeometry? borderRadius;
  final double? iconSize;
  final Widget? child;
  final bool disabled;

  final EdgeInsets? customIconMargin;

  const AppIconOnlyButton({
    Key? key,
    this.isLoading = false,
    this.onPressed,
    this.svgIcon,
    this.icon,
    this.iconColor = Colors.white,
    this.backgroundColor,
    this.margin,
    this.isCircle = true,
    this.gradient,
    this.borderRadius,
    this.customIconMargin,
    this.iconSize,
    this.child,
    this.disabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double iconSize = this.iconSize ?? SizeConfig.safeBlockHorizontal * 7;

    return Container(
      height: iconSize,
      width: iconSize,
      margin: margin,
      decoration:
          gradient != null
              ? BoxDecoration(
                gradient: gradient,
                borderRadius:
                    isCircle ? null : borderRadius ?? BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2.6),
                shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              )
              : null,
      child: ElevatedButton(
        onPressed: () async {
          if (disabled) {
            return;
          }

          onPressed?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? Colors.grey : backgroundColor,
          elevation: 0.0,
          shadowColor: Colors.black12,
          shape:
              isCircle == false
                  ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2),
                    side: BorderSide(color: Colors.transparent, width: 0),
                  )
                  : CircleBorder(),
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
        ),
        child:
            child ??
            Container(
              height: iconSize,
              width: iconSize,
              padding: customIconMargin ?? EdgeInsets.all(SizeConfig.getRelativeWidth(2)),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Visibility(
                  visible: isLoading,
                  replacement:
                      svgIcon != null
                          ? SvgPicture.asset(
                            svgIcon!,
                            semanticsLabel: "Icon Button",
                            width: iconSize - SizeConfig.safeBlockHorizontal * 3,
                            height: iconSize - SizeConfig.safeBlockHorizontal * 3,
                            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                          )
                          : Icon(icon, color: iconColor, size: iconSize - SizeConfig.safeBlockHorizontal * 3),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
      ),
    );
  }
}
