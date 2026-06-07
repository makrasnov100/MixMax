import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/chip.dart';
import 'package:mix_max/widgets/design/atoms/drawer_container.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';

/// The destructive "Delete experiment?" confirm drawer for Experiment Details.
///
/// Source: `design_app/drawers.jsx` `ConfirmDeleteDrawer` (+ `DrawerShell`): a
/// centered serif title naming the experiment (italic, quoted), a danger [
/// MixMaxTile] alert glyph, a warning blurb, and a row of soft chips spelling
/// out everything that will be lost — its parameters, outcomes and runs. The
/// pinned footer carries the danger "Delete experiment" commit and a ghost
/// "Keep it" cancel.
///
/// Present it with `showModalBottomSheet(backgroundColor: transparent,
/// isScrollControlled: true)`. Nothing is deleted here — [onConfirm] fires and
/// the sheet pops; the caller does the destructive write and navigation.
class ConfirmDeleteExperimentDrawer extends StatelessWidget {
  final String? experimentName;
  final int parameterCount;
  final int outcomeCount;
  final int runCount;

  /// Fired when the user commits to deleting. The sheet pops first.
  final VoidCallback onConfirm;

  const ConfirmDeleteExperimentDrawer({
    super.key,
    required this.experimentName,
    required this.parameterCount,
    required this.outcomeCount,
    required this.runCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final name = experimentName?.isNotEmpty == true
        ? experimentName!
        : 'Untitled experiment';

    final bits = [
      '$parameterCount parameter${parameterCount == 1 ? '' : 's'}',
      '$outcomeCount outcome${outcomeCount == 1 ? '' : 's'}',
      '$runCount run${runCount == 1 ? '' : 's'}',
    ];

    return MixMaxDrawerContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered serif title with the italic, quoted experiment name.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
            child: Text.rich(
              TextSpan(
                style: TitleText.styleOf(fontSize: 25),
                children: [
                  const TextSpan(text: 'Delete '),
                  TextSpan(
                    text: '“$name”',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Body: alert tile, warning, and the "what you'll lose" chips.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                children: [
                  const MixMaxTile(
                    glyph: MixMaxGlyph.alert,
                    tone: MixMaxTileTone.danger,
                    size: 56,
                    radius: 18,
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: const BodyText(
                      text: 'This permanently removes the experiment and '
                          'everything in it. This can’t be undone.',
                      fontSize: 14.5,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final bit in bits)
                        MixMaxChip(label: bit, tone: MixMaxChipTone.soft),
                    ],
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
                  label: 'Delete experiment',
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
