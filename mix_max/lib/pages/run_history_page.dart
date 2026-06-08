import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/pages/run_details_page.dart';
import 'package:mix_max/services/firebase/auth_service.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/services/ui/navigation_service.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/round_button.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/display_text.dart';
import 'package:mix_max/widgets/design/ions/text/eyebrow_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';
import 'package:mix_max/widgets/pages/run_history/run_history_card.dart';
import 'package:mix_max/widgets/pages/run_history/run_sort_toggle.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';

enum _RunHistoryPhase { loading, ready, error }

/// The Run History screen — every completed run of an experiment, scored and
/// ordered, reached from the run-count pill on the Experiment Details page.
///
/// Source: `design_app/screens.jsx` `RunHistoryScreen`. The runs are loaded from
/// the Runs collection (the experiment only caches its best run and a count), so
/// this page owns the fetch and a loading / error / ready state. Once loaded the
/// user can re-order between "Most recent" and "Highest rated" via the
/// [RunSortToggle]; the highest-scoring run is highlighted as the best run.
///
/// Tapping a run opens the [RunDetailsPage], carrying that card's number and
/// best-run flag so the details header matches it.
class RunHistoryPage extends StatefulWidget {
  final SchemaExperiment experiment;

  const RunHistoryPage({super.key, required this.experiment});

  @override
  State<RunHistoryPage> createState() => _RunHistoryPageState();
}

class _RunHistoryPageState extends State<RunHistoryPage> {
  _RunHistoryPhase _phase = _RunHistoryPhase.loading;
  String? _errorMessage;

  /// Completed runs (those with recorded outcomes), unsorted.
  List<SchemaRun> _runs = const [];

  RunSortMode _sort = RunSortMode.recent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _phase = _RunHistoryPhase.loading;
      _errorMessage = null;
    });

    try {
      final userId = getIt<AuthService>().user.id;
      if (userId.isEmpty || userId == 'INITIAL') {
        throw StateError('Not signed in yet. Please try again in a moment.');
      }

      final snapshot = await DatabaseService.runsRef
          .where('userId', isEqualTo: userId)
          .where('experimentId', isEqualTo: widget.experiment.id)
          .get();

      final runs = snapshot.docs
          .map((d) => d.data())
          .where((r) => r.isValid() && r.outcomeValues != null)
          .toList();

      if (!mounted) return;
      setState(() {
        _runs = runs;
        _phase = _RunHistoryPhase.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load run history.\n$e';
        _phase = _RunHistoryPhase.error;
      });
    }
  }

  /// Opens the Run Details page for [run], carrying its chronological [number]
  /// and whether it is the experiment's best run so the details header matches
  /// the card the user tapped.
  void _openRun(SchemaRun run, int number, bool isBest) {
    Navigation.goTo(
      context: context,
      page: RunDetailsPage(
        experiment: widget.experiment,
        run: run,
        number: number,
        isBest: isBest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationScaffold(
      body: ColoredBox(
        color: AppColors.bg,
        child: switch (_phase) {
          _RunHistoryPhase.loading => const _StatusView(
              message: 'Loading runs…',
            ),
          _RunHistoryPhase.error => _ErrorView(
              message: _errorMessage ?? 'Something went wrong.',
              onRetry: _load,
            ),
          _RunHistoryPhase.ready => _ReadyView(
              experiment: widget.experiment,
              runs: _runs,
              sort: _sort,
              onSortChanged: (mode) => setState(() => _sort = mode),
              onBack: () => Navigator.of(context).maybePop(),
              onOpenRun: _openRun,
            ),
        },
      ),
    );
  }
}

/// The loaded screen: top-bar back, eyebrow + serif name, then either an empty
/// state or the sort toggle over the list of run cards.
class _ReadyView extends StatelessWidget {
  final SchemaExperiment experiment;
  final List<SchemaRun> runs;
  final RunSortMode sort;
  final ValueChanged<RunSortMode> onSortChanged;
  final VoidCallback onBack;
  final void Function(SchemaRun run, int number, bool isBest) onOpenRun;

  const _ReadyView({
    required this.experiment,
    required this.runs,
    required this.sort,
    required this.onSortChanged,
    required this.onBack,
    required this.onOpenRun,
  });

  @override
  Widget build(BuildContext context) {
    final outcomes = experiment.outcomes ?? const [];
    final name = experiment.name?.isNotEmpty == true
        ? experiment.name!
        : 'Untitled experiment';

    // Chronological numbering: oldest run is "Run 1".
    final chrono = [...runs]
      ..sort((a, b) => _whenOf(a).compareTo(_whenOf(b)));
    final numberOf = <String, int>{};
    for (var i = 0; i < chrono.length; i++) {
      numberOf[chrono[i].id] = i + 1;
    }

    // Best run = highest final rating.
    String? bestId;
    var bestScore = double.negativeInfinity;
    for (final r in runs) {
      final s = r.finalRating(outcomes);
      if (s > bestScore) {
        bestScore = s;
        bestId = r.id;
      }
    }

    // Apply the selected ordering.
    final ordered = [...runs]..sort((a, b) {
        if (sort == RunSortMode.rated) {
          final d = b.finalRating(outcomes).compareTo(a.finalRating(outcomes));
          if (d != 0) return d;
        }
        return _whenOf(b).compareTo(_whenOf(a));
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: back.
          Row(
            children: [
              MixMaxRoundButton(
                glyph: MixMaxGlyph.arrowLeft,
                onTap: onBack,
              ),
            ],
          ),

          const SizedBox(height: 18),
          const EyebrowText(text: 'Run history', color: AppColors.gold),
          const SizedBox(height: 8),
          DisplayText(
            text: name,
            fontSize: 34,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (runs.isEmpty)
            const _EmptyState()
          else ...[
            const SizedBox(height: 22),
            RunSortToggle(value: sort, onChanged: onSortChanged),
            const SizedBox(height: 16),
            for (var i = 0; i < ordered.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              RunHistoryCard(
                experiment: experiment,
                run: ordered[i],
                number: numberOf[ordered[i].id] ?? (i + 1),
                isBest: ordered[i].id == bestId,
                onOpen: () => onOpenRun(
                  ordered[i],
                  numberOf[ordered[i].id] ?? (i + 1),
                  ordered[i].id == bestId,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  int _whenOf(SchemaRun r) => r.completedAt ?? r.createdAt ?? 0;
}

/// The "no runs yet" placeholder (source: `screens.jsx` `RunHistoryScreen`
/// empty branch): a centered gold clock tile, a serif title and a soft nudge.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 56, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          MixMaxTile(
            glyph: MixMaxGlyph.clock,
            tone: MixMaxTileTone.gold,
            size: 64,
            radius: 20,
          ),
          SizedBox(height: 18),
          TitleText(text: 'No runs yet', fontSize: 22, textAlign: TextAlign.center),
          SizedBox(height: 6),
          BodyText(
            text:
                "Run the experiment and record your outcomes — they'll show up here.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A centered spinner + caption — the loading state.
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

/// The error state: the message and a retry button.
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
          BodyText(
            text: message,
            color: AppColors.danger,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          MixMaxButton(
            label: 'Try again',
            variant: MixMaxButtonVariant.ink,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
