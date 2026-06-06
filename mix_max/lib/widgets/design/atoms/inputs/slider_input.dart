import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';

/// A large, controlled slider with a black handle — the outcome-rating control.
///
/// Source: `screens.jsx` `SliderRow` input. A rounded, gold-filled track over a
/// faint rail, with a prominent ink (black) thumb. Holds no state of its own: it
/// paints [value] within [min]..[max] and reports drags through [onChanged].
/// When [divisions] is set the thumb snaps to that many evenly spaced stops.
class MixMaxSliderInput extends StatelessWidget {
  final double value;
  final double min;
  final double max;

  /// Number of discrete stops. Null leaves the slider continuous.
  final int? divisions;

  /// Drag handler. Null renders a non-interactive slider.
  final ValueChanged<double>? onChanged;

  const MixMaxSliderInput({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: AppColors.gold,
        inactiveTrackColor: AppColors.hairlineStrong,
        thumbColor: AppColors.ink,
        overlayColor: const Color(0x1A221F2A),
        thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 13, elevation: 2),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
        trackShape: const RoundedRectSliderTrackShape(),
        // The scale is conveyed by the value readout and the min/max labels of
        // [MixMaxSliderField]; suppress Flutter's per-division tick marks so the
        // rail stays clean even over wide ranges.
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 0),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}
