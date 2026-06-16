import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/inputs/text_input.dart';
import 'package:mix_max/widgets/design/atoms/tap_ripple.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';

/// The Add-Parameter drawer's "Increment" picker for number / duration
/// parameters — a row of granularity preset pills (1 / 0.5 / 0.1 / 0.01) over a
/// "type a custom step" [MixMaxTextInput]. Both edit the same [controller], so
/// tapping a pill fills the field and typing a matching value lights the pill;
/// tapping the active pill clears it (back to a smooth range).
///
/// Source: `drawers.jsx` `IncrementField`. Lives under
/// `pages/experiment_details/` — specific to building a parameter, not a
/// general design-system molecule.
class IncrementField extends StatelessWidget {
  final TextEditingController controller;

  /// Fired when a pill sets / clears the value (the field's own onChanged covers
  /// typing). Lets the host re-render the active-pill state.
  final ValueChanged<String>? onChanged;

  const IncrementField({Key? key, required this.controller, this.onChanged})
    : super(key: key);

  // Whole-number first (its "whole" note hints at integers-only), then finer.
  static const List<({double value, String label, String? note})> _presets = [
    (value: 1.0, label: '1', note: 'whole'),
    (value: 0.5, label: '0.5', note: null),
    (value: 0.1, label: '0.1', note: null),
    (value: 0.01, label: '0.01', note: null),
  ];

  @override
  Widget build(BuildContext context) {
    final current = double.tryParse(controller.text.trim());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < _presets.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _IncrementPill(
                  label: _presets[i].label,
                  note: _presets[i].note,
                  active: current != null && current == _presets[i].value,
                  onTap: () {
                    final p = _presets[i];
                    final wasActive = current != null && current == p.value;
                    final next = wasActive ? '' : _fmt(p.value);
                    controller.text = next;
                    onChanged?.call(next);
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        MixMaxTextInput(
          controller: controller,
          placeholder: 'Or type a custom step',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
        ),
      ],
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// One granularity pill — ink fill when [active], else a hairline-ringed
/// surface. An optional [note] (e.g. "whole") trails the label in a quieter tint.
class _IncrementPill extends StatelessWidget {
  final String label;
  final String? note;
  final bool active;
  final VoidCallback onTap;

  const _IncrementPill({
    required this.label,
    required this.note,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      height: 42,
      decoration: BoxDecoration(
        color: active ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? AppColors.ink : AppColors.hairline,
          width: 1.5,
        ),
      ),
      child: MixMaxInk(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          // Cells share the row width evenly; scale down if a label (e.g.
          // "1 whole") would be too wide on a narrow screen rather than overflow.
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppFonts.sans,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1,
                      color: active ? Colors.white : AppColors.ink,
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      note!,
                      style: TextStyle(
                        fontFamily: AppFonts.sans,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        height: 1,
                        color: active ? Colors.white70 : AppColors.inkFaint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
