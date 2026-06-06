import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';

/// An interactive on/off switch — the input counterpart to the decorative
/// [MiniSwitch].
///
/// Source: `ui.jsx` `MiniSwitch`, promoted to a real control. The knob slides
/// left → right as [value] flips; the track warms to [AppColors.sage] when on
/// and falls back to a faint hairline when off. Controlled — it holds no state
/// of its own, it paints [value] and reports taps through [onChanged].
///
/// Sized at a comfortable 52×32 tap target (the mini graphic is 40×24); the
/// whole control is tappable, not just the knob.
class MixMaxToggleInput extends StatelessWidget {
  /// Whether the knob sits on the right (on) or left (off).
  final bool value;

  /// Fires with the toggled value. Null renders a non-interactive switch.
  final ValueChanged<bool>? onChanged;

  const MixMaxToggleInput({
    Key? key,
    required this.value,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final track = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 52,
      height: 32,
      padding: const EdgeInsets.all(3),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: value ? AppColors.sage : AppColors.hairlineStrong,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x33000000), offset: Offset(0, 1), blurRadius: 2),
          ],
        ),
      ),
    );

    if (onChanged == null) return track;
    return GestureDetector(
      onTap: () => onChanged!(!value),
      child: MouseRegion(cursor: SystemMouseCursors.click, child: track),
    );
  }
}
