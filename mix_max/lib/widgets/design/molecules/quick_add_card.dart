import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/label_text.dart';

/// One preset card in a drawer's "Quick add" row — a tinted glyph [MixMaxTile]
/// over a title and a faint hint. Tapping it seeds the form with a preset.
///
/// Source: `drawers.jsx` `PresetRow` card. A fixed 116px-wide surface card with
/// a hairline ring and a whisper of elevation, meant to be laid out in a
/// horizontally scrolling row by the host drawer. Reused by both the parameter
/// and outcome drawers, hence the configurable [tone].
class MixMaxQuickAddCard extends StatelessWidget {
  final MixMaxGlyph icon;

  /// Bold title (e.g. "Temperature").
  final String title;

  /// Faint sub-hint (e.g. "°F", "minutes").
  final String hint;

  /// Tile tint — sage for parameters, violet for outcomes.
  final MixMaxTileTone tone;

  final VoidCallback? onTap;

  /// Card width. The design fixes this at 116 so the row scrolls predictably.
  final double width;

  const MixMaxQuickAddCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.hint,
    this.tone = MixMaxTileTone.sage,
    this.onTap,
    this.width = 116,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.hairline, width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x08221F2A), offset: Offset(0, 1), blurRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MixMaxTile(glyph: icon, tone: tone, size: 34, radius: 10),
          const SizedBox(height: 9),
          LabelText(
            text: title,
            fontSize: 13.5,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          CaptionText(
            text: hint,
            fontSize: 11.5,
            color: AppColors.inkFaint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: card),
    );
  }
}
