import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';

/// The run-count pill in the Experiment Details top bar — a tappable affordance
/// that opens the Run History page.
///
/// Source: `design_app/screens.jsx` `RunsPill`. Styled to sit beside the round
/// back / menu buttons: a white `surface` pill with a hairline ring and a soft
/// shadow, a gold flask glyph, the "{n} runs" count, and a trailing chevron
/// hinting it drills into the run list. Replaces the inert run-count [MixMaxChip]
/// that previously occupied this slot.
class RunsPill extends StatelessWidget {
  /// Number of completed runs to show in the label.
  final int count;

  /// Opens the run history.
  final VoidCallback onTap;

  const RunsPill({Key? key, required this.count, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.hairline, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D221F2A), // rgba(34,31,42,0.05)
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MixMaxIcon(
                MixMaxGlyph.flask,
                size: 17,
                color: AppColors.gold,
              ),
              const SizedBox(width: 7),
              Text(
                '$count run${count == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontFamily: AppFonts.sans,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 7),
              const MixMaxIcon(
                MixMaxGlyph.chevRight,
                size: 16,
                color: AppColors.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
