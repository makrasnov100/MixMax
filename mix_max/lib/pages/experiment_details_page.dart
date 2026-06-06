import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/pages/run_iteration_page.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/ui/navigation_service.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/display_text.dart';
import 'package:mix_max/widgets/design/ions/text/section_label_text.dart';
import 'package:mix_max/widgets/experiments/add_output_drawer.dart';
import 'package:mix_max/widgets/experiments/add_parameter_drawer.dart';
import 'package:mix_max/widgets/pages/experiment_details/outcome_list_card.dart';
import 'package:mix_max/widgets/pages/experiment_details/parameter_list_card.dart';
import 'package:mix_max/widgets/pages/experiment_details/rename_experiment_drawer.dart';
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
/// design system. The runs chip and the "Best mix so far" banner are
/// intentionally left out for now; they'll be wired up with a runs source
/// later.
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
    await DatabaseService.experimentsRef
        .doc(_experiment.id)
        .set(_experiment, SetOptions(merge: true));
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
    await DatabaseService.experimentsRef
        .doc(_experiment.id)
        .set(_experiment, SetOptions(merge: true));
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
    await DatabaseService.experimentsRef
        .doc(_experiment.id)
        .set(_experiment, SetOptions(merge: true));
    if (!mounted) return;
    setState(() {});
  }

  void _runExperiment() {
    Navigation.goTo(
      context: context,
      page: RunIterationPage(experiment: _experiment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parameters = _experiment.parameters ?? const [];
    final outcomes = _experiment.outcomes ?? const [];
    final canRun = parameters.isNotEmpty && outcomes.isNotEmpty;
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
                  // Top bar: back.
                  Row(
                    children: [
                      _RoundButton(
                        glyph: MixMaxGlyph.arrowLeft,
                        onTap: () => Navigator.of(context).maybePop(),
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

/// A 40px circular icon button — the back affordance in the top bar.
///
/// Source: `ui.jsx` `RoundBtn` (neutral tone): a white surface disc with a
/// hairline ring and a soft shadow.
class _RoundButton extends StatelessWidget {
  final MixMaxGlyph glyph;
  final VoidCallback onTap;

  const _RoundButton({required this.glyph, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.hairline, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D221F2A),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: MixMaxIcon(glyph, size: 20, color: AppColors.ink),
        ),
      ),
    );
  }
}
