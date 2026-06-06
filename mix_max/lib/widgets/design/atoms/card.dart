import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';

/// White elevated surface — the default container for content in the
/// "Quiet Instrument" system.
///
/// Source: `screens.jsx` cards. A white `surface` fill, a single 1px `hairline`
/// border, the soft two-layer `CARD_SHADOW`, and a 20px (`rCard`) radius. The
/// border + barely-there shadow give it a calm lift off the warm `bg` without
/// shouting.
///
/// Knobs cover the common variations seen in the design:
///   • [onTap]         — make the whole card a tap target (no ripple, matching
///                       the design's removed tap highlight).
///   • [elevated]      — drop the shadow for flush/inset cards.
///   • [clipContents]  — clip children to the rounded corners (for cards whose
///                       content bleeds to the edge, e.g. imagery).
///   • [color]/[padding]/[margin] — straightforward overrides.
class MixMaxCard extends StatelessWidget {
  final Widget child;

  /// Inner padding. Defaults to the design's `18 / 18 / 16` (T R B / L).
  final EdgeInsetsGeometry padding;

  /// Outer spacing around the card.
  final EdgeInsetsGeometry? margin;

  /// Whole-card tap handler. Null leaves the card inert.
  final VoidCallback? onTap;

  /// Whether to paint the soft drop shadow. Off → a flat bordered surface.
  final bool elevated;

  /// Clip children to the rounded corners (edge-to-edge content).
  final bool clipContents;

  /// Surface fill. Defaults to white `AppColors.surface`.
  final Color? color;

  const MixMaxCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 16),
    this.margin,
    this.onTap,
    this.elevated = true,
    this.clipContents = false,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      clipBehavior: clipContents ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: AppColors.hairline, width: 1),
        boxShadow: elevated ? _cardShadow : null,
      ),
      child: child,
    );

    final content = margin != null ? Padding(padding: margin!, child: card) : card;

    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: content),
    );
  }
}

// Border radius — design token `rCard` (theme.jsx).
const double _kRadius = 20;

// CARD_SHADOW — '0 1px 2px rgba(34,31,42,0.04), 0 8px 22px -12px rgba(34,31,42,0.10)'
const List<BoxShadow> _cardShadow = [
  BoxShadow(color: Color(0x0A221F2A), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(color: Color(0x1A221F2A), offset: Offset(0, 8), blurRadius: 22, spreadRadius: -12),
];
