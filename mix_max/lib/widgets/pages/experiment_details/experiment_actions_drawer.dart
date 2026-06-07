import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/drawer_container.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/label_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';

/// The "Manage this experiment" actions drawer for the Experiment Details page.
///
/// Source: `design_app/drawers.jsx` `ExperimentActionsDrawer` (+ `DrawerShell`):
/// a [MixMaxDrawerContainer] surface with a centered serif title (the
/// experiment name) and soft subtitle, then a stack of [_ActionRow]s — "Rename
/// experiment" and the danger-toned "Delete experiment".
///
/// Present it with `showModalBottomSheet(backgroundColor: transparent,
/// isScrollControlled: true)`. The drawer pops itself before invoking [onRename]
/// or [onDelete] so the caller can immediately open the follow-up drawer.
class ExperimentActionsDrawer extends StatelessWidget {
  /// The experiment name, shown as the drawer title.
  final String? experimentName;

  /// Opens the rename flow.
  final VoidCallback onRename;

  /// Opens the destructive confirm-delete flow.
  final VoidCallback onDelete;

  const ExperimentActionsDrawer({
    super.key,
    required this.experimentName,
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
                _ActionRow(
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
                _ActionRow(
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

/// A single tappable row in the actions drawer: a tinted [MixMaxTile] glyph, a
/// label / sublabel stack, and a trailing chevron.
///
/// Source: `drawers.jsx` `ActionRow`. The `danger` flag reddens the label and
/// chevron for the destructive option.
class _ActionRow extends StatefulWidget {
  final MixMaxGlyph glyph;
  final MixMaxTileTone tone;
  final String label;
  final String sublabel;
  final bool danger;
  final VoidCallback onTap;

  const _ActionRow({
    required this.glyph,
    required this.tone,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.danger = false,
  });

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.danger ? AppColors.danger : AppColors.ink;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.bgAlt : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          child: Row(
            children: [
              MixMaxTile(glyph: widget.glyph, tone: widget.tone, size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabelText(text: widget.label, color: foreground),
                    const SizedBox(height: 2),
                    BodyText(text: widget.sublabel, fontSize: 13),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              MixMaxIcon(
                MixMaxGlyph.chevRight,
                size: 19,
                color: widget.danger ? AppColors.danger : AppColors.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
