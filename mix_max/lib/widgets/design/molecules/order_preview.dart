import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/chip.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';

/// A sequence preview: `a → b → c` as soft chips joined by arrows.
///
/// Source: `ui.jsx` `OrderPreview`. The value visual for an `order` parameter,
/// where the meaning is the ordering itself. Wraps onto multiple lines when the
/// sequence is long.
class OrderPreview extends StatelessWidget {
  final List<String> items;

  const OrderPreview({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(MixMaxChip(label: items[i]));
      if (i < items.length - 1) {
        children.add(const MixMaxIcon(
          MixMaxGlyph.arrowRight,
          size: 13,
          color: AppColors.inkFaint,
        ));
      }
    }

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
