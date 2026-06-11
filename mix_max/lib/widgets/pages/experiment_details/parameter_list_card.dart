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

  /// Tapping the empty-state hint (e.g. open the add-parameter drawer).
  final VoidCallback? onAdd;

  /// Press-and-hold drag reorder handler, called with the row's old and new
  /// indices once a drag settles. Null disables reordering (the rows render as
  /// a plain list). Reordering only changes the saved list order — it never
  /// rewrites a parameter's definition, so it leaves earlier runs untouched.
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Paints the empty-state hint in the danger voice — flags a required but
  /// missing parameter when "Run experiment" is pressed.
  final bool emptyError;

  const ParameterListCard({
    Key? key,
    required this.parameters,
    this.emptyTitle = 'No parameters yet',
    this.emptyBody = 'Add the knobs you want to tune.',
    this.onEdit,
    this.onAdd,
    this.onReorder,
    this.emptyError = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (parameters.isEmpty) {
      return MixMaxEmptyHint(
        glyph: MixMaxGlyph.sparkle,
        title: emptyTitle,
        body: emptyBody,
        error: emptyError,
        onTap: onAdd,
      );
    }

    // With two or more rows and a reorder handler, the card becomes a
    // press-and-hold drag list so the order can be rearranged; otherwise it
    // stays a plain stack of rows.
    if (onReorder != null && parameters.length > 1) {
      return MixMaxCard(
        padding: EdgeInsets.zero,
        clipContents: true,
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: parameters.length,
          onReorder: onReorder!,
          proxyDecorator: _draggedRowDecorator,
          itemBuilder: (context, i) {
            final parameter = parameters[i];
            return ReorderableDelayedDragStartListener(
              key: ValueKey('parameter-${parameter.id}'),
              index: i,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i > 0) const _RowDivider(),
                  ParameterDisplay(
                    parameter: parameter,
                    onTap: onEdit == null ? null : () => onEdit!(parameter),
                  ),
                ],
              ),
            );
          },
        ),
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

/// Lifts the row being dragged onto a white surface with a soft shadow, so it
/// reads as floating above the card while it is moved. Mirrors the calm
/// `CARD_SHADOW` lift used elsewhere in the design system.
Widget _draggedRowDecorator(
  Widget child,
  int index,
  Animation<double> animation,
) {
  return Material(
    color: AppColors.surface,
    elevation: 6,
    shadowColor: const Color(0x33221F2A),
    child: child,
  );
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
