import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tap_ripple.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/label_text.dart';

/// A quiet "nothing here yet" placeholder — a dashed-outline panel with a
/// neutral type tile, a title, and a one-line nudge.
///
/// Source: `screens.jsx` `EmptyHint`. Unlike a [MixMaxCard] it draws a dashed
/// `hairlineStrong` ring on the warm surface rather than a solid border + shadow,
/// signalling an empty slot waiting to be filled (e.g. "No parameters yet").
///
/// When [error] is set the whole panel switches to a soft red voice — danger
/// ring, tint fill and type tile — to flag a required-but-missing slot (e.g.
/// pressing "Run experiment" with no parameters yet). An optional [onTap] makes
/// the panel itself a tappable affordance (e.g. open the add-parameter drawer).
class MixMaxEmptyHint extends StatelessWidget {
  final MixMaxGlyph glyph;
  final String title;
  final String body;

  /// When true, paint the panel in the danger voice to flag a missing slot.
  final bool error;

  /// Tapping the whole panel. Null leaves it inert.
  final VoidCallback? onTap;

  const MixMaxEmptyHint({
    Key? key,
    required this.glyph,
    required this.title,
    required this.body,
    this.error = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final panel = CustomPaint(
      painter: _DashedRRectPainter(
        color: error ? AppColors.danger : AppColors.hairlineStrong,
        radius: 20, // rCard
      ),
      child: Container(
        // Surface fill sits inside the dashed ring (border-box in the design).
        decoration: BoxDecoration(
          color: error ? AppColors.dangerTint : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: MixMaxInk(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                MixMaxTile(
                  glyph: glyph,
                  tone: error ? MixMaxTileTone.danger : MixMaxTileTone.neutral,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LabelText(
                        text: title,
                        fontSize: 14.5,
                        color: error ? AppColors.dangerText : AppColors.ink,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      CaptionText(
                        text: body,
                        color: error ? AppColors.dangerText : AppColors.inkSoft,
                        fontWeight: FontWeight.w400,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return panel;
  }
}

/// Strokes a dashed rounded-rectangle outline — Flutter's [Border] can't dash,
/// so this paints the `1px dashed hairlineStrong` ring of [MixMaxEmptyHint].
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  static const double strokeWidth = 1;
  static const double dash = 5;
  static const double gap = 4;

  const _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Inset by half the stroke so the dashes sit fully inside the bounds.
    final rect = Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final source = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += dash + gap;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
