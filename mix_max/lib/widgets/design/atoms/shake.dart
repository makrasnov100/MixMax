import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Briefly shakes [child] sideways whenever [trigger] changes value.
///
/// A lightweight "nope" / attention nudge — used when an action is blocked by a
/// missing requirement (e.g. pressing "Run experiment" with no parameters yet).
/// Drive it by passing a value that changes each time you want a shake (a
/// monotonically increasing counter is the simplest); equal consecutive values
/// are ignored so an unrelated rebuild won't re-fire the animation.
class MixMaxShake extends StatefulWidget {
  final Object? trigger;
  final Widget child;

  /// Peak horizontal travel in logical pixels.
  final double amplitude;

  /// Number of left-right oscillations per shake.
  final int shakes;

  final Duration duration;

  const MixMaxShake({
    Key? key,
    required this.trigger,
    required this.child,
    this.amplitude = 8,
    this.shakes = 3,
    this.duration = const Duration(milliseconds: 450),
  }) : super(key: key);

  @override
  State<MixMaxShake> createState() => _MixMaxShakeState();
}

class _MixMaxShakeState extends State<MixMaxShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void didUpdateWidget(MixMaxShake old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Decaying sine: a few full oscillations that taper to rest.
        final offset = math.sin(t * math.pi * 2 * widget.shakes) *
            widget.amplitude *
            (1 - t);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}
