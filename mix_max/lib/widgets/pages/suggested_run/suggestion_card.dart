import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/widgets/design/atoms/card.dart';
import 'package:mix_max/widgets/design/atoms/chip.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/inputs/text_input.dart';
import 'package:mix_max/widgets/design/atoms/inputs/toggle_input.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/format.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/display_text.dart';
import 'package:mix_max/widgets/design/molecules/mini_switch.dart';
import 'package:mix_max/widgets/design/molecules/option_preview.dart';
import 'package:mix_max/widgets/design/molecules/order_preview.dart';
import 'package:mix_max/widgets/design/molecules/slider_field.dart';

/// One suggested-parameter card on the Suggested Run page — a sage type tile,
/// the parameter's name, and the concrete value the optimizer picked for this
/// run.
///
/// Source: `design_app/screens.jsx` `SuggestionCard`. A number/duration reads as
/// a serif metric (the card's hero); choice / order / toggle reuse the system's
/// value-preview molecules so a pick looks the same here as on the details page.
///
/// When [onChanged] is supplied the card becomes interactive, but it stays
/// collapsed to the compact read-only row until the user taps it. Tapping calls
/// [onStartEdit]; the parent then rebuilds the card with [editing] true, which
/// swaps in the right control for the parameter's type (a bounded slider, an
/// options picker, a reorder list, or a switch) plus a "Done" affordance that
/// fires [onDone] to collapse it again — always within the parameter's own spec.
/// Left null the card is purely read-only and inert, as on the run-details
/// screen.
class SuggestionCard extends StatefulWidget {
  final SchemaParameter parameter;
  final dynamic value;

  /// Reports the user's adjusted value. Null keeps the card purely read-only
  /// (no tap-to-edit, as on the run-details screen).
  final ValueChanged<dynamic>? onChanged;

  /// Whether this card is currently expanded into its editor. Only meaningful
  /// when [onChanged] is non-null.
  final bool editing;

  /// Whether the user has frozen this value (committed an edit that differs
  /// from the optimizer's pick). A frozen card reads subtly different — a gold
  /// edge and a small gold lock — so the held values stand out in "Try these"
  /// without shouting.
  final bool frozen;

  /// Tapped on the collapsed card to begin editing it.
  final VoidCallback? onStartEdit;

  /// Tapped on the "Done" control to collapse the editor back to the row.
  final VoidCallback? onDone;

  const SuggestionCard({
    Key? key,
    required this.parameter,
    required this.value,
    this.onChanged,
    this.editing = false,
    this.frozen = false,
    this.onStartEdit,
    this.onDone,
  }) : super(key: key);

  @override
  State<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<SuggestionCard> {
  /// The scale a temperature value is *read* in here. It starts at the
  /// parameter's stored scale and the reader can flip it (°C / °F / K) without
  /// changing what's saved — purely a lens on the suggested-run screen. Ignored
  /// for every other parameter type.
  late TemperatureUnit _displayUnit;

  @override
  void initState() {
    super.initState();
    _displayUnit = widget.parameter.temperatureUnit;
  }

  @override
  void didUpdateWidget(covariant SuggestionCard old) {
    super.didUpdateWidget(old);
    // A different parameter (or a re-saved scale) reseeds the lens.
    if (old.parameter.temperatureUnit != widget.parameter.temperatureUnit) {
      _displayUnit = widget.parameter.temperatureUnit;
    }
  }

  /// Offered only on the interactive (suggested-run) card and only for a
  /// temperature parameter; null everywhere else suppresses the unit switcher.
  ValueChanged<TemperatureUnit>? get _onDisplayUnitChanged {
    if (widget.onChanged == null) return null;
    if (widget.parameter.type != ParameterType.temperature) return null;
    return (u) => setState(() => _displayUnit = u);
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = widget.onChanged;
    const padding = EdgeInsets.symmetric(horizontal: 18, vertical: 16);

    // A frozen value's quiet tell: the hairline warms to gold.
    final borderColor = widget.frozen ? AppColors.gold : null;

    // Purely read-only (run details): no tap target.
    if (onChanged == null) {
      return MixMaxCard(padding: padding, child: _readOnly());
    }

    // Adjustable but collapsed: the whole card is a tap target that opens the
    // editor, with a quiet pencil hint at the trailing edge.
    if (!widget.editing) {
      return MixMaxCard(
        padding: padding,
        borderColor: borderColor,
        onTap: widget.onStartEdit,
        child: _readOnly(showEditHint: true),
      );
    }

    // Expanded into its editor.
    return MixMaxCard(
      padding: padding,
      borderColor: borderColor,
      child: _editable(onChanged),
    );
  }

  /// The compact display row used on the run-details screen and as the collapsed
  /// state on the suggested-run screen: tile, name, and the value preview, side
  /// by side. [showEditHint] adds a trailing pencil glyph to signal the row is
  /// tappable.
  Widget _readOnly({bool showEditHint = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MixMaxTile(
          glyph: _glyphForType(widget.parameter.type),
          tone: MixMaxTileTone.sage,
          size: 46,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _name(),
              const SizedBox(height: 4),
              _SuggestedValue(
                parameter: widget.parameter,
                value: widget.value,
                displayUnit: _displayUnit,
                onDisplayUnitChanged: _onDisplayUnitChanged,
              ),
            ],
          ),
        ),
        if (widget.frozen) ...[
          const SizedBox(width: 12),
          const MixMaxIcon(MixMaxGlyph.lock, size: 15, color: AppColors.gold),
        ],
        if (showEditHint) ...[
          const SizedBox(width: 12),
          const MixMaxIcon(
            MixMaxGlyph.edit,
            size: 18,
            color: AppColors.inkFaint,
          ),
        ],
      ],
    );
  }

  /// The interactive layout: the tile + name header (with a "Done" control to
  /// collapse) sits above a full-width editor for the parameter's type.
  Widget _editable(ValueChanged<dynamic> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MixMaxTile(
              glyph: _glyphForType(widget.parameter.type),
              tone: MixMaxTileTone.sage,
              size: 46,
            ),
            const SizedBox(width: 15),
            Expanded(child: _name()),
            if (widget.onDone != null) ...[
              const SizedBox(width: 12),
              _DoneButton(onTap: widget.onDone!),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _SuggestedEditor(
          parameter: widget.parameter,
          value: widget.value,
          onChanged: onChanged,
          displayUnit: _displayUnit,
          onDisplayUnitChanged: _onDisplayUnitChanged,
        ),
      ],
    );
  }

  Widget _name() => CaptionText(
    text:
        widget.parameter.name?.isNotEmpty == true
            ? widget.parameter.name
            : 'Untitled parameter',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// The small sage "Done" pill in an expanded card's header — a check glyph and
/// label that collapse the card back to its compact row.
class _DoneButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DoneButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.sage,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MixMaxIcon(MixMaxGlyph.check, size: 15, color: Colors.white),
              SizedBox(width: 5),
              CaptionText(text: 'Done', fontSize: 13, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// The per-type value visual for a suggested parameter (source: `screens.jsx`
/// `fmtSuggested`, lifted into the system's preview molecules).
class _SuggestedValue extends StatelessWidget {
  final SchemaParameter parameter;
  final dynamic value;

  /// The scale a temperature is shown in. Ignored for other types.
  final TemperatureUnit displayUnit;

  /// When non-null, a °C / °F / K switcher is shown beneath a temperature value.
  final ValueChanged<TemperatureUnit>? onDisplayUnitChanged;

  const _SuggestedValue({
    required this.parameter,
    required this.value,
    required this.displayUnit,
    this.onDisplayUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (parameter.type) {
      case ParameterType.number:
      case ParameterType.duration:
        return DisplayText(text: _numberLabel(parameter, value), fontSize: 24);

      case ParameterType.temperature:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            DisplayText(
              text: parameter.formatTemperature(
                value is num ? value as num : null,
                to: displayUnit,
              ),
              fontSize: 24,
            ),
            if (onDisplayUnitChanged != null) ...[
              const SizedBox(height: 8),
              _TempUnitSwitcher(
                selected: displayUnit,
                onChanged: onDisplayUnitChanged!,
              ),
            ],
          ],
        );

      case ParameterType.toggle:
        final on = value == true;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniSwitch(on: on),
            const SizedBox(width: 11),
            DisplayText(
              text: on ? parameter.resolvedOnLabel : parameter.resolvedOffLabel,
              fontSize: 22,
            ),
          ],
        );

      case ParameterType.choice:
        return OptionPreview(
          options: [value?.toString() ?? '—'],
          tone: MixMaxChipTone.sage,
        );

      case ParameterType.order:
        return OrderPreview(
          items:
              value is List
                  ? (value as List).map((e) => e.toString()).toList()
                  : const [],
        );

      case null:
        return const DisplayText(text: '—', fontSize: 24);
    }
  }
}

/// The interactive counterpart to [_SuggestedValue]: an editor constrained to
/// the parameter's own spec — a slider between its min/max (snapped to its
/// increment), a single-select over its options, a reorder of its items, or an
/// on/off switch with its labels. Controlled: every change is reported up; this
/// widget keeps no state.
class _SuggestedEditor extends StatelessWidget {
  final SchemaParameter parameter;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  /// The scale a temperature is shown in while editing. Ignored for other types.
  final TemperatureUnit displayUnit;

  /// When non-null, a °C / °F / K switcher accompanies a temperature slider.
  final ValueChanged<TemperatureUnit>? onDisplayUnitChanged;

  const _SuggestedEditor({
    required this.parameter,
    required this.value,
    required this.onChanged,
    required this.displayUnit,
    this.onDisplayUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (parameter.type) {
      case ParameterType.number:
      case ParameterType.duration:
        return _NumberEditor(
          parameter: parameter,
          value: value,
          onChanged: onChanged,
        );

      case ParameterType.temperature:
        return _TemperatureEditor(
          parameter: parameter,
          value: value,
          onChanged: onChanged,
          displayUnit: displayUnit,
          onDisplayUnitChanged: onDisplayUnitChanged,
        );

      case ParameterType.toggle:
        final on = value == true;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MixMaxToggleInput(value: on, onChanged: onChanged),
            const SizedBox(width: 13),
            DisplayText(
              text: on ? parameter.resolvedOnLabel : parameter.resolvedOffLabel,
              fontSize: 22,
            ),
          ],
        );

      case ParameterType.choice:
        return _ChoiceEditor(
          options: parameter.options ?? const [],
          selected: value?.toString(),
          onChanged: onChanged,
        );

      case ParameterType.order:
        return _OrderEditor(
          value: value,
          fallback: parameter.items ?? const [],
          onChanged: onChanged,
        );

      case null:
        return const DisplayText(text: '—', fontSize: 24);
    }
  }
}

/// A bounded slider for number / duration parameters, with the live value as the
/// serif hero above it. When the parameter has no usable min/max range it falls
/// back to a clamped numeric field so an open-ended value can still be typed.
class _NumberEditor extends StatelessWidget {
  final SchemaParameter parameter;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _NumberEditor({
    required this.parameter,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final min = parameter.min;
    final max = parameter.max;
    final hasRange = min != null && max != null && max > min;

    if (!hasRange) {
      return _NumberFieldFallback(
        parameter: parameter,
        value: value,
        onChanged: onChanged,
      );
    }

    final current = (value is num ? (value as num).toDouble() : min).clamp(
      min,
      max,
    );
    // Respect the parameter's granularity; smooth params get ~100 fine stops so
    // the track still feels continuous.
    final increment =
        (parameter.increment != null && parameter.increment! > 0)
            ? parameter.increment!
            : (max - min) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DisplayText(text: _numberLabel(parameter, current), fontSize: 28),
        const SizedBox(height: 10),
        MixMaxSliderField(
          value: current,
          min: min,
          max: max,
          increment: increment,
          format:
              parameter.type == ParameterType.duration
                  ? parameter.formatDuration
                  : null,
          onChanged: (v) => onChanged(parameter.snapToIncrement(v)),
        ),
      ],
    );
  }
}

/// A clamped numeric text field — the editor for a number parameter that has no
/// bounded range to slide within.
class _NumberFieldFallback extends StatefulWidget {
  final SchemaParameter parameter;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _NumberFieldFallback({
    required this.parameter,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_NumberFieldFallback> createState() => _NumberFieldFallbackState();
}

class _NumberFieldFallbackState extends State<_NumberFieldFallback> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final v = widget.value;
    _controller = TextEditingController(
      text: v is num ? MixMaxFormat.number(v.toDouble()) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null) return;
    var v = parsed;
    final min = widget.parameter.min;
    final max = widget.parameter.max;
    if (min != null && v < min) v = min;
    if (max != null && v > max) v = max;
    widget.onChanged(widget.parameter.snapToIncrement(v));
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.parameter.displayUnit;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: MixMaxTextInput(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            placeholder: 'Enter a value',
            onChanged: _commit,
          ),
        ),
        if (unit?.isNotEmpty == true) ...[
          const SizedBox(width: 12),
          CaptionText(text: unit, color: AppColors.inkSoft),
        ],
      ],
    );
  }
}

/// A bounded slider for a temperature parameter. The slider, its bounds and the
/// reported value all stay on the parameter's *stored* scale (so snapping to the
/// increment is exact); only the hero label and the slider's end labels are
/// converted into the reader-selected [displayUnit]. A °C / °F / K switcher sits
/// below so the reader can flip the lens. Falls back to a clamped field (in the
/// stored scale) when there's no usable range to slide within.
class _TemperatureEditor extends StatelessWidget {
  final SchemaParameter parameter;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final TemperatureUnit displayUnit;
  final ValueChanged<TemperatureUnit>? onDisplayUnitChanged;

  const _TemperatureEditor({
    required this.parameter,
    required this.value,
    required this.onChanged,
    required this.displayUnit,
    this.onDisplayUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final min = parameter.min;
    final max = parameter.max;
    final hasRange = min != null && max != null && max > min;

    final switcher =
        onDisplayUnitChanged == null
            ? null
            : _TempUnitSwitcher(
              selected: displayUnit,
              onChanged: onDisplayUnitChanged!,
            );

    if (!hasRange) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NumberFieldFallback(
            parameter: parameter,
            value: value,
            onChanged: onChanged,
          ),
          if (switcher != null) ...[
            const SizedBox(height: 14),
            Align(alignment: Alignment.centerLeft, child: switcher),
          ],
        ],
      );
    }

    final current = (value is num ? (value as num).toDouble() : min).clamp(
      min,
      max,
    );
    final increment =
        (parameter.increment != null && parameter.increment! > 0)
            ? parameter.increment!
            : (max - min) / 100;

    String fmt(num? v) => parameter.formatTemperature(v, to: displayUnit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DisplayText(text: fmt(current), fontSize: 28),
        const SizedBox(height: 10),
        MixMaxSliderField(
          value: current,
          min: min,
          max: max,
          increment: increment,
          format: fmt,
          onChanged: (v) => onChanged(parameter.snapToIncrement(v)),
        ),
        if (switcher != null) ...[
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerLeft, child: switcher),
        ],
      ],
    );
  }
}

/// The °F / °C / K lens toggle shown on a suggested temperature — a row of pill
/// chips, the active scale filled sage. Tapping one re-reads the value on that
/// scale; it never changes the stored value.
class _TempUnitSwitcher extends StatelessWidget {
  final TemperatureUnit selected;
  final ValueChanged<TemperatureUnit> onChanged;

  /// Presentation order, matching the add-parameter drawer's segmented picker.
  static const List<TemperatureUnit> _order = [
    TemperatureUnit.fahrenheit,
    TemperatureUnit.celsius,
    TemperatureUnit.kelvin,
  ];

  const _TempUnitSwitcher({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final u in _order)
          MixMaxChip(
            label: u.symbol,
            tone: u == selected ? MixMaxChipTone.sage : MixMaxChipTone.outline,
            onTap: () => onChanged(u),
          ),
      ],
    );
  }
}

/// A single-select over a choice parameter's options, rendered as tap-to-pick
/// chips. The active option fills sage; the rest sit as quiet outline chips.
class _ChoiceEditor extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<dynamic> onChanged;

  const _ChoiceEditor({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const BodyText(text: 'No options set.', fontSize: 13);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          MixMaxChip(
            label: option,
            tone:
                option == selected
                    ? MixMaxChipTone.sage
                    : MixMaxChipTone.outline,
            onTap: () => onChanged(option),
          ),
      ],
    );
  }
}

/// A drag-to-reorder list of an order parameter's items — the user can only
/// rearrange the spec's items, never add or drop one.
class _OrderEditor extends StatelessWidget {
  final dynamic value;
  final List<String> fallback;
  final ValueChanged<dynamic> onChanged;

  const _OrderEditor({
    required this.value,
    required this.fallback,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items =
        value is List
            ? (value as List).map((e) => e.toString()).toList()
            : List<String>.from(fallback);

    if (items.isEmpty) {
      return const BodyText(text: 'No steps set.', fontSize: 13);
    }

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      proxyDecorator:
          (child, index, animation) =>
              Material(color: Colors.transparent, child: child),
      onReorder: (oldIndex, newIndex) {
        final next = [...items];
        if (newIndex > oldIndex) newIndex -= 1;
        next.insert(newIndex, next.removeAt(oldIndex));
        onChanged(next);
      },
      children: [
        for (var i = 0; i < items.length; i++)
          _OrderRow(
            key: ValueKey('order-$i-${items[i]}'),
            index: i,
            label: items[i],
          ),
      ],
    );
  }
}

/// One row of the order editor: its position, the step name, and a grip handle
/// that starts the drag.
class _OrderRow extends StatelessWidget {
  final int index;
  final String label;

  const _OrderRow({required Key key, required this.index, required this.label})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: DisplayText(
                text: '${index + 1}',
                fontSize: 16,
                color: AppColors.sageText,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppFonts.sans,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                  color: AppColors.ink,
                  height: 1.1,
                ),
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: MixMaxIcon(
                    MixMaxGlyph.grip,
                    size: 18,
                    color: AppColors.inkFaint,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parameter type → sage list glyph. Mirrors `theme.jsx` `PARAM_TYPES` (the same
/// mapping the details page's `ParameterDisplay` uses).
MixMaxGlyph _glyphForType(ParameterType? type) {
  switch (type) {
    case ParameterType.number:
      return MixMaxGlyph.hash;
    case ParameterType.duration:
      return MixMaxGlyph.timer;
    case ParameterType.temperature:
      return MixMaxGlyph.ruler;
    case ParameterType.toggle:
      return MixMaxGlyph.toggle;
    case ParameterType.choice:
      return MixMaxGlyph.list;
    case ParameterType.order:
      return MixMaxGlyph.order;
    case null:
      return MixMaxGlyph.hash;
  }
}

/// Formats a number / duration value with its unit, matching the read-only card.
/// Durations are rendered as a `1h 30m` string via the parameter itself.
String _numberLabel(SchemaParameter parameter, dynamic value) {
  if (value is! num) return '—';
  if (parameter.type == ParameterType.duration) {
    return parameter.formatDuration(value);
  }
  final s = MixMaxFormat.number(value.toDouble(), decimals: 3);
  return parameter.unit?.isNotEmpty == true ? '$s ${parameter.unit}' : s;
}
