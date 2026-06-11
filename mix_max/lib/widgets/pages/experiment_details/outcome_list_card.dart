import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/widgets/design/atoms/card.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/molecules/empty_hint.dart';
import 'package:mix_max/widgets/pages/experiment_details/outcome_display.dart';

/// The grouped list of an experiment's outcomes — a single white card with one
/// [OutcomeDisplay] per outcome, hairline-divided.
///
/// Source: `screens.jsx` `GroupCard` wrapping `OutcomeRow`s. Mirrors
/// [ParameterListCard]: the card owns no padding, clips rows to its rounded
/// corners, and inserts an inset divider between rows. When [outcomes] is empty
/// it falls back to a dashed [MixMaxEmptyHint] (the "No outcomes yet" state).
class OutcomeListCard extends StatelessWidget {
  final List<SchemaOutcome> outcomes;

  /// Empty-state heading. Defaults to the design's copy.
  final String emptyTitle;

  /// Empty-state nudge. Defaults to the design's copy.
  final String emptyBody;

  /// Called with an outcome when its row is tapped — opens its edit drawer.
  /// Null leaves the rows inert.
  final ValueChanged<SchemaOutcome>? onEdit;

  /// Tapping the empty-state hint (e.g. open the add-outcome drawer).
  final VoidCallback? onAdd;

  /// Press-and-hold drag reorder handler, called with the row's old and new
  /// indices once a drag settles. Null disables reordering. The saved order
  /// drives how outcomes are walked on the record-outcomes page; past runs keep
  /// their own outcome snapshot, so reordering here never disturbs them.
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Paints the empty-state hint in the danger voice — flags a required but
  /// missing outcome when "Run experiment" is pressed.
  final bool emptyError;

  const OutcomeListCard({
    Key? key,
    required this.outcomes,
    this.emptyTitle = 'No outcomes yet',
    this.emptyBody = 'Add a result to maximize or minimize.',
    this.onEdit,
    this.onAdd,
    this.onReorder,
    this.emptyError = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (outcomes.isEmpty) {
      return MixMaxEmptyHint(
        glyph: MixMaxGlyph.target,
        title: emptyTitle,
        body: emptyBody,
        error: emptyError,
        onTap: onAdd,
      );
    }

    // With two or more rows and a reorder handler, the card becomes a
    // press-and-hold drag list so the order can be rearranged; otherwise it
    // stays a plain stack of rows.
    if (onReorder != null && outcomes.length > 1) {
      return MixMaxCard(
        padding: EdgeInsets.zero,
        clipContents: true,
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: outcomes.length,
          onReorder: onReorder!,
          proxyDecorator: _draggedRowDecorator,
          itemBuilder: (context, i) {
            final outcome = outcomes[i];
            return ReorderableDelayedDragStartListener(
              key: ValueKey('outcome-${outcome.id}'),
              index: i,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i > 0) const _RowDivider(),
                  OutcomeDisplay(
                    outcome: outcome,
                    onTap: onEdit == null ? null : () => onEdit!(outcome),
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
          for (var i = 0; i < outcomes.length; i++) ...[
            if (i > 0) const _RowDivider(),
            OutcomeDisplay(
              outcome: outcomes[i],
              onTap: onEdit == null ? null : () => onEdit!(outcomes[i]),
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
