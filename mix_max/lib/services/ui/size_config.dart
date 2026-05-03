import 'package:flutter/widgets.dart';

enum ScreenType { phone, tablet }

class SizeConfig {
  static int mobileWidth = 600;
  static double goldenRatioPercentage = 61.8;

  static late MediaQueryData _mediaQueryData;
  static late Orientation orientation;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;

  static late double safeScreenHeight;
  static late double safeScreenWidth;
  static late double safeGoldenRatioScreenHeight;
  static late double _safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  static late ScreenType screenType;
  static late double bottomSafeAreaHeight;
  static late double topSafeAreaHeight;
  static late double pixelRatio;

  void init(
    BuildContext context,
  ) {
    double currentWidth = MediaQuery.of(context).size.width;
    double currentHeight = MediaQuery.of(context).size.height;

    orientation = currentWidth < currentHeight ? Orientation.portrait : Orientation.landscape;

    double portaitWidth = currentWidth < currentHeight ? currentWidth : currentHeight;
    double portaitHeight = currentWidth < currentHeight ? currentHeight : currentWidth;
    double portraitAspectRatio = portaitWidth / portaitHeight;

    screenWidth = portaitWidth == currentWidth ? currentWidth : portraitAspectRatio * currentHeight;
    screenHeight = currentHeight;

    _mediaQueryData = MediaQuery.of(context);
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    _safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeScreenWidth = screenWidth - _safeAreaHorizontal;
    safeScreenHeight = screenHeight - safeAreaVertical;
    safeGoldenRatioScreenHeight = safeScreenHeight * (goldenRatioPercentage / 100);
    safeBlockHorizontal = safeScreenWidth / 100;
    safeBlockVertical = safeScreenHeight / 100;

    screenType = screenWidth < mobileWidth ? ScreenType.phone : ScreenType.tablet;

    bottomSafeAreaHeight = _mediaQueryData.padding.bottom;
    topSafeAreaHeight = _mediaQueryData.padding.top;
    pixelRatio = _mediaQueryData.devicePixelRatio;
  }

  static bool isTablet() {
    return screenType == ScreenType.tablet;
  }

  static double getFontSize(double relativeSize) {
    return isTablet() ? (safeBlockHorizontal * relativeSize) : (1.2 * safeBlockHorizontal * relativeSize);
  }

  static double getWidth({required double tablet, required double phone}) {
    return isTablet() ? (safeBlockHorizontal * tablet) : (safeBlockHorizontal * phone);
  }

  static double getHeight({required double tablet, required double phone}) {
    return isTablet() ? (safeBlockVertical * tablet) : (safeBlockVertical * phone);
  }

  static double getRelativeWidth(double relativeSize) {
    return isTablet() ? (safeBlockHorizontal * relativeSize) : (1.2 * safeBlockHorizontal * relativeSize);
  }
}
