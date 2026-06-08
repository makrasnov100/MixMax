import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/drawer_container.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';

/// What is being deleted — chooses the copy and the button labels.
enum DeleteItemTarget { parameter, outcome }

/// The destructive "Delete this parameter? / outcome?" confirm drawer.
///
/// Source: `design_app/drawers.jsx` `ConfirmDeleteItemDrawer` (+ `DrawerShell`):
/// a centered serif title, a danger [MixMaxTile] trash glyph, a short warning
/// whose wording depends on whether any runs have been recorded, and a pinned
/// footer with the danger "Delete …" commit over a ghost "Keep it" escape.
///
/// Every past run keeps its own snapshot of the parameters and outcomes, so
/// nothing in the run history is lost when an item is deleted — runs recorded
/// against the old set simply stop tuning future runs.
///
/// Present it with `showModalBottomSheet(backgroundColor: transparent,
/// isScrollControlled: true)`. Nothing is deleted here — [onConfirm] fires and
/// the sheet pops; the caller does the destructive write. [onClose] is called
/// when the user keeps the item (the design returns them to its edit drawer).
class ConfirmDeleteItemDrawer extends StatelessWidget {
  final DeleteItemTarget target;

  /// Number of recorded runs on the experiment — switches the warning copy.
  final int runCount;

  /// Fired when the user commits to deleting. The sheet pops first.
  final VoidCallback onConfirm;

  /// Fired when the user backs out via "Keep it". The sheet pops first.
  final VoidCallback? onClose;

  const ConfirmDeleteItemDrawer({
    super.key,
    required this.target,
    required this.runCount,
    required this.onConfirm,
    this.onClose,
  });

  String get _noun => target == DeleteItemTarget.parameter ? 'parameter' : 'outcome';

  @override
  Widget build(BuildContext context) {
    final hasRuns = runCount > 0;

    return MixMaxDrawerContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
            child: TitleText(
              text: 'Delete this $_noun?',
              fontSize: 25,
              textAlign: TextAlign.center,
            ),
          ),

          // Body: trash tile + a warning whose wording depends on run history.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                children: [
                  const MixMaxTile(
                    glyph: MixMaxGlyph.trash,
                    tone: MixMaxTileTone.danger,
                    size: 56,
                    radius: 18,
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 312),
                    child: BodyText(
                      text: hasRuns
                          ? 'Nothing in your run history will change, but some '
                              'or all past runs may stop being used to tune your '
                              'next run.'
                          : 'This $_noun will be removed from the experiment. '
                              'There are no recorded runs, so nothing else is '
                              'affected.',
                      fontSize: 14.5,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pinned destructive footer: delete commit + ghost cancel.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MixMaxButton(
                  label: 'Delete $_noun',
                  variant: MixMaxButtonVariant.danger,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  leading: const MixMaxIcon(
                    MixMaxGlyph.trash,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                MixMaxButton(
                  label: 'Keep it',
                  variant: MixMaxButtonVariant.ghost,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClose?.call();
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
