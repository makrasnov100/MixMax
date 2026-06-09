import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';
import 'package:mix_max/widgets/pages/experiments_list/experiment_list_item.dart';

/// The scrollable body of the Experiments list — a stack of
/// [ExperimentListItem] cards, or the "nothing brewing yet" empty state.
///
/// Source: `screens.jsx` `ExperimentsListScreen` (the experiments column +
/// empty hint). The screen chrome — eyebrow, "Experiments" display title, and
/// the floating "New experiment" button — stays with the page; this widget
/// owns only the list itself so it can be dropped into a `StreamBuilder`.
class ExperimentsList extends StatelessWidget {
  final List<SchemaExperiment> experiments;

  /// Tapping a card opens its experiment.
  final void Function(SchemaExperiment experiment) onOpen;

  /// Outer padding. Defaults to the design's `22 / 20 / 8 / 20` (T R B L); the
  /// caller should add bottom room for the floating action button.
  final EdgeInsetsGeometry padding;

  /// When set, attached to the first card so the onboarding tour can spotlight
  /// it. Null in normal use.
  final Key? firstItemKey;

  const ExperimentsList({
    Key? key,
    required this.experiments,
    required this.onOpen,
    this.padding = const EdgeInsets.fromLTRB(20, 22, 20, 8),
    this.firstItemKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (experiments.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      padding: padding,
      itemCount: experiments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 13),
      itemBuilder: (_, index) {
        final experiment = experiments[index];
        return KeyedSubtree(
          key: index == 0 ? firstItemKey : null,
          child: ExperimentListItem(
            experiment: experiment,
            onTap: () => onOpen(experiment),
          ),
        );
      },
    );
  }
}

/// Shown when the user has no experiments yet.
///
/// Source: `screens.jsx` `ExperimentsListScreen` empty branch — a gold flask
/// tile over a serif headline and a soft prompt.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            MixMaxTile(
              glyph: MixMaxGlyph.flask,
              tone: MixMaxTileTone.gold,
              size: 64,
              radius: 20,
            ),
            SizedBox(height: 18),
            TitleText(
              text: 'Nothing brewing yet',
              fontSize: 22,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            BodyText(
              text: 'Start an experiment to let Mix Max find your best mix.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
