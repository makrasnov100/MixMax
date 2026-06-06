import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';

/// The bottom-sheet panel surface for the "Quiet Instrument" drawers.
///
/// Source: `drawers.jsx` `DrawerShell` (the inner panel). A warm `bg` sheet
/// pinned to the bottom of the screen: its top corners rounded to the 30px
/// `rDrawer` token, a soft *upward* shadow lifting it off the content below, and
/// a centered drag-handle bar at the very top.
///
/// This atom is deliberately *only* the container + handle. The scrim, slide-up
/// entrance animation, title / subtitle header and pinned footer that the full
/// design composes around it (`DrawerShell`) are left to the molecule or page
/// that presents the sheet — so the atom stays a pure, reusable surface.
///
/// The sheet hugs its [child]'s height (`MainAxisSize.min`) but never grows past
/// [maxHeightFraction] of the screen; give the child a scroll view when its
/// content can overflow that cap.
class MixMaxDrawerContainer extends StatelessWidget {
  final Widget child;

  /// Cap on the sheet's height as a fraction of the screen height. Mirrors the
  /// design's `maxHeight: '90%'`.
  final double maxHeightFraction;

  const MixMaxDrawerContainer({
    Key? key,
    required this.child,
    this.maxHeightFraction = 0.9,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * maxHeightFraction;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(_kRadius)),
          boxShadow: _drawerShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _HandleBar(),
            // Flexible so a scrollable body can shrink to fit under the
            // maxHeight cap instead of overflowing.
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// The centered 40×5 drag handle — a rounded `hairlineStrong` pill with the
/// design's 10px top breathing room.
class _HandleBar extends StatelessWidget {
  const _HandleBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 2),
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.hairlineStrong,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

// Top-corner radius — design token `rDrawer` (theme.jsx).
const double _kRadius = 30;

// '0 -12px 40px rgba(28,24,20,0.22)' — a soft shadow cast upward so the sheet
// reads as floating above the dimmed content beneath it.
const List<BoxShadow> _drawerShadow = [
  BoxShadow(color: Color(0x381C1814), offset: Offset(0, -12), blurRadius: 40),
];
