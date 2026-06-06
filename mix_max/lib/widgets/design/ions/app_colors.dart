import 'package:flutter/material.dart';

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

  // ===========================================================================
  // [Quiet Instrument] — design system tokens (design_app/theme.jsx)
  // Editorial / calm / premium. Warm off-white, near-black ink, gold signature,
  // muted sage (parameters) + violet (outcomes). Use these for new UI.
  // ===========================================================================

  // [Surfaces]
  static const Color bg = Color(0xFFFBF7F0); // warm off-white app background
  static const Color bgAlt = Color(0xFFF4EEE3); // slightly deeper warm
  static const Color surface = Color(0xFFFFFFFF); // cards
  static const Color surfaceSoft = Color(0xFFFBF8F2); // inset fields
  static const Color scrim = Color.fromRGBO(28, 24, 20, 0.42);

  // [Ink]
  static const Color ink = Color(0xFF221F2A); // primary text / commit buttons
  static const Color inkSoft = Color(0xFF6E6A75); // secondary text
  static const Color inkFaint = Color(0xFFA9A4AE); // placeholders / tertiary
  static const Color hairline = Color(0xFFECE6DA); // warm borders
  static const Color hairlineStrong = Color(0xFFE0D9CB);

  // [Signature — Gold] optimization / run / active
  static const Color gold = Color(0xFFB5872B);
  static const Color goldDeep = Color(0xFF8A6519);
  static const Color goldTint = Color(0xFFF4EBD4); // gold soft background
  static const Color goldText = Color(0xFF7C5C16);

  // [Parameters — Sage]
  static const Color sage = Color(0xFF6E8A63);
  static const Color sageTint = Color(0xFFE9EFE3);
  static const Color sageText = Color(0xFF4C6743);

  // [Outcomes — Violet]
  static const Color violet = Color(0xFF7E719A);
  static const Color violetTint = Color(0xFFECE7F2);
  static const Color violetText = Color(0xFF5A4E78);

  // [Status]
  static const Color danger = Color(0xFFC0492F);

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
