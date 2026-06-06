import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/card.dart';
import 'package:mix_max/widgets/design/atoms/inputs/toggle_input.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/label_text.dart';

/// The Add-Parameter drawer's "on or off" section — a flat [MixMaxCard] pairing
/// an interactive [MixMaxToggleInput] with a label that reflects its state.
///
/// Source: `drawers.jsx` `AddParameterDrawer` toggle block (the
/// `MiniSwitch + "No range needed…"` box), promoted to a live control. Shown
/// when the parameter type is `toggle`: there's no range to set, so the field
/// just captures the knob's default state. The bold [LabelText] flips between
/// [onLabel] / [offLabel] as [value] changes, with [description] as a quiet
/// second line.
///
/// Lives under `pages/experiment_details/` — it's specific to building an
/// experiment's parameters, not a general design-system molecule.
class ToggleField extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Bold line when on / off.
  final String onLabel;
  final String offLabel;

  /// Faint helper line beneath the state label.
  final String description;

  const ToggleField({
    Key? key,
    required this.value,
    required this.onChanged,
    this.onLabel = 'On',
    this.offLabel = 'Off',
    this.description = "No range needed — it's simply on or off.",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MixMaxCard(
      elevated: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          MixMaxToggleInput(value: value, onChanged: onChanged),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LabelText(text: value ? onLabel : offLabel, fontSize: 15),
                const SizedBox(height: 2),
                CaptionText(
                  text: description,
                  fontSize: 13.5,
                  color: AppColors.inkSoft,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
