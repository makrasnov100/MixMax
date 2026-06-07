import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';

/// How the Run History list is ordered.
enum RunSortMode { recent, rated }

/// The pill segmented control at the top of the Run History page — switches the
/// run list between "Most recent" and "Highest rated".
///
/// Source: `design_app/screens.jsx` `SortToggle`. A fully-rounded `bgAlt` track
/// holding two equal-flex cells: the active cell lifts onto a white `surface`
/// fill with a soft shadow and a gold glyph, while the inactive cell stays flat
/// with a faint glyph and soft-ink label.
///
/// This is intentionally a separate control from [MixMaxSegmented] (the
/// ink-filled rectangular picker used inside drawers): the toggle is quieter and
/// pill-shaped so it reads as a list filter sitting above the runs rather than a
/// committing form choice.
class RunSortToggle extends StatelessWidget {
  /// The currently selected ordering.
  final RunSortMode value;

  /// Fires with the tapped cell's mode.
  final ValueChanged<RunSortMode> onChanged;

  const RunSortToggle({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _cell(
              mode: RunSortMode.recent,
              label: 'Most recent',
              glyph: MixMaxGlyph.clock,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _cell(
              mode: RunSortMode.rated,
              label: 'Highest rated',
              glyph: MixMaxGlyph.trophy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell({
    required RunSortMode mode,
    required String label,
    required MixMaxGlyph glyph,
  }) {
    final active = mode == value;

    return GestureDetector(
      onTap: () => onChanged(mode),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x1A221F2A), // rgba(34,31,42,0.10)
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MixMaxIcon(
                glyph,
                size: 15,
                color: active ? AppColors.gold : AppColors.inkFaint,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.sans,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: active ? AppColors.ink : AppColors.inkSoft,
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
