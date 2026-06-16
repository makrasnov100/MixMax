import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';

/// Wraps [child] in a transparent [Material] + [InkWell] so taps paint the
/// platform ripple over the host's own background, clipped to its shape.
///
/// Pass [borderRadius] for rounded rects or [customBorder] (e.g. a
/// [CircleBorder]) for non-rect shapes. A null [onTap] returns [child]
/// untouched — inert, no ripple — so callers can pass an optional handler
/// straight through.
class MixMaxInk extends StatelessWidget {
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final Widget child;

  const MixMaxInk({
    Key? key,
    required this.onTap,
    required this.child,
    this.borderRadius,
    this.customBorder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: customBorder == null ? borderRadius : null,
        customBorder: customBorder,
        splashColor: AppColors.bgAlt,
        highlightColor: AppColors.bgAlt,
        child: child,
      ),
    );
  }
}
