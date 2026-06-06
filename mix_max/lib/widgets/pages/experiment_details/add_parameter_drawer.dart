import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/drawer_container.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/inputs/text_input.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/eyebrow_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';
import 'package:mix_max/widgets/design/molecules/multi_option_adder.dart';
import 'package:mix_max/widgets/design/molecules/param_type_picker.dart';
import 'package:mix_max/widgets/design/molecules/quick_add_card.dart';
import 'package:mix_max/widgets/pages/experiment_details/toggle_field.dart';

/// The "Add a parameter" bottom drawer.
///
/// Source: `design_app/drawers.jsx` `AddParameterDrawer` (+ `DrawerShell`).
/// Composed entirely from the design system: the [MixMaxDrawerContainer] shell,
/// a centered serif header, a "Quick add" row of [MixMaxQuickAddCard] presets, a
/// name [MixMaxTextInput], the [MixMaxParamTypePicker] value-kind selector, and a
/// progressively-disclosed body that swaps to match the chosen type — unit &
/// range fields, the [ToggleField], or a [MixMaxMultiOptionAdder] for choice
/// options / order steps. A pinned ink "Save parameter" footer stays disabled
/// until the form is valid.
///
/// Present it with `showModalBottomSheet(backgroundColor: transparent,
/// isScrollControlled: true)`. Nothing is persisted here — [onSave] fires with a
/// freshly-id'd [SchemaParameter] and the sheet pops; the caller does the write.
class AddParameterDrawer extends StatefulWidget {
  static const int maxNameLength = 50;

  /// Called with the assembled parameter when the user saves.
  final ValueChanged<SchemaParameter> onSave;

  const AddParameterDrawer({super.key, required this.onSave});

  @override
  State<AddParameterDrawer> createState() => _AddParameterDrawerState();
}

class _AddParameterDrawerState extends State<AddParameterDrawer> {
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  ParameterType _type = ParameterType.number;
  List<String> _options = [];
  List<String> _items = [];

  // The toggle's default state. There's no schema field for it yet, so it
  // drives only the live preview in the [ToggleField] and isn't persisted.
  bool _toggleOn = true;

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
    super.dispose();
  }

  void _onChanged() => setState(() {});

  /// number / duration carry a unit and an optional min/max range.
  bool get _isRanged =>
      _type == ParameterType.number || _type == ParameterType.duration;

  bool get _canSave {
    if (_nameController.text.trim().isEmpty) return false;
    if (_type == ParameterType.choice && _options.isEmpty) return false;
    // An order of one step has nothing to sequence.
    if (_type == ParameterType.order && _items.length < 2) return false;
    return true;
  }

  void _selectType(ParameterType type) => setState(() => _type = type);

  void _applyPreset(_ParamPreset preset) {
    setState(() {
      _type = preset.type;
      _nameController.text = preset.name;
      _unitController.text = preset.unit ?? '';
      _minController.text = preset.min?.toString() ?? '';
      _maxController.text = preset.max?.toString() ?? '';
    });
  }

  void _save() {
    if (!_canSave) return;
    final name = _nameController.text.trim();
    final unit = _unitController.text.trim();

    final parameter = SchemaParameter(
      id: DatabaseService.experimentsRef.doc().id,
      name: name,
      type: _type,
      unit: _isRanged && unit.isNotEmpty ? unit : null,
      min: _isRanged ? double.tryParse(_minController.text.trim()) : null,
      max: _isRanged ? double.tryParse(_maxController.text.trim()) : null,
      options: _type == ParameterType.choice ? List.of(_options) : null,
      items: _type == ParameterType.order ? List.of(_items) : null,
    );

    widget.onSave(parameter);
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
            text: 'Add a parameter',
            fontSize: 25,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3),
          CaptionText(
            text: 'A knob Mix Max will learn to tune',
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
              placeholder: 'e.g. Ounces of water',
              maxLength: AddParameterDrawer.maxNameLength,
              keyboardType: TextInputType.text,
            ),
          ),

          _subHead('What kind of value?'),
          _hpad(MixMaxParamTypePicker(value: _type, onChanged: _selectType)),
          _hpad(
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CaptionText(
                text: MixMaxParamTypePicker.metaFor(_type).blurb,
                fontSize: 12.5,
                color: AppColors.inkFaint,
              ),
            ),
          ),

          ..._disclosure(),
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
              onTap: () => _applyPreset(_presets[i]),
            ),
          ],
        ],
      ),
    );
  }

  // The type-specific tail of the form.
  List<Widget> _disclosure() {
    switch (_type) {
      case ParameterType.number:
      case ParameterType.duration:
        return [
          _subHead('Unit & range'),
          _hpad(
            MixMaxTextInput(
              controller: _unitController,
              placeholder: 'Unit — e.g. g, °F, ml',
              keyboardType: TextInputType.text,
            ),
          ),
          const SizedBox(height: 10),
          _hpad(
            Row(
              children: [
                Expanded(child: _numberField(_minController, 'Min')),
                const SizedBox(width: 10),
                Expanded(child: _numberField(_maxController, 'Max')),
              ],
            ),
          ),
        ];

      case ParameterType.toggle:
        return [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: ToggleField(
              value: _toggleOn,
              onChanged: (v) => setState(() => _toggleOn = v),
            ),
          ),
        ];

      case ParameterType.choice:
        return [
          _subHead('Options'),
          _hpad(
            MixMaxMultiOptionAdder(
              items: _options,
              placeholder: 'Add an option',
              onChanged: (next) => setState(() => _options = next),
            ),
          ),
        ];

      case ParameterType.order:
        return [
          _subHead('Steps to sequence'),
          _hpad(
            MixMaxMultiOptionAdder(
              items: _items,
              placeholder: 'Add a step',
              onChanged: (next) => setState(() => _items = next),
            ),
          ),
        ];
    }
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

  // Pinned ink "Save parameter" action. DrawerShell footer padding '10px 24px 26px'.
  Widget _footer() {
    final enabled = _canSave;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 26),
      child: MixMaxButton(
        label: 'Save parameter',
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
  // The body scroll view is unpadded so the preset row can bleed to the edges;
  // every other section restates the design's 24px horizontal gutter.
  Widget _hpad(Widget child) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: child);

  // SubHead — a faint eyebrow with the design's '18px 0 9px' margins.
  Widget _subHead(String text, {double topGap = 18}) => Padding(
        padding: EdgeInsets.fromLTRB(24, topGap, 24, 9),
        child: EyebrowText(text: text, color: AppColors.inkFaint),
      );
}

/// A "Quick add" preset — the card metadata plus the values it seeds.
///
/// Mirrors `drawers.jsx` `PARAM_PRESETS`. Temperature defaults to Fahrenheit
/// (32–212 °F, the freezing/boiling range) rather than the design's Celsius.
class _ParamPreset {
  final String title;
  final String hint;
  final MixMaxGlyph glyph;

  // Seeded form values.
  final String name;
  final ParameterType type;
  final String? unit;
  final num? min;
  final num? max;

  const _ParamPreset({
    required this.title,
    required this.hint,
    required this.glyph,
    required this.name,
    required this.type,
    this.unit,
    this.min,
    this.max,
  });
}

const List<_ParamPreset> _presets = [
  _ParamPreset(
    title: 'Amount',
    hint: 'grams',
    glyph: MixMaxGlyph.bag,
    name: 'Amount',
    type: ParameterType.number,
    unit: 'g',
    min: 0,
    max: 100,
  ),
  _ParamPreset(
    title: 'Time',
    hint: 'minutes',
    glyph: MixMaxGlyph.timer,
    name: 'Time',
    type: ParameterType.duration,
    unit: 'minutes',
    min: 1,
    max: 10,
  ),
  _ParamPreset(
    title: 'Temperature',
    hint: '°F',
    glyph: MixMaxGlyph.ruler,
    name: 'Temperature',
    type: ParameterType.number,
    unit: '°F',
    min: 32,
    max: 212,
  ),
];
