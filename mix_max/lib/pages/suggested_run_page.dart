import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/pages/record_outcomes_page.dart';
import 'package:mix_max/services/bayesian_optimization_service.dart';
import 'package:mix_max/services/firebase/auth_service.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/services/ui/navigation_service.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/display_text.dart';
import 'package:mix_max/widgets/design/ions/text/eyebrow_text.dart';
import 'package:mix_max/widgets/design/ions/text/section_label_text.dart';
import 'package:mix_max/widgets/pages/suggested_run/smart_pick_banner.dart';
import 'package:mix_max/widgets/pages/suggested_run/suggestion_card.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';
import 'package:mix_max/widgets/wrappers/sticky_top_bar.dart';

enum _SuggestedRunPhase { loading, ready, error }

/// The first half of running an iteration: it asks the optimizer for the next
/// set of parameters to try and shows them. Nothing is persisted here — a draft
/// [SchemaRun] is held in memory only. The run is written to the database the
/// moment the user presses "Record outcomes", which then hands off to the
/// [RecordOutcomesPage] where the measured values are entered.
class SuggestedRunPage extends StatefulWidget {
  final SchemaExperiment experiment;

  /// When non-null, the page shows this fixed suggestion instead of querying
  /// past runs and running the optimizer — used by the onboarding tour so the
  /// suggested-run screen renders offline against in-memory demo data.
  final Map<String, dynamic>? demoSuggestion;

  /// Spotlight target for the onboarding tour, attached to the suggested values.
  final Key? spotlightKey;

  const SuggestedRunPage({
    super.key,
    required this.experiment,
    this.demoSuggestion,
    this.spotlightKey,
  });

  @override
  State<SuggestedRunPage> createState() => _SuggestedRunPageState();
}

class _SuggestedRunPageState extends State<SuggestedRunPage> {
  _SuggestedRunPhase _phase = _SuggestedRunPhase.loading;
  String? _errorMessage;

  Map<String, dynamic> _suggestedParameters = const <String, dynamic>{};
  SchemaRun? _draftRun;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    setState(() {
      _phase = _SuggestedRunPhase.loading;
      _errorMessage = null;
    });

    try {
      // Onboarding tour: skip the database + optimizer and present the fixed
      // demo suggestion. Nothing is ever recorded, so a placeholder user id is
      // fine for the in-memory draft run.
      final demoSuggestion = widget.demoSuggestion;
      if (demoSuggestion != null) {
        final docRef = DatabaseService.runsRef.doc();
        final draft = SchemaRun(
          id: docRef.id,
          experimentId: widget.experiment.id,
          userId: 'demo',
          parameterValues: demoSuggestion,
          parameters: widget.experiment.parameters ?? const [],
          outcomes: widget.experiment.outcomes ?? const [],
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
        if (!mounted) return;
        setState(() {
          _suggestedParameters = demoSuggestion;
          _draftRun = draft;
          _phase = _SuggestedRunPhase.ready;
        });
        return;
      }

      final userId = getIt<AuthService>().user.id;
      if (userId.isEmpty || userId == 'INITIAL') {
        throw StateError('Not signed in yet. Please try again in a moment.');
      }

      final pastRunsSnapshot =
          await DatabaseService.runsRef
              .where('userId', isEqualTo: userId)
              .where('experimentId', isEqualTo: widget.experiment.id)
              .get();

      final pastRuns =
          pastRunsSnapshot.docs
              .map((d) => d.data())
              .where((r) => r.isValid())
              .toList();

      final suggestion = BayesianOptimizationService.suggestNextParameters(
        experiment: widget.experiment,
        pastRuns: pastRuns,
      );

      // Capture a point-in-time snapshot of the parameter and outcome
      // definitions so this run renders and scores correctly even after the
      // experiment is later edited. Deep-cloned via JSON so later edits to the
      // experiment never mutate the run's copy.
      final paramSnapshot =
          (widget.experiment.parameters ?? const [])
              .map((p) => SchemaParameter.fromJson(p.toJson()))
              .toList();
      final outcomeSnapshot =
          (widget.experiment.outcomes ?? const [])
              .map((o) => SchemaOutcome.fromJson(o.toJson()))
              .toList();

      final docRef = DatabaseService.runsRef.doc();
      final draft = SchemaRun(
        id: docRef.id,
        experimentId: widget.experiment.id,
        userId: userId,
        parameterValues: suggestion,
        parameters: paramSnapshot,
        outcomes: outcomeSnapshot,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      if (!mounted) return;
      setState(() {
        _suggestedParameters = suggestion;
        _draftRun = draft;
        _phase = _SuggestedRunPhase.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not generate next run.\n$e';
        _phase = _SuggestedRunPhase.error;
      });
    }
  }

  /// Hands the in-memory draft run off to the record-outcomes screen. Nothing is
  /// persisted yet — the run is written to the database only once every outcome
  /// has been recorded, on the final step of that flow.
  void _recordOutcomes() {
    final draft = _draftRun;
    if (draft == null) return;
    Navigation.goTo(
      context: context,
      page: RecordOutcomesPage(experiment: widget.experiment, run: draft),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationScaffold(
      body: ColoredBox(
        color: AppColors.bg,
        child: switch (_phase) {
          _SuggestedRunPhase.loading => const _StatusView(
            message: 'Generating next run…',
          ),
          _SuggestedRunPhase.error => _ErrorView(
            message: _errorMessage ?? 'Something went wrong.',
            onRetry: _bootstrap,
          ),
          _SuggestedRunPhase.ready => _ReadyView(
            experiment: widget.experiment,
            suggestion: _suggestedParameters,
            errorMessage: _errorMessage,
            spotlightKey: widget.spotlightKey,
            onBack: () => Navigator.of(context).maybePop(),
            onRecordOutcomes: _recordOutcomes,
          ),
        },
      ),
    );
  }
}

/// The suggested-parameters screen: top-bar back, eyebrow + serif name, the
/// smart-pick explainer, then one [SuggestionCard] per parameter over a sticky
/// "Record outcomes" footer.
class _ReadyView extends StatelessWidget {
  final SchemaExperiment experiment;
  final Map<String, dynamic> suggestion;
  final String? errorMessage;
  final Key? spotlightKey;
  final VoidCallback onBack;
  final VoidCallback onRecordOutcomes;

  const _ReadyView({
    required this.experiment,
    required this.suggestion,
    required this.errorMessage,
    required this.spotlightKey,
    required this.onBack,
    required this.onRecordOutcomes,
  });

  @override
  Widget build(BuildContext context) {
    final parameters = experiment.parameters ?? const [];
    final outcomes = experiment.outcomes ?? const [];
    final name =
        experiment.name?.isNotEmpty == true
            ? experiment.name!
            : 'Untitled experiment';

    return StickyTopBar(
      onBack: onBack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              StickyTopBar.contentInset,
              20,
              140,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EyebrowText(
                  text: 'Next run · suggested',
                  color: AppColors.gold,
                ),
                const SizedBox(height: 8),
                DisplayText(
                  text: name,
                  fontSize: 34,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),
                const SmartPickBanner(),

                const SizedBox(height: 22),
                KeyedSubtree(
                  key: spotlightKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabelText(text: 'Try these'),
                      const SizedBox(height: 13),
                      if (parameters.isEmpty)
                        const BodyText(text: 'No parameters set.', fontSize: 13)
                      else
                        for (var i = 0; i < parameters.length; i++) ...[
                          if (i > 0) const SizedBox(height: 11),
                          SuggestionCard(
                            parameter: parameters[i],
                            value: suggestion[parameters[i].id],
                          ),
                        ],
                    ],
                  ),
                ),

                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  BodyText(
                    text: errorMessage!,
                    color: AppColors.danger,
                    fontSize: 13,
                  ),
                ],
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
              child: MixMaxButton(
                label: 'Record outcomes',
                variant: MixMaxButtonVariant.ink,
                enabled: outcomes.isNotEmpty,
                onPressed: outcomes.isEmpty ? null : onRecordOutcomes,
                trailing: MixMaxIcon(
                  MixMaxGlyph.arrowRight,
                  size: 20,
                  color: outcomes.isEmpty ? AppColors.inkFaint : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A centered spinner + caption — the loading and saving states.
class _StatusView extends StatelessWidget {
  final String message;
  const _StatusView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation(AppColors.gold),
          ),
          const SizedBox(height: 22),
          BodyText(text: message, color: AppColors.inkSoft),
        ],
      ),
    );
  }
}

/// The error state: a gold-tinted info glyph, the message, and a retry button.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: MixMaxIcon(
              MixMaxGlyph.info,
              size: 40,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 16),
          BodyText(
            text: message,
            color: AppColors.inkSoft,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          MixMaxButton(
            label: 'Try again',
            variant: MixMaxButtonVariant.ghost,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
