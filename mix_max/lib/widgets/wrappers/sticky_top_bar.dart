import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/round_button.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';

/// Pins a screen's top bar — the back affordance and any trailing actions — to
/// the top of the page so it stays reachable while the body scrolls underneath.
///
/// The bar floats over the scrollable [child] inside a [Stack], so the page's
/// scroll view must reserve [contentInset] of top padding to clear it. A soft
/// bg → transparent fade along the bar's lower edge lets content slip cleanly
/// beneath it. Mirrors the sticky footer treatment used on the run flows.
class StickyTopBar extends StatelessWidget {
  /// Top padding the scrollable [child] should use so its first element clears
  /// the floating bar (back button height + the bar's vertical padding).
  static const double contentInset = 62;

  /// Back affordance handler — wired to the leading round button.
  final VoidCallback onBack;

  /// Optional right-aligned actions (a chip, a run-count pill + more button…).
  final Widget? trailing;

  /// The scrollable page body the bar floats over.
  final Widget child;

  const StickyTopBar({
    super.key,
    required this.onBack,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,

        // Floating bar over a bg → transparent fade so content slips under it.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.bg, AppColors.bg, Color(0x00FBF7F0)],
                stops: [0.0, 0.72, 1.0],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MixMaxRoundButton(glyph: MixMaxGlyph.arrowLeft, onTap: onBack),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
