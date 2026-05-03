import 'package:flutter/material.dart';

//TODO TEMPLATE: update colors to match project
//NOTE: color palette can quickly be generated using https://coolors.co/
class AppColors {
  // [Palette Colors]
  static const Color actionOrange = Color(0xFFF9931F);
  static const Color optionLightBlue = Color(0xFF58BDBA);
  static const Color optionDarkBlue = Color(0xFF537BFF);
  static const Color addGreen = Color(0xFF04E474);
  static const Color infoPink = Color(0xFFFF4880);
  static const Color dangerRed = Color(0xFFFF3D3D);

  // [Shade Colors]
  static const Color dark = Color(0xFF0D0628);
  static const Color light = Color(0xFFE5E5E5);
  static const Color lightGrey = Color(0xFFE1E1E5);
  static const Color grey = Color.fromARGB(255, 174, 174, 174);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // [Background Colors]
  static const Color background = Color(0xFFF0ECE4);

  // [Primary Colors]
  static Color primaryColor = Color.fromRGBO(29, 211, 176, 1);
  static MaterialColor primary = MaterialColor(
    0xFF9A348E,
    const {
      50: Color.fromRGBO(29, 211, 176, .1),
      100: Color.fromRGBO(29, 211, 176, .2),
      200: Color.fromRGBO(29, 211, 176, .3),
      300: Color.fromRGBO(29, 211, 176, .4),
      400: Color.fromRGBO(29, 211, 176, .5),
      500: Color.fromRGBO(29, 211, 176, .6),
      600: Color.fromRGBO(29, 211, 176, .7),
      700: Color.fromRGBO(29, 211, 176, .8),
      800: Color.fromRGBO(29, 211, 176, .9),
      900: Color.fromRGBO(29, 211, 176, 1),
    },
  );
  static MaterialColor primaryDark = primary;

  // [Helper Functions]
  static Color darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  static Color lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}
