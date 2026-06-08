import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/pages/run_details_page.dart';
import 'package:mix_max/pages/run_history_page.dart';
import 'package:mix_max/pages/suggested_run_page.dart';
import 'package:mix_max/services/ui/navigation_service.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/round_button.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/display_text.dart';
import 'package:mix_max/widgets/design/ions/text/section_label_text.dart';
import 'package:mix_max/widgets/pages/experiment_details/add_output_drawer.dart';
import 'package:mix_max/widgets/pages/experiment_details/add_parameter_drawer.dart';
import 'package:mix_max/widgets/pages/experiment_details/best_mix_card.dart';
import 'package:mix_max/widgets/pages/experiment_details/confirm_delete_experiment_drawer.dart';
import 'package:mix_max/widgets/pages/experiment_details/experiment_actions_drawer.dart';
import 'package:mix_max/widgets/pages/experiment_details/outcome_list_card.dart';
import 'package:mix_max/widgets/pages/experiment_details/parameter_list_card.dart';
import 'package:mix_max/widgets/pages/experiment_details/rename_experiment_drawer.dart';
import 'package:mix_max/widgets/pages/experiment_details/runs_pill.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';

/// The Experiment Details screen.
///
/// Source: `design_app/screens.jsx` `ExperimentDetailsScreen`. A warm
/// editorial layout: a back top bar, the tappable serif experiment name, then
/// the grouped Parameters and Outcomes cards. A sticky footer carries the gold
/// "Run experiment" action and the sage / violet "add" buttons.
///
/// The add-parameter, add-outcome and rename flows still open the existing
/// bottom-sheet drawers — only the page chrome has been moved onto the new
/// design system. The "Best mix so far" banner shows once the experiment has a
/// cached [SchemaExperiment.bestRun], and the top bar carries a soft chip with
/// the experiment's [SchemaExperiment.runCount].
class ExperimentDetailsPage extends StatefulWidget {
  final SchemaExperiment experiment;

  const ExperimentDetailsPage({super.key, required this.experiment});

  @override
  State<ExperimentDetailsPage> createState() => _ExperimentDetailsPageState();
}

class _ExperimentDetailsPageState extends State<ExperimentDetailsPage> {
  late SchemaExperiment _experiment;

  @override
  void initState() {
    super.initState();
    _experiment = widget.experiment;
  }

  /// Opens the "Manage this experiment" actions drawer (rename / delete).
  void _showActionsDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ExperimentActionsDrawer(
        experimentName: _experiment.name,
        onRename: _showRenameDrawer,
        onDelete: _showConfirmDeleteDrawer,
      ),
    );
  }

  /// Opens the destructive confirm-delete drawer.
  void _showConfirmDeleteDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ConfirmDeleteExperimentDrawer(
        experimentName: _experiment.name,
        parameterCount: _experiment.parameters?.length ?? 0,
        outcomeCount: _experiment.outcomes?.length ?? 0,
        runCount: _experiment.runCount,
        onConfirm: _deleteExperiment,
      ),
    );
  }

  /// Deletes the experiment, then returns straight to the experiments list.
  Future<void> _deleteExperiment() async {
    await _experiment.delete();
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _showRenameDrawer({String title = 'Rename experiment'}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => RenameExperimentDrawer(
            title: title,
            initialName: _experiment.name,
            onSave: _saveName,
          ),
    );
  }

  Future<void> _saveName(String name) async {
    _experiment.name = name;
    await _experiment.save();
    if (!mounted) return;
    setState(() {});
  }

  void _showAddParameterDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddParameterDrawer(onSave: _saveParameter),
    );
  }

  Future<void> _saveParameter(SchemaParameter parameter) async {
    _experiment.parameters = [...(_experiment.parameters ?? []), parameter];
    await _experiment.save();
    if (!mounted) return;
    setState(() {});
  }

  void _showAddOutputDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddOutputDrawer(onSave: _saveOutcome),
    );
  }

  Future<void> _saveOutcome(SchemaOutcome outcome) async {
    _experiment.outcomes = [...(_experiment.outcomes ?? []), outcome];
    await _experiment.save();
    if (!mounted) return;
    setState(() {});
  }

  /// Opens the Run History page for this experiment.
  void _openRunHistory() {
    Navigation.goTo(
      context: context,
      page: RunHistoryPage(experiment: _experiment),
    );
  }

  /// Opens the cached best run's details. The full run list isn't loaded here,
  /// so the run's chronological number is unknown — the details header falls
  /// back to the "Best run" kicker.
  void _openBestRun(SchemaRun run) {
    Navigation.goTo(
      context: context,
      page: RunDetailsPage(
        experiment: _experiment,
        run: run,
        isBest: true,
      ),
    );
  }

  Future<void> _runExperiment() async {
    // The run flow mutates [_experiment] in place (e.g. promoting a new best
    // run); rebuild on return so the "Best mix so far" banner reflects it.
    await Navigation.goTo(
      context: context,
      page: SuggestedRunPage(experiment: _experiment),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final parameters = _experiment.parameters ?? const [];
    final outcomes = _experiment.outcomes ?? const [];
    final canRun = parameters.isNotEmpty && outcomes.isNotEmpty;
    final runCount = _experiment.runCount;
    final bestRun = _experiment.bestRun;
    final bestLabel =
        bestRun == null ? null : BestMixCard.labelFor(outcomes, bestRun);
    final name =
        _experiment.name?.isNotEmpty == true
            ? _experiment.name!
            : 'Untitled experiment';

    return OrientationScaffold(
      body: ColoredBox(
        color: AppColors.bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: back + the run-count chip on the right.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MixMaxRoundButton(
                        glyph: MixMaxGlyph.arrowLeft,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RunsPill(
                            count: runCount,
                            onTap: _openRunHistory,
                          ),
                          const SizedBox(width: 10),
                          MixMaxRoundButton(
                            glyph: MixMaxGlyph.more,
                            onTap: _showActionsDrawer,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Tappable experiment name → rename drawer. The edit glyph
                  // flows inline right after the name (an Expanded row would
                  // shove it to the far screen edge instead).
                  const SizedBox(height: 18),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showRenameDrawer(),
                    child: Text.rich(
                      TextSpan(
                        text: name,
                        style: DisplayText.styleOf(fontSize: 36),
                        children: const [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: MixMaxIcon(
                                MixMaxGlyph.edit,
                                size: 19,
                                color: AppColors.inkFaint,
                              ),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Best mix so far — only once a winning run is recorded.
                  if (bestLabel != null && bestRun != null) ...[
                    const SizedBox(height: 22),
                    BestMixCard(
                      label: bestLabel,
                      onTap: () => _openBestRun(bestRun),
                    ),
                  ],

                  // Parameters.
                  const SizedBox(height: 26),
                  _SectionHeader(
                    label: 'Parameters',
                    count: parameters.isEmpty ? null : parameters.length,
                  ),
                  const SizedBox(height: 4),
                  const BodyText(
                    text: 'The knobs Mix Max tunes for you.',
                    fontSize: 13,
                  ),
                  const SizedBox(height: 13),
                  ParameterListCard(parameters: parameters),

                  // Outcomes.
                  const SizedBox(height: 24),
                  _SectionHeader(
                    label: 'Outcomes',
                    count: outcomes.isEmpty ? null : outcomes.length,
                  ),
                  const SizedBox(height: 4),
                  const BodyText(
                    text: 'What you measure to score each run.',
                    fontSize: 13,
                  ),
                  const SizedBox(height: 13),
                  OutcomeListCard(outcomes: outcomes),
                ],
              ),
            ),

            // Sticky footer over a bg fade.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00FBF7F0), AppColors.bg],
                    stops: [0.0, 0.28],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MixMaxButton(
                      label: 'Run experiment',
                      variant: MixMaxButtonVariant.gold,
                      enabled: canRun,
                      onPressed: canRun ? _runExperiment : null,
                      trailing: MixMaxIcon(
                        MixMaxGlyph.play,
                        size: 20,
                        color: canRun ? Colors.white : AppColors.inkFaint,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: MixMaxButton(
                            label: 'Parameter',
                            variant: MixMaxButtonVariant.sage,
                            onPressed: _showAddParameterDrawer,
                            leading: const MixMaxIcon(
                              MixMaxGlyph.plus,
                              size: 20,
                              color: AppColors.sageText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MixMaxButton(
                            label: 'Outcome',
                            variant: MixMaxButtonVariant.violet,
                            onPressed: _showAddOutputDrawer,
                            leading: const MixMaxIcon(
                              MixMaxGlyph.plus,
                              size: 20,
                              color: AppColors.violetText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The italic serif section heading with an optional faint count beside it.
///
/// Source: `ui.jsx` `SectionLabel` (serif italic label + sans count, baseline
/// aligned).
class _SectionHeader extends StatelessWidget {
  final String label;
  final int? count;

  const _SectionHeader({required this.label, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SectionLabelText(text: label),
        if (count != null) ...[
          const SizedBox(width: 9),
          CaptionText(
            text: '$count',
            color: AppColors.inkFaint,
            fontWeight: FontWeight.w600,
          ),
        ],
      ],
    );
  }
}
