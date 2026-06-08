import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/drawer_container.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/inputs/text_input.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/eyebrow_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';
import 'package:mix_max/widgets/design/molecules/quick_add_card.dart';
import 'package:mix_max/widgets/design/molecules/segmented.dart';

/// The "Add an outcome" bottom drawer.
///
/// Source: `design_app/drawers.jsx` `AddOutputDrawer` (+ `DrawerShell`).
/// Composed from the design system: the [MixMaxDrawerContainer] shell, a centered
/// serif header, a violet "Quick add" row of [MixMaxQuickAddCard] presets, a name
/// [MixMaxTextInput], a [MixMaxSegmented] goal selector (Minimize / Maximize), a
/// two-column min/max scale, a unit + increment row, and a pinned ink "Save outcome"
/// footer that stays disabled until a name is entered.
///
/// Present it with `showModalBottomSheet(backgroundColor: transparent,
/// isScrollControlled: true)`. Nothing is persisted here — [onSave] fires with a
/// freshly-id'd [SchemaOutcome] and the sheet pops; the caller does the write.
class AddOutputDrawer extends StatefulWidget {
  static const int maxNameLength = 50;

  /// Called with the assembled outcome when the user saves.
  final ValueChanged<SchemaOutcome> onSave;

  const AddOutputDrawer({super.key, required this.onSave});

  @override
  State<AddOutputDrawer> createState() => _AddOutputDrawerState();
}

class _AddOutputDrawerState extends State<AddOutputDrawer> {
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  // Seed the scale with the design's defaults (a 1–10, increment-1 scale).
  final _minController = TextEditingController(text: '1');
  final _maxController = TextEditingController(text: '10');
  final _incrementController = TextEditingController(text: '1');

  OutcomeGoal _goal = OutcomeGoal.maximize;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onChanged)
      ..dispose();
    _unitController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _incrementController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  void _applyPreset(_OutcomePreset preset) {
    setState(() {
      // Seed the name from the cased title so quick adds keep their casing.
      _nameController.text = preset.title;
      _unitController.text = preset.unit ?? '';
      _goal = preset.goal;
      _minController.text = preset.min.toString();
      _maxController.text = preset.max.toString();
      _incrementController.text = preset.increment.toString();
    });
  }

  void _save() {
    if (!_canSave) return;
    final unit = _unitController.text.trim();
    final increment = double.tryParse(_incrementController.text.trim());

    final outcome = SchemaOutcome(
      id: DatabaseService.experimentsRef.doc().id,
      name: _nameController.text.trim(),
      unit: unit.isEmpty ? null : unit,
      min: double.tryParse(_minController.text.trim()),
      max: double.tryParse(_maxController.text.trim()),
      // Default to an increment of 1 when blank or non-positive.
      step: (increment != null && increment > 0) ? increment : 1.0,
      goal: _goal,
    );

    widget.onSave(outcome);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 14, 24, 4),
      child: Column(
        children: [
          TitleText(
            text: 'Add an outcome',
            fontSize: 25,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3),
          CaptionText(
            text: "What you'll measure after each run",
            fontSize: 13.5,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _subHead('Quick add', topGap: 12),
          _quickAddRow(),

          _subHead('Name'),
          _hpad(
            MixMaxTextInput(
              controller: _nameController,
              placeholder: 'e.g. taste',
              maxLength: AddOutputDrawer.maxNameLength,
              keyboardType: TextInputType.text,
            ),
          ),

          _subHead('Goal'),
          _hpad(
            MixMaxSegmented<OutcomeGoal>(
              value: _goal,
              onChanged: (g) => setState(() => _goal = g),
              options: const [
                MixMaxSegment(
                  value: OutcomeGoal.minimize,
                  label: 'Minimize',
                  icon: MixMaxGlyph.down,
                ),
                MixMaxSegment(
                  value: OutcomeGoal.maximize,
                  label: 'Maximize',
                  icon: MixMaxGlyph.up,
                ),
              ],
            ),
          ),

          _subHead('Scale'),
          _hpad(
            Row(
              children: [
                Expanded(child: _numberField(_minController, 'Min')),
                const SizedBox(width: 10),
                Expanded(child: _numberField(_maxController, 'Max')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _hpad(
            Row(
              children: [
                Expanded(
                  child: MixMaxTextInput(
                    controller: _unitController,
                    placeholder: 'Unit (optional)',
                    keyboardType: TextInputType.text,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _numberField(_incrementController, 'Increment')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The horizontally-scrolling preset row. Full-bleed (its own 24px content
  // padding) so cards scroll under the drawer edges.
  Widget _quickAddRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
      child: Row(
        children: [
          for (var i = 0; i < _presets.length; i++) ...[
            if (i > 0) const SizedBox(width: 9),
            MixMaxQuickAddCard(
              icon: _presets[i].glyph,
              title: _presets[i].title,
              hint: _presets[i].hint,
              tone: MixMaxTileTone.violet,
              onTap: () => _applyPreset(_presets[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String placeholder) {
    return MixMaxTextInput(
      controller: controller,
      placeholder: placeholder,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
    );
  }

  // Pinned ink "Save outcome" action. DrawerShell footer padding '10px 24px 26px'.
  Widget _footer() {
    final enabled = _canSave;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
      child: MixMaxButton(
        label: 'Save outcome',
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

  // ── Layout helpers ───────────────────────────────────────────────────────
  Widget _hpad(Widget child) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: child);

  Widget _subHead(String text, {double topGap = 18}) => Padding(
        padding: EdgeInsets.fromLTRB(24, topGap, 24, 9),
        child: EyebrowText(text: text, color: AppColors.inkFaint),
      );
}

/// A "Quick add" preset — the card metadata plus the values it seeds.
/// Mirrors `drawers.jsx` `OUTPUT_PRESETS`.
class _OutcomePreset {
  final String title;
  final String hint;
  final MixMaxGlyph glyph;

  // Seeded form values.
  final String? unit;
  final num min;
  final num max;
  final num increment;
  final OutcomeGoal goal;

  const _OutcomePreset({
    required this.title,
    required this.hint,
    required this.glyph,
    this.unit,
    required this.min,
    required this.max,
    required this.increment,
    required this.goal,
  });
}

const List<_OutcomePreset> _presets = [
  _OutcomePreset(
    title: 'Taste',
    hint: '1–10, higher',
    glyph: MixMaxGlyph.spark2,
    min: 1,
    max: 10,
    increment: 1,
    goal: OutcomeGoal.maximize,
  ),
  _OutcomePreset(
    title: 'Quality',
    hint: '1–5, higher',
    glyph: MixMaxGlyph.trophy,
    min: 1,
    max: 5,
    increment: 1,
    goal: OutcomeGoal.maximize,
  ),
  _OutcomePreset(
    title: 'Yield',
    hint: '%, higher',
    glyph: MixMaxGlyph.up,
    unit: '%',
    min: 0,
    max: 100,
    increment: 1,
    goal: OutcomeGoal.maximize,
  ),
  _OutcomePreset(
    title: 'Time',
    hint: 'min, lower',
    glyph: MixMaxGlyph.clock,
    unit: 'min',
    min: 0,
    max: 60,
    increment: 1,
    goal: OutcomeGoal.minimize,
  ),
];
