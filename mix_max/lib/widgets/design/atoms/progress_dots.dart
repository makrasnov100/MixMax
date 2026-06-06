import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';

/// A row of pill markers showing position within a short sequence — the top-bar
/// progress indicator of the outcome-rating flow.
///
/// Source: `ui.jsx` `ProgressDots`. Each step is a 5px dot; the current step
/// stretches to a 22px gold pill, completed steps are sage, upcoming steps a
/// faint hairline. Width and color animate over 200ms as [index] advances.
class MixMaxProgressDots extends StatelessWidget {
  /// Number of steps.
  final int total;

  /// Zero-based index of the active step.
  final int index;

  const MixMaxProgressDots({
    Key? key,
    required this.total,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 5,
            width: i == index ? 22 : 5,
            decoration: BoxDecoration(
              color: i == index
                  ? AppColors.gold
                  : (i < index ? AppColors.sage : AppColors.hairlineStrong),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ],
    );
  }
}
