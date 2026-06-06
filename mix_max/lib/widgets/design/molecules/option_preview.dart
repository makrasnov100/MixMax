import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/chip.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';

/// A horizontal preview of a choice parameter's options as soft chips, with a
/// quiet `+N` when there are more than [max] of them.
///
/// Source: `ui.jsx` `OptionPreview`. The value visual for a `choice` parameter —
/// it shows the first few options and tallies the rest rather than wrapping a
/// long list across the row.
class OptionPreview extends StatelessWidget {
  final List<String> options;

  /// How many chips to show before collapsing the remainder into `+N`.
  final int max;

  final MixMaxChipTone tone;

  const OptionPreview({
    Key? key,
    required this.options,
    this.max = 3,
    this.tone = MixMaxChipTone.soft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shown = options.take(max).toList();
    final extra = options.length - shown.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final o in shown) MixMaxChip(label: o, tone: tone),
        if (extra > 0)
          Text(
            '+$extra',
            style: const TextStyle(
              fontFamily: AppFonts.sans,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: AppColors.inkFaint,
              height: 1,
            ),
          ),
      ],
    );
  }
}
