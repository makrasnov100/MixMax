import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/drawer_container.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';
import 'package:mix_max/widgets/design/molecules/action_row.dart';

/// The "Manage this run" actions drawer for the Run Details page.
///
/// Source: `design_app/drawers.jsx` `RunActionsDrawer` (+ `DrawerShell`): a
/// [MixMaxDrawerContainer] surface with a centered serif title ("Run N") and
/// soft subtitle, then the gold "Share run", violet "Rescore run" and danger
/// "Delete run" [MixMaxActionRow]s.
///
/// Present it with `showModalBottomSheet(backgroundColor: transparent,
/// isScrollControlled: true)`. The drawer pops itself before invoking [onShare],
/// [onRescore] or [onDelete] so the caller can immediately open the follow-up
/// flow.
class RunActionsDrawer extends StatelessWidget {
  /// The run's chronological number, shown as the drawer title. Null falls back
  /// to "this run" when the caller doesn't know the position.
  final int? number;

  /// Opens the share flow (renders the run as a shareable image).
  final VoidCallback onShare;

  /// Opens the rescore flow.
  final VoidCallback onRescore;

  /// Opens the destructive confirm-delete flow.
  final VoidCallback onDelete;

  const RunActionsDrawer({
    super.key,
    required this.number,
    required this.onShare,
    required this.onRescore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = number != null ? 'Run $number' : 'This run';

    return MixMaxDrawerContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered serif title + soft subtitle. DrawerShell padding.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
            child: Column(
              children: [
                TitleText(
                  text: title,
                  fontSize: 25,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                const CaptionText(
                  text: 'Manage this run',
                  fontSize: 13.5,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Action rows.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MixMaxActionRow(
                  glyph: MixMaxGlyph.share,
                  tone: MixMaxTileTone.gold,
                  label: 'Share run',
                  sublabel: 'Save its mix & ratings as an image',
                  onTap: () {
                    Navigator.of(context).pop();
                    onShare();
                  },
                ),
                const SizedBox(height: 10),
                MixMaxActionRow(
                  glyph: MixMaxGlyph.target,
                  tone: MixMaxTileTone.violet,
                  label: 'Rescore run',
                  sublabel: 'Adjust the outcome ratings',
                  onTap: () {
                    Navigator.of(context).pop();
                    onRescore();
                  },
                ),
                const SizedBox(height: 10),
                MixMaxActionRow(
                  glyph: MixMaxGlyph.trash,
                  tone: MixMaxTileTone.danger,
                  label: 'Delete run',
                  sublabel: 'Remove it from your history',
                  danger: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
