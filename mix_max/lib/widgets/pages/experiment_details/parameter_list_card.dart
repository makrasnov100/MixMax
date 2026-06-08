import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/widgets/design/atoms/card.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/molecules/empty_hint.dart';
import 'package:mix_max/widgets/pages/experiment_details/parameter_display.dart';

/// The grouped list of an experiment's parameters — a single white card with
/// one [ParameterDisplay] per parameter, hairline-divided.
///
/// Source: `screens.jsx` `GroupCard` wrapping `ParamRow`s. The card itself owns
/// no padding (each row pads itself), clips its rows to the rounded corners, and
/// inserts an inset divider between rows. When [parameters] is empty it falls
/// back to a dashed [MixMaxEmptyHint] (the "No parameters yet" state), so callers
/// can drop it in unconditionally.
class ParameterListCard extends StatelessWidget {
  final List<SchemaParameter> parameters;

  /// Empty-state heading. Defaults to the design's copy.
  final String emptyTitle;

  /// Empty-state nudge. Defaults to the design's copy.
  final String emptyBody;

  /// Called with a parameter when its row is tapped — opens its edit drawer.
  /// Null leaves the rows inert.
  final ValueChanged<SchemaParameter>? onEdit;

  const ParameterListCard({
    Key? key,
    required this.parameters,
    this.emptyTitle = 'No parameters yet',
    this.emptyBody = 'Add the knobs you want to tune.',
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (parameters.isEmpty) {
      return MixMaxEmptyHint(
        glyph: MixMaxGlyph.sparkle,
        title: emptyTitle,
        body: emptyBody,
      );
    }

    return MixMaxCard(
      padding: EdgeInsets.zero,
      clipContents: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < parameters.length; i++) ...[
            if (i > 0) const _RowDivider(),
            ParameterDisplay(
              parameter: parameters[i],
              onTap: onEdit == null ? null : () => onEdit!(parameters[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// Inset hairline between rows — indented past the type tile, per `screens.jsx`
/// `Divider` (`marginLeft: 70`).
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 70),
      child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
    );
  }
}
