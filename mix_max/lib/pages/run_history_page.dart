import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/pages/run_details_page.dart';
import 'package:mix_max/services/firebase/auth_service.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/services/ui/navigation_service.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/display_text.dart';
import 'package:mix_max/widgets/design/ions/text/eyebrow_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';
import 'package:mix_max/widgets/pages/run_history/run_history_card.dart';
import 'package:mix_max/widgets/pages/run_history/run_sort_toggle.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';
import 'package:mix_max/widgets/wrappers/sticky_top_bar.dart';

/// How many runs are fetched per page as the history list scrolls.
const int _pageSize = 20;

/// The Run History screen — every completed run of an experiment, scored and
/// ordered, reached from the run-count pill on the Experiment Details page.
///
/// Source: `design_app/screens.jsx` `RunHistoryScreen`. The runs are loaded from
/// the Runs collection (the experiment only caches its best run and a count), so
/// this page paginates them 20 at a time via [PagingController]. The user can
/// re-order between "Most recent" (by `completedAt`) and "Highest rated" (by the
/// persisted `finalRating`) via the [RunSortToggle]; both orderings are served
/// straight from indexed queries, and the experiment's cached
/// [SchemaExperiment.bestRun] supplies the gold "best run" highlight without
/// loading every run.
///
/// Tapping a run opens the [RunDetailsPage], carrying whether it is the best run
/// so the details header matches it.
class RunHistoryPage extends StatefulWidget {
  final SchemaExperiment experiment;

  const RunHistoryPage({super.key, required this.experiment});

  @override
  State<RunHistoryPage> createState() => _RunHistoryPageState();
}

class _RunHistoryPageState extends State<RunHistoryPage> {
  late final PagingController<int, SchemaRun> _pagingController;

  /// Cursor for the next page — the last document of the page fetched so far.
  /// Reset to null on [_refresh] so the next fetch starts from the top.
  DocumentSnapshot<SchemaRun>? _lastRunDoc;

  /// Whether the last fetched page was full, i.e. more pages may exist.
  bool _runHasMore = true;

  RunSortMode _sort = RunSortMode.recent;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, SchemaRun>(
      getNextPageKey: (state) => _runHasMore ? state.nextIntPageKey : null,
      fetchPage: _fetchRunsPage,
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  /// The completed runs for this experiment in the currently selected order.
  /// Ordering by `completedAt` / `finalRating` also excludes in-progress runs,
  /// since those documents have neither field set yet.
  Query<SchemaRun> _runsQuery() {
    final userId = getIt<AuthService>().user.id;
    final base = DatabaseService.runsRef
        .where('userId', isEqualTo: userId)
        .where('experimentId', isEqualTo: widget.experiment.id);
    return _sort == RunSortMode.rated
        ? base.orderBy('finalRating', descending: true)
        : base.orderBy('completedAt', descending: true);
  }

  Future<List<SchemaRun>> _fetchRunsPage(int pageKey) async {
    final userId = getIt<AuthService>().user.id;
    if (userId.isEmpty || userId == 'INITIAL') {
      throw StateError('Not signed in yet. Please try again in a moment.');
    }

    Query<SchemaRun> query = _runsQuery().limit(_pageSize);
    if (_lastRunDoc != null) {
      query = query.startAfterDocument(_lastRunDoc!);
    }

    final snapshot = await query.get();
    _runHasMore = snapshot.docs.length == _pageSize;
    if (snapshot.docs.isNotEmpty) _lastRunDoc = snapshot.docs.last;

    return snapshot.docs.map((d) => d.data()).where((r) => r.isValid()).toList();
  }

  /// Restarts pagination from the top — resets the cursor and re-fetches the
  /// first page. Used when the sort changes or a run is edited/deleted.
  void _refresh() {
    _lastRunDoc = null;
    _runHasMore = true;
    _pagingController.refresh();
  }

  void _onSortChanged(RunSortMode mode) {
    if (mode == _sort) return;
    setState(() => _sort = mode);
    _refresh();
  }

  /// Opens the Run Details page for [run], carrying whether it is the
  /// experiment's best run so the details header matches the card the user
  /// tapped. The run may have been rescored or deleted there, so the list is
  /// refreshed on return.
  Future<void> _openRun(SchemaRun run) async {
    final isBest = run.id == widget.experiment.bestRun?.id;
    await Navigation.goTo(
      context: context,
      page: RunDetailsPage(
        experiment: widget.experiment,
        run: run,
        isBest: isBest,
      ),
    );
    if (!mounted) return;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final experiment = widget.experiment;
    final name =
        experiment.name?.isNotEmpty == true
            ? experiment.name!
            : 'Untitled experiment';

    return OrientationScaffold(
      body: ColoredBox(
        color: AppColors.bg,
        child: StickyTopBar(
          onBack: () => Navigator.of(context).maybePop(),
          child: PagingListener<int, SchemaRun>(
            controller: _pagingController,
            builder: (context, state, fetchNextPage) {
              final hasItems = state.items?.isNotEmpty ?? false;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        StickyTopBar.contentInset,
                        20,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EyebrowText(
                            text: 'Run history',
                            color: AppColors.gold,
                          ),
                          const SizedBox(height: 8),
                          DisplayText(
                            text: name,
                            fontSize: 34,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Only offer the ordering toggle once there are runs
                          // to order.
                          if (hasItems) ...[
                            const SizedBox(height: 22),
                            RunSortToggle(value: _sort, onChanged: _onSortChanged),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    sliver: PagedSliverList<int, SchemaRun>.separated(
                      state: state,
                      fetchNextPage: fetchNextPage,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      builderDelegate: PagedChildBuilderDelegate<SchemaRun>(
                        itemBuilder: (context, run, index) {
                          return RunHistoryCard(
                            experiment: experiment,
                            run: run,
                            isBest: run.id == experiment.bestRun?.id,
                            onOpen: () => _openRun(run),
                          );
                        },
                        firstPageProgressIndicatorBuilder:
                            (_) => const _StatusView(message: 'Loading runs…'),
                        firstPageErrorIndicatorBuilder:
                            (_) => _ErrorView(
                              message: 'Could not load run history.',
                              onRetry: _refresh,
                            ),
                        noItemsFoundIndicatorBuilder: (_) => const _EmptyState(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
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
          TitleText(
            text: 'No runs yet',
            fontSize: 22,
            textAlign: TextAlign.center,
          ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 56),
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
      padding: const EdgeInsets.fromLTRB(12, 56, 12, 0),
      child: Column(
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
