import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/widgets/design/atoms/card.dart';
import 'package:mix_max/widgets/design/atoms/chip.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/format.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/display_text.dart';
import 'package:mix_max/widgets/design/molecules/mini_switch.dart';
import 'package:mix_max/widgets/design/molecules/option_preview.dart';
import 'package:mix_max/widgets/design/molecules/order_preview.dart';

/// One suggested-parameter card on the Suggested Run page — a sage type tile,
/// the parameter's name, and the concrete value the optimizer picked for this
/// run.
///
/// Source: `design_app/screens.jsx` `SuggestionCard`. A number/duration reads as
/// a serif metric (the card's hero); choice / order / toggle reuse the system's
/// value-preview molecules so a pick looks the same here as on the details page.
class SuggestionCard extends StatelessWidget {
  final SchemaParameter parameter;
  final dynamic value;

  const SuggestionCard({
    Key? key,
    required this.parameter,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MixMaxCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MixMaxTile(
            glyph: _glyphForType(parameter.type),
            tone: MixMaxTileTone.sage,
            size: 46,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CaptionText(
                  text: parameter.name?.isNotEmpty == true
                      ? parameter.name
                      : 'Untitled parameter',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _SuggestedValue(parameter: parameter, value: value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The per-type value visual for a suggested parameter (source: `screens.jsx`
/// `fmtSuggested`, lifted into the system's preview molecules).
class _SuggestedValue extends StatelessWidget {
  final SchemaParameter parameter;
  final dynamic value;

  const _SuggestedValue({required this.parameter, required this.value});

  @override
  Widget build(BuildContext context) {
    switch (parameter.type) {
      case ParameterType.number:
      case ParameterType.duration:
        return DisplayText(text: _numberLabel(), fontSize: 24);

      case ParameterType.toggle:
        final on = value == true;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniSwitch(on: on),
            const SizedBox(width: 11),
            DisplayText(text: on ? 'On' : 'Off', fontSize: 22),
          ],
        );

      case ParameterType.choice:
        return OptionPreview(
          options: [value?.toString() ?? '—'],
          tone: MixMaxChipTone.sage,
        );

      case ParameterType.order:
        return OrderPreview(
          items: value is List
              ? (value as List).map((e) => e.toString()).toList()
              : const [],
        );

      case null:
        return const DisplayText(text: '—', fontSize: 24);
    }
  }

  String _numberLabel() {
    if (value is num) {
      final s = MixMaxFormat.number((value as num).toDouble(), decimals: 3);
      return parameter.unit?.isNotEmpty == true ? '$s ${parameter.unit}' : s;
    }
    return '—';
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
