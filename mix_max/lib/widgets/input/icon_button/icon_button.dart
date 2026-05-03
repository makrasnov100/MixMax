import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/ui/size_config.dart';

class AppIconButton extends StatelessWidget {
  final Function? onPressed;
  final Function? onLongPress;
  final String text;
  final Color? color;
  final Gradient? gradient;
  final String svgIconStart;
  final IconData? iconEnd;
  final String? svgIconEnd;
  final Widget? child;
  final bool spaceOutside;
  final bool isOutline;
  final bool isDark;
  final bool enlargeSvgIcon;
  final bool noColorOverride;
  final String? badgeText;
  final double? fontSize;
  final Color? fontColor;
  final Color? outlineColor;

  final EdgeInsets? customButtonMargin;
  final EdgeInsets? customIconMargin;
  final EdgeInsets? customEndIconMargin;

  const AppIconButton({
    Key? key,
    this.onPressed,
    this.onLongPress,
    required this.text,
    this.color,
    this.gradient,
    this.svgIconStart = "",
    this.iconEnd,
    this.svgIconEnd = "",
    this.child,
    this.spaceOutside = false,
    this.isOutline = false,
    this.isDark = false,
    this.enlargeSvgIcon = false,
    this.customButtonMargin,
    this.customIconMargin,
    this.customEndIconMargin,
    this.noColorOverride = false,
    this.badgeText,
    this.fontSize,
    this.fontColor,
    this.outlineColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SizeConfig.safeBlockVertical * 7,
      margin: customButtonMargin ?? EdgeInsets.symmetric(vertical: SizeConfig.safeBlockVertical * 1),
      decoration:
          gradient != null
              ? BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2.6),
              )
              : null,
      child: ElevatedButton(
        onLongPress: () => onLongPress?.call(),
        onPressed: () async {
          onPressed?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: (gradient != null || isOutline == true) ? Colors.transparent : color,
          elevation: 0.0,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2.6),
            side: BorderSide(
              color:
                  isOutline == true ? (outlineColor ?? (isDark ? AppColors.dark : Colors.white)) : Colors.transparent,
              width: isOutline == true ? 1 : 0,
            ),
          ),
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
        ),
        child:
            child ??
            Row(
              children: [
                if (spaceOutside == true) Spacer(),
                if (svgIconStart != "")
                  Container(
                    margin:
                        customIconMargin ??
                        (spaceOutside == true
                            ? EdgeInsets.only(
                              right: SizeConfig.safeBlockHorizontal * 2.6,
                              top: SizeConfig.safeBlockHorizontal * 2.6,
                              bottom: SizeConfig.safeBlockHorizontal * 2.6,
                            )
                            : EdgeInsets.only(
                              top:
                                  enlargeSvgIcon == false
                                      ? SizeConfig.safeBlockHorizontal * 2.6
                                      : SizeConfig.safeBlockHorizontal * 1.3,
                              bottom:
                                  enlargeSvgIcon == false
                                      ? SizeConfig.safeBlockHorizontal * 2.6
                                      : SizeConfig.safeBlockHorizontal * 1.3,
                              right: SizeConfig.safeBlockHorizontal * (SizeConfig.isTablet() ? 5 : 3),
                              left: SizeConfig.safeBlockHorizontal * (SizeConfig.isTablet() ? 5 : 3),
                            )),
                    child: FittedBox(
                      fit: BoxFit.fitHeight,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: SizeConfig.safeBlockHorizontal * 13.3),
                        child: SvgPicture.asset(
                          svgIconStart,
                          semanticsLabel: 'Button Icon',
                          width: SizeConfig.safeBlockHorizontal * 6.65,
                          height: SizeConfig.safeBlockHorizontal * 6.65,
                          colorFilter:
                              noColorOverride == true
                                  ? null
                                  : ColorFilter.mode(
                                    fontColor ?? (isDark ? AppColors.dark : Colors.white),
                                    BlendMode.srcIn,
                                  ),
                          theme: SvgTheme(
                            currentColor:
                                noColorOverride == true
                                    ? AppColors.dark
                                    : fontColor ?? (isDark ? AppColors.dark : Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (text != "")
                  Text(
                    text.toUpperCase(),
                    textAlign: spaceOutside == true ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      color: fontColor ?? (isDark ? AppColors.dark : Colors.white),
                      fontSize: fontSize ?? SizeConfig.getFontSize(3.3),
                      fontWeight: FontWeight.w400,
                      fontFamily: "OpenSans",
                    ),
                  ),
                if (text != "" && spaceOutside == false) Spacer(),
                if (iconEnd != null)
                  Container(
                    padding: EdgeInsets.zero,
                    margin:
                        spaceOutside == true
                            ? EdgeInsets.only(
                              left: SizeConfig.safeBlockVertical * 1.3,
                              top: SizeConfig.safeBlockVertical * 1.3,
                              bottom: SizeConfig.safeBlockVertical * 1.3,
                            )
                            : EdgeInsets.symmetric(
                              vertical: SizeConfig.safeBlockVertical * 1.3,
                              horizontal: SizeConfig.safeBlockHorizontal * 3,
                            ),
                    child: Icon(iconEnd, color: fontColor ?? (isDark ? AppColors.dark : Colors.white)),
                  ),
                if (svgIconEnd != "" && svgIconEnd != null)
                  Container(
                    margin:
                        customEndIconMargin ??
                        (spaceOutside == true
                            ? EdgeInsets.only(
                              left: SizeConfig.safeBlockHorizontal * 2.6,
                              top: SizeConfig.safeBlockHorizontal * 2.6,
                              bottom: SizeConfig.safeBlockHorizontal * 2.6,
                            )
                            : EdgeInsets.only(
                              top:
                                  enlargeSvgIcon == false
                                      ? SizeConfig.safeBlockHorizontal * 2.6
                                      : SizeConfig.safeBlockHorizontal * 1.3,
                              bottom:
                                  enlargeSvgIcon == false
                                      ? SizeConfig.safeBlockHorizontal * 2.6
                                      : SizeConfig.safeBlockHorizontal * 1.3,
                              right: SizeConfig.safeBlockHorizontal * (SizeConfig.isTablet() ? 5 : 3),
                              left: SizeConfig.safeBlockHorizontal * (SizeConfig.isTablet() ? 5 : 3),
                            )),
                    child: FittedBox(
                      fit: BoxFit.fitHeight,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: SizeConfig.safeBlockHorizontal * 13.3),
                        child: SvgPicture.asset(
                          svgIconEnd!,
                          semanticsLabel: 'Button Icon',
                          width: SizeConfig.safeBlockHorizontal * 6.65,
                          height: SizeConfig.safeBlockHorizontal * 6.65,
                          colorFilter:
                              noColorOverride == true
                                  ? null
                                  : ColorFilter.mode(
                                    fontColor ?? (isDark ? AppColors.dark : Colors.white),
                                    BlendMode.srcIn,
                                  ),
                          theme: SvgTheme(
                            currentColor:
                                noColorOverride == true
                                    ? AppColors.dark
                                    : fontColor ?? (isDark ? AppColors.dark : Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (spaceOutside == true) Spacer(),
              ],
            ),
      ),
    );
  }
}
