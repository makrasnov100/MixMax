import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tap_ripple.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';

/// One choice in a [MixMaxSegmented] control — its [value], a [label], and an
/// optional leading [icon].
class MixMaxSegment<T> {
  final T value;
  final String label;
  final MixMaxGlyph? icon;

  const MixMaxSegment({required this.value, required this.label, this.icon});
}

/// A full-width segmented control — two-or-more equal-flex buttons where exactly
/// one is selected (e.g. the outcome goal: Minimize / Maximize).
///
/// Source: `drawers.jsx` `Segmented`. Each segment is a 50px-tall cell at the
/// 14px `rField` radius: the selected one takes an ink fill with white ink, the
/// rest sit on a surface fill with a hairline ring and soft ink. Unlike
/// [MixMaxSelectablePill] (which hugs its label), segments share the width
/// evenly so the control reads as one bar.
class MixMaxSegmented<T> extends StatelessWidget {
  final List<MixMaxSegment<T>> options;

  /// The currently selected value.
  final T value;

  /// Fires with the tapped segment's value.
  final ValueChanged<T> onChanged;

  const MixMaxSegmented({
    Key? key,
    required this.options,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _segment(options[i])),
        ],
      ],
    );
  }

  Widget _segment(MixMaxSegment<T> option) {
    final selected = option.value == value;
    final fg = selected ? Colors.white : AppColors.inkSoft;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      height: 50,
      decoration: BoxDecoration(
        color: selected ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.ink : AppColors.hairline,
          width: 1.5,
        ),
      ),
      child: MixMaxInk(
        onTap: () => onChanged(option.value),
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.icon != null) ...[
                MixMaxIcon(option.icon!, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                option.label,
                style: TextStyle(
                  fontFamily: AppFonts.sans,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: fg,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
