import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/drawer_container.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';
import 'package:mix_max/widgets/design/molecules/action_row.dart';

/// The "Manage this experiment" actions drawer for the Experiment Details page.
///
/// Source: `design_app/drawers.jsx` `ExperimentActionsDrawer` (+ `DrawerShell`):
/// a [MixMaxDrawerContainer] surface with a centered serif title (the
/// experiment name) and soft subtitle, then a stack of [MixMaxActionRow]s — an
/// optional gold "Share best run" (shown when [canShareBest]), "Rename
/// experiment" and the danger-toned "Delete experiment".
///
/// Present it with `showModalBottomSheet(backgroundColor: transparent,
/// isScrollControlled: true)`. The drawer pops itself before invoking
/// [onShareBest], [onRename] or [onDelete] so the caller can immediately open
/// the follow-up drawer.
class ExperimentActionsDrawer extends StatelessWidget {
  /// The experiment name, shown as the drawer title.
  final String? experimentName;

  /// Whether the experiment has a best run to share. Shows the "Share best run"
  /// row only when a winning run exists (mirrors the design's `hasRuns` check).
  final bool canShareBest;

  /// Opens the share flow for the experiment's best run. Only reachable when
  /// [canShareBest] is true.
  final VoidCallback onShareBest;

  /// Opens the rename flow.
  final VoidCallback onRename;

  /// Opens the destructive confirm-delete flow.
  final VoidCallback onDelete;

  const ExperimentActionsDrawer({
    super.key,
    required this.experimentName,
    this.canShareBest = false,
    required this.onShareBest,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = experimentName?.isNotEmpty == true
        ? experimentName!
        : 'Untitled experiment';

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
                  text: name,
                  fontSize: 25,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                const CaptionText(
                  text: 'Manage this experiment',
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
                if (canShareBest) ...[
                  MixMaxActionRow(
                    glyph: MixMaxGlyph.share,
                    tone: MixMaxTileTone.gold,
                    label: 'Share best run',
                    sublabel: 'Save its mix & ratings as an image',
                    onTap: () {
                      Navigator.of(context).pop();
                      onShareBest();
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                MixMaxActionRow(
                  glyph: MixMaxGlyph.edit,
                  tone: MixMaxTileTone.neutral,
                  label: 'Rename experiment',
                  sublabel: 'Change its title',
                  onTap: () {
                    Navigator.of(context).pop();
                    onRename();
                  },
                ),
                const SizedBox(height: 10),
                MixMaxActionRow(
                  glyph: MixMaxGlyph.trash,
                  tone: MixMaxTileTone.danger,
                  label: 'Delete experiment',
                  sublabel: 'Remove it and all its data',
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
