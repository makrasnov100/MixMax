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

  const OutcomeListCard({
    Key? key,
    required this.outcomes,
    this.emptyTitle = 'No outcomes yet',
    this.emptyBody = 'Add a result to maximize or minimize.',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (outcomes.isEmpty) {
      return MixMaxEmptyHint(
        glyph: MixMaxGlyph.target,
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
          for (var i = 0; i < outcomes.length; i++) ...[
            if (i > 0) const _RowDivider(),
            OutcomeDisplay(outcome: outcomes[i]),
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
