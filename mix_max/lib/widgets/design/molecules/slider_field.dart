import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/inputs/slider_input.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/format.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';

/// A [MixMaxSliderInput] with its numeric bounds labelled beneath — the full
/// rating slider as it appears on the outcome screen.
///
/// Source: `screens.jsx` `SliderRow`. Below the track sit the formatted [min]
/// and [max] at the two ends. Snapping follows [increment]: the slider divides
/// the range into `(max - min) / increment` evenly spaced stops.
class MixMaxSliderField extends StatelessWidget {
  final double value;
  final double min;
  final double max;

  /// Increment the thumb snaps to. Non-positive values fall back to 1.
  final double increment;

  final ValueChanged<double>? onChanged;

  /// Formats the two end labels. Defaults to [MixMaxFormat.number]; a duration
  /// parameter passes its own `formatDuration` so the ends read as `1m` / `10m`.
  final String Function(num?)? format;

  const MixMaxSliderField({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    this.increment = 1,
    this.onChanged,
    this.format,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final range = max - min;
    final s = increment > 0 ? increment : 1.0;
    final divisions = range > 0 ? (range / s).round().clamp(1, 10000) : null;
    final String Function(num?) fmt =
        format ?? (num? v) => MixMaxFormat.number(v?.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MixMaxSliderInput(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CaptionText(
                text: fmt(min),
                fontSize: 14,
                color: AppColors.inkFaint,
              ),
              CaptionText(
                text: fmt(max),
                fontSize: 14,
                color: AppColors.inkFaint,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
