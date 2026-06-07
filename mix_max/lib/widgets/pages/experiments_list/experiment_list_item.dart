import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/widgets/design/atoms/card.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';
import 'package:mix_max/widgets/pages/experiment_details/best_mix_card.dart';

/// One experiment row on the Experiments list — a tappable summary card.
///
/// Source: `screens.jsx` `ExperimentCard`. A white [MixMaxCard] holding the
/// experiment name (serif), a strip of "type" glyphs for its parameters and
/// outcomes, a meta line counting each, and — once a best run exists — a gold
/// "Best so far" footer.
///
/// The "Best so far" footer is driven by the experiment's cached
/// [SchemaExperiment.bestRun] and shows whenever one exists.
class ExperimentListItem extends StatelessWidget {
  final SchemaExperiment experiment;
  final VoidCallback onTap;

  const ExperimentListItem({
    Key? key,
    required this.experiment,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final params = experiment.parameters ?? const [];
    final outcomes = experiment.outcomes ?? const [];
    final bestRun = experiment.bestRun;
    final best =
        bestRun == null ? null : BestMixCard.labelFor(outcomes, bestRun);

    return MixMaxCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + chevron.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TitleText(
                  text: experiment.name?.isNotEmpty == true
                      ? experiment.name
                      : 'Untitled experiment',
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 3, left: 12),
                child: MixMaxIcon(
                  MixMaxGlyph.chevRight,
                  size: 20,
                  color: AppColors.inkFaint,
                ),
              ),
            ],
          ),

          // Param/outcome type-glyph strip (up to 5 params + 2 outcomes).
          if (params.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final p in params.take(5))
                  MixMaxTile(
                    glyph: _glyphForType(p.type),
                    tone: MixMaxTileTone.sage,
                    size: 32,
                    radius: 9,
                  ),
                for (var i = 0; i < outcomes.length && i < 2; i++)
                  const MixMaxTile(
                    glyph: MixMaxGlyph.target,
                    tone: MixMaxTileTone.violet,
                    size: 32,
                    radius: 9,
                  ),
              ],
            ),
          ],

          // Meta counts.
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _MetaBit(
                glyph: MixMaxGlyph.hash,
                text: '${params.length} '
                    'parameter${params.length == 1 ? '' : 's'}',
              ),
              _MetaBit(
                glyph: MixMaxGlyph.target,
                text: '${outcomes.length} '
                    'outcome${outcomes.length == 1 ? '' : 's'}',
              ),
              _MetaBit(
                glyph: MixMaxGlyph.flask,
                text: '${experiment.runCount} '
                    'run${experiment.runCount == 1 ? '' : 's'}',
              ),
            ],
          ),

          // Best-so-far footer.
          if (best != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: Row(
                children: [
                  const MixMaxIcon(
                    MixMaxGlyph.trophy,
                    size: 15,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  const CaptionText(text: 'Best so far'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CaptionText(
                      text: best,
                      color: AppColors.goldText,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single icon-plus-count fragment in the meta line.
///
/// Source: `screens.jsx` `MetaBit` (faint glyph + soft caption, weight 500).
class _MetaBit extends StatelessWidget {
  final MixMaxGlyph glyph;
  final String text;

  const _MetaBit({required this.glyph, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MixMaxIcon(glyph, size: 14, color: AppColors.inkFaint),
        const SizedBox(width: 5),
        CaptionText(text: text),
      ],
    );
  }
}

/// Parameter type → list glyph, mirroring `theme.jsx` `PARAM_TYPES`.
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

