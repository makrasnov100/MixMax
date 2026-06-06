import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';

/// A small illustrative on/off switch graphic.
///
/// Source: `ui.jsx` `MiniSwitch`. Purely decorative — it pictures a toggle's
/// state next to a label, it is not an interactive control. A sage track when
/// [on], a faint track when off, with a white knob shoved to the matching side.
class MiniSwitch extends StatelessWidget {
  /// Whether the knob sits on the right (on) or left (off).
  final bool on;

  const MiniSwitch({Key? key, this.on = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 40,
      height: 24,
      padding: const EdgeInsets.all(3),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on ? AppColors.sage : AppColors.hairlineStrong,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x33000000), offset: Offset(0, 1), blurRadius: 2),
          ],
        ),
      ),
    );
  }
}
