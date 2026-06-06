import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/drawer_container.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/inputs/text_input.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';

/// The "Rename experiment" bottom drawer for the Experiment Details page.
///
/// Source: `design_app/drawers.jsx` `NameDrawer` (+ `DrawerShell`), trimmed for
/// renaming: a [MixMaxDrawerContainer] surface, a centered serif title / soft
/// subtitle, a big [MixMaxTextInput] (seeded with the current name) and its
/// character counter, and a pinned ink "Save" footer disabled until a non-empty
/// name is entered. The "Need inspiration" presets from the create flow are
/// dropped — when renaming you already have a name to start from.
///
/// Present it with `showModalBottomSheet(backgroundColor: transparent,
/// isScrollControlled: true)`. Nothing is persisted here — [onSave] fires with
/// the trimmed name and the sheet pops; the caller does the write.
class RenameExperimentDrawer extends StatefulWidget {
  static const int maxNameLength = 50;

  /// Seeds the field with the experiment's current name.
  final String? initialName;
  final String title;
  final String subtitle;

  /// Called with the trimmed name when the user saves.
  final ValueChanged<String> onSave;

  const RenameExperimentDrawer({
    super.key,
    required this.onSave,
    this.initialName,
    this.title = 'Rename experiment',
    this.subtitle = 'What are you trying to perfect?',
  });

  @override
  State<RenameExperimentDrawer> createState() => _RenameExperimentDrawerState();
}

class _RenameExperimentDrawerState extends State<RenameExperimentDrawer> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '')
      ..addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canSave => _controller.text.trim().isNotEmpty;

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    widget.onSave(name);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Lift the sheet above the keyboard the focused field raises.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: MixMaxDrawerContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            Flexible(child: _body()),
            _footer(),
          ],
        ),
      ),
    );
  }

  // Centered serif title + soft subtitle. DrawerShell padding '14px 24px 4px'.
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
      child: Column(
        children: [
          TitleText(
            text: widget.title,
            fontSize: 25,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          CaptionText(
            text: widget.subtitle,
            fontSize: 13.5,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _body() {
    final length = _controller.text.characters.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MixMaxTextInput(
            controller: _controller,
            placeholder: 'Experiment name',
            maxLength: RenameExperimentDrawer.maxNameLength,
            autofocus: true,
            big: true,
            keyboardType: TextInputType.text,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: CaptionText(
              text: '$length/${RenameExperimentDrawer.maxNameLength}',
              fontSize: 12,
              color: AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }

  // Pinned ink "Save" action. DrawerShell footer padding '10px 24px 26px'.
  Widget _footer() {
    final enabled = _canSave;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
      child: MixMaxButton(
        label: 'Save',
        variant: MixMaxButtonVariant.ink,
        enabled: enabled,
        onPressed: _save,
        trailing: MixMaxIcon(
          MixMaxGlyph.check,
          size: 20,
          color: enabled ? Colors.white : AppColors.inkFaint,
        ),
      ),
    );
  }
}
