import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/selectable_pill.dart';

/// Display metadata for a [ParameterType] — its glyph, human label, and the
/// one-line blurb shown beneath the picker. Mirrors `theme.jsx` `PARAM_TYPES`.
class ParamTypeMeta {
  final MixMaxGlyph glyph;
  final String label;
  final String blurb;

  const ParamTypeMeta(this.glyph, this.label, this.blurb);
}

/// The "What kind of value?" picker — a wrapping button group of selectable
/// pills, one per [ParameterType].
///
/// Source: `drawers.jsx` `TypePicker`. Lays the five parameter types out as
/// [MixMaxSelectablePill]s that flow onto multiple lines; tapping one reports it
/// through [onChanged]. The accompanying blurb (`metaFor(type).blurb`) is left to
/// the host drawer to render, since it sits outside the button group.
class MixMaxParamTypePicker extends StatelessWidget {
  /// The currently chosen type, or null when nothing is selected yet.
  final ParameterType? value;

  /// Fires with the tapped type.
  final ValueChanged<ParameterType> onChanged;

  /// The types to offer, in display order. Defaults to all of them.
  final List<ParameterType> types;

  const MixMaxParamTypePicker({
    Key? key,
    required this.value,
    required this.onChanged,
    this.types = ParameterType.values,
  }) : super(key: key);

  /// Glyph / label / blurb for a parameter type. Shared so the drawer can show
  /// the blurb with the same source of truth the pills use.
  static ParamTypeMeta metaFor(ParameterType type) {
    switch (type) {
      case ParameterType.number:
        return const ParamTypeMeta(MixMaxGlyph.hash, 'Number', 'A measured amount');
      case ParameterType.duration:
        return const ParamTypeMeta(MixMaxGlyph.timer, 'Duration', 'A length of time');
      case ParameterType.toggle:
        return const ParamTypeMeta(MixMaxGlyph.toggle, 'Toggle', 'On or off');
      case ParameterType.choice:
        return const ParamTypeMeta(MixMaxGlyph.list, 'Choice', 'Pick from options');
      case ParameterType.order:
        return const ParamTypeMeta(MixMaxGlyph.order, 'Order', 'A sequence');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in types)
          MixMaxSelectablePill(
            icon: metaFor(type).glyph,
            label: metaFor(type).label,
            selected: type == value,
            onTap: () => onChanged(type),
          ),
      ],
    );
  }
}
