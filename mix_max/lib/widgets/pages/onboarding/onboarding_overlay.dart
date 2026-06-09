import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/progress_dots.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/eyebrow_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';
import 'package:mix_max/widgets/pages/onboarding/onboarding_controller.dart';

/// Wraps the app (via `MaterialApp.builder`) and floats the onboarding tour on
/// top of every route while it is active.
///
/// Mounting here — above the [Navigator] rather than inside its overlay —
/// guarantees the dim + spotlight + explainer always sit over whatever screen
/// the [OnboardingController] has pushed, regardless of route transitions.
class OnboardingHost extends StatefulWidget {
  final Widget child;

  const OnboardingHost({super.key, required this.child});

  @override
  State<OnboardingHost> createState() => _OnboardingHostState();
}

class _OnboardingHostState extends State<OnboardingHost> {
  final OnboardingController _controller = getIt<OnboardingController>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_controller.active)
          Positioned.fill(child: _OnboardingOverlay(controller: _controller)),
      ],
    );
  }
}

/// The active tour layer: a dimming scrim with a rounded spotlight cut over the
/// current target, a tap-absorber so the app beneath stays inert, and the
/// bottom explainer card.
class _OnboardingOverlay extends StatefulWidget {
  final OnboardingController controller;

  const _OnboardingOverlay({required this.controller});

  @override
  State<_OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<_OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  /// Drives the spotlight's gentle pulse so the tappable highlight draws the eye.
  final Stopwatch _clock = Stopwatch()..start();

  static const double _holePad = 8;

  @override
  void initState() {
    super.initState();
    // The spotlight target moves while routes transition and lists scroll into
    // place; rebuild every frame so the cutout stays glued to it. The body is
    // just a rect read + repaint, so this is cheap.
    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// On-screen rect of the current step's highlighted widget, or null while it
  /// is not laid out yet (the scrim then dims the whole screen).
  Rect? _targetRect() {
    final context = widget.controller.currentTargetKey?.currentContext;
    final box = context?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final hole = _targetRect();
    final size = MediaQuery.of(context).size;

    // 0..1..0 pulse, ~1.2s period.
    final phase = (_clock.elapsedMilliseconds % 1200) / 1200;
    final pulse = (1 - (phase * 2 - 1).abs());

    // Drop the explainer to the top when the highlight sits in the lower half of
    // the screen (e.g. the Outcomes card), so the card never covers it.
    final cardAtTop = hole != null && hole.center.dy > size.height * 0.52;

    // Mounted above the Navigator (via MaterialApp.builder), so the overlay has
    // no Material ancestor — wrap it in a transparent one so text renders
    // normally instead of with the debug yellow underlines.
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Dim + spotlight (visual only — pointers handled below).
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SpotlightPainter(hole: hole, pulse: pulse),
              ),
            ),
          ),

          // Swallow every tap so the app underneath can't be operated.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
            ),
          ),

          // The highlighted element itself advances the tour: a tap target laid
          // over the spotlight, above the absorber.
          if (hole != null)
            Positioned.fromRect(
              rect: hole.inflate(_holePad),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.next,
              ),
            ),

          // Explainer card — top or bottom, above everything so its Skip works.
          Positioned(
            left: 0,
            right: 0,
            top: cardAtTop ? 0 : null,
            bottom: cardAtTop ? null : 0,
            child: SafeArea(
              bottom: !cardAtTop,
              top: cardAtTop,
              child: _ExplainerCard(controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a translucent scrim over the whole screen with a single rounded hole
/// punched out around [hole], ringed in gold to draw the eye.
class _SpotlightPainter extends CustomPainter {
  final Rect? hole;

  /// 0..1 pulse value, animating the ring/glow to signal the highlight is tappable.
  final double pulse;

  const _SpotlightPainter({required this.hole, this.pulse = 0});

  static const double _pad = 8;
  static const double _radius = 18;
  static const Color _scrim = Color(0xB3120F0C); // ~0.70 warm near-black

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final spotlight = hole == null
        ? null
        : RRect.fromRectAndRadius(
            hole!.inflate(_pad),
            const Radius.circular(_radius),
          );

    // Scrim with the spotlight cleared out of it.
    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(bounds, Paint()..color = _scrim);
    if (spotlight != null) {
      canvas.drawRRect(spotlight, Paint()..blendMode = BlendMode.clear);
    }
    canvas.restore();

    if (spotlight != null) {
      // Pulsing gold glow just outside the cutout.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          hole!.inflate(_pad + 3 + pulse * 5),
          const Radius.circular(_radius + 4),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + pulse * 2
          ..color = AppColors.gold.withValues(alpha: 0.18 + pulse * 0.22),
      );
      // Crisp gold ring on the cutout edge.
      canvas.drawRRect(
        spotlight,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.gold,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.pulse != pulse;
}

/// The explainer card carrying the step kicker, title, body, a tap-to-continue
/// hint (the tour advances by pressing the highlighted element, not a button),
/// progress dots, and Skip.
class _ExplainerCard extends StatelessWidget {
  final OnboardingController controller;

  const _ExplainerCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final step = controller.currentStep;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33221F2A),
            offset: Offset(0, 12),
            blurRadius: 32,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EyebrowText(text: step.eyebrow, color: AppColors.gold),
          const SizedBox(height: 12),
          TitleText(text: step.title, fontSize: 22),
          const SizedBox(height: 8),
          BodyText(text: step.body, fontSize: 14, color: AppColors.inkSoft),
          const SizedBox(height: 16),
          // Tap-to-continue hint — the highlighted element is the real button.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.goldTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MixMaxIcon(
                  MixMaxGlyph.sparkle,
                  size: 16,
                  color: AppColors.goldText,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: CaptionText(
                    text: controller.isLastStep
                        ? 'Tap the highlighted card to finish'
                        : 'Tap the highlighted area to continue',
                    color: AppColors.goldText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              MixMaxProgressDots(
                total: controller.totalSteps,
                index: controller.step,
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.finish,
                child: const CaptionText(
                  text: 'Skip tour',
                  color: AppColors.inkFaint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
