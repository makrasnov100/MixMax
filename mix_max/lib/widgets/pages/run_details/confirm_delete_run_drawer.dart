import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/chip.dart';
import 'package:mix_max/widgets/design/atoms/drawer_container.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/format.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';

/// The destructive "Delete Run N?" confirm drawer for the Run Details page.
///
/// Source: `design_app/drawers.jsx` `ConfirmDeleteRunDrawer` (+ `DrawerShell`):
/// a centered serif title naming the run (italic), a danger [MixMaxTile] trash
/// glyph, a warning blurb — which gains an extra line when the run being deleted
/// is the experiment's current best — and a row of soft chips recapping the
/// run's recorded outcomes. The pinned footer carries the danger "Delete run"
/// commit and a ghost "Keep it" cancel.
///
/// Present it with `showModalBottomSheet(backgroundColor: transparent,
/// isScrollControlled: true)`. Nothing is deleted here — [onConfirm] fires and
/// the sheet pops; the caller does the destructive write and navigation.
class ConfirmDeleteRunDrawer extends StatelessWidget {
  final SchemaExperiment experiment;
  final SchemaRun run;

  /// Whether this run is the experiment's current best — switches the warning
  /// to explain the next-best run will be crowned.
  final bool isBest;

  /// Fired when the user commits to deleting. The sheet pops first.
  final VoidCallback onConfirm;

  const ConfirmDeleteRunDrawer({
    super.key,
    required this.experiment,
    required this.run,
    required this.isBest,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    // Recap the run's recorded outcomes from its own snapshot (falling back to
    // the experiment's current outcomes for legacy runs without one).
    final outcomes = run.outcomes ?? experiment.outcomes ?? const [];
    final values = run.outcomeValues ?? const <String, double>{};
    final bits = <String>[
      for (final o in outcomes)
        if (values[o.id] != null)
          '${o.name ?? 'Outcome'} ${MixMaxFormat.number(values[o.id])}'
              '${o.unit?.isNotEmpty == true ? ' ${o.unit}' : ''}',
    ];

    const label = 'this run';
    final blurb = isBest
        ? 'This run is your current best. Deleting it removes it for good, and '
            'Mix Max will crown the next-highest run as best. This can’t be '
            'undone.'
        : 'This permanently removes this run from your history. This can’t be '
            'undone.';

    return MixMaxDrawerContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered serif title with the italic run label.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
            child: Text.rich(
              TextSpan(
                style: TitleText.styleOf(fontSize: 25),
                children: const [
                  TextSpan(text: 'Delete '),
                  TextSpan(
                    text: label,
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  TextSpan(text: '?'),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Body: trash tile, warning, and the outcome recap chips.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
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
                      text: blurb,
                      fontSize: 14.5,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (bits.isNotEmpty) ...[
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
                  label: 'Delete run',
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
