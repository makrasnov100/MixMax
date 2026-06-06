import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/chip.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/inputs/text_input.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';

/// A repeated text-entry field that builds a list of short strings — the
/// "options" editor for a `choice` parameter and the "steps" editor for an
/// `order` parameter.
///
/// Source: `drawers.jsx` `ChipEditor`. The committed [items] render above as
/// removable soft [MixMaxChip]s; below sits a [MixMaxTextInput] paired with a
/// square ink add button. Submitting the field (or tapping +) commits the
/// trimmed draft and clears it. Controlled — every mutation reports the new list
/// through [onChanged]; this widget owns only the in-progress draft.
class MixMaxMultiOptionAdder extends StatefulWidget {
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final String? placeholder;

  const MixMaxMultiOptionAdder({
    Key? key,
    required this.items,
    required this.onChanged,
    this.placeholder,
  }) : super(key: key);

  @override
  State<MixMaxMultiOptionAdder> createState() => _MixMaxMultiOptionAdderState();
}

class _MixMaxMultiOptionAdderState extends State<MixMaxMultiOptionAdder> {
  final TextEditingController _draft = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _draft.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    final value = _draft.text.trim();
    if (value.isEmpty) return;
    widget.onChanged([...widget.items, value]);
    _draft.clear();
    // Keep the field hot so several entries can be typed in a row.
    _focus.requestFocus();
  }

  void _removeAt(int index) {
    final next = [...widget.items]..removeAt(index);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.items.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < widget.items.length; i++)
                MixMaxChip(
                  label: widget.items[i],
                  tone: MixMaxChipTone.soft,
                  onClose: () => _removeAt(i),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: MixMaxTextInput(
                controller: _draft,
                focusNode: _focus,
                placeholder: widget.placeholder,
                keyboardType: TextInputType.text,
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            _AddButton(onTap: _add),
          ],
        ),
      ],
    );
  }
}

/// The square ink "+" affordance beside the draft field. Sized to the 50px
/// [MixMaxTextInput] it sits next to, at the field radius.
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const MixMaxIcon(MixMaxGlyph.plus, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
