import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/services/firebase/auth_service.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/services/ui/navigation_service.dart';
import 'package:mix_max/services/ui/onboarding_service.dart';
import 'package:mix_max/widgets/pages/onboarding/onboarding_controller.dart';
import 'package:mix_max/pages/experiment_details_page.dart';
import 'package:mix_max/services/ui/popup_service.dart';
import 'package:mix_max/widgets/pages/account/account_drawer.dart';
import 'package:mix_max/widgets/pages/account/confirm_delete_account_drawer.dart';
import 'package:mix_max/widgets/pages/experiments_list/create_experiment_drawer.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/progress_overlay.dart';
import 'package:mix_max/widgets/design/atoms/round_button.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/display_text.dart';
import 'package:mix_max/widgets/design/ions/text/eyebrow_text.dart';
import 'package:mix_max/widgets/pages/experiments_list/experiments_list.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';

/// The Experiments list — the app's home screen.
///
/// Source: `design_app/screens.jsx` `ExperimentsListScreen`. A warm-off-white
/// [Screen]-equivalent: a fixed editorial masthead (gold "Mix Max" eyebrow,
/// serif "Experiments" display, soft tagline), the scrollable [ExperimentsList]
/// of cards beneath it, and a sticky gold-fading footer carrying the ink
/// "New experiment" action.
class ExperimentsListPage extends StatefulWidget {
  /// When non-null, the page renders these in-memory experiments instead of the
  /// live Firestore stream — used by the onboarding tour to show its sample
  /// experiment on the real list screen without saving anything.
  final List<SchemaExperiment>? demoExperiments;

  /// Spotlight target handed to the first card during the onboarding tour.
  final Key? spotlightFirstItemKey;

  const ExperimentsListPage({
    super.key,
    this.demoExperiments,
    this.spotlightFirstItemKey,
  });

  bool get isDemo => demoExperiments != null;

  @override
  State<ExperimentsListPage> createState() => _ExperimentsListPageState();
}

class _ExperimentsListPageState extends State<ExperimentsListPage> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = getIt<AuthService>();
    _authService.addListener(_onAuthChanged);
    _maybeStartOnboarding();
  }

  /// On the real home screen (not the tour's demo copy), auto-start the one-time
  /// onboarding tour for a brand-new user once the first frame is laid out.
  void _maybeStartOnboarding() {
    if (widget.isDemo) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (await OnboardingService.shouldShow()) {
        getIt<OnboardingController>().start();
      }
    });
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  /// Gated on having an account: a brand-new user must first choose how to use
  /// the app (guest / Google / Apple) in the account drawer — closing it
  /// without choosing goes nowhere. Once an account exists this prompts for a
  /// name; nothing is persisted until the user saves.
  Future<void> _addExperiment() async {
    if (!_authService.hasAccount) {
      final result = await AccountDrawer.show(context);
      if (!mounted || result != AccountDrawerResult.chose) return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CreateExperimentDrawer(
        onSave: _createExperiment,
      ),
    );
  }

  /// The masthead account button — the same drawer as the create gate, but its
  /// dismissal needs no follow-up except the delete-account confirm flow.
  Future<void> _openAccount() async {
    final result = await AccountDrawer.show(context);
    if (!mounted) return;
    if (result == AccountDrawerResult.deleteRequested) {
      await _confirmDeleteAccount();
    }
  }

  /// Shows the destructive confirm (with a live experiment count). "Keep my
  /// account" returns to the account drawer, like the design; confirming runs
  /// the cloud deletion and drops the session back to the unchosen state.
  Future<void> _confirmDeleteAccount() async {
    final count = await _countExperiments();
    if (!mounted) return;

    final confirmed = await ConfirmDeleteAccountDrawer.show(
      context,
      experimentCount: count,
    );
    if (!mounted) return;

    if (!confirmed) {
      await _openAccount();
      return;
    }

    // A full-screen blocking overlay (matching the sign-in flows), then a
    // result toast once the cloud call settles.
    final result = await MixMaxProgressOverlay.during(
      context: context,
      message: 'Deleting your account…',
      operation: _authService.deleteAccount,
    );
    if (!mounted) return;

    PopupService.showResultToast(
      message: result.success
          ? '✅ Your account and data have been deleted.'
          : '❌ Could not delete your account. Please try again later.',
      backgroundColor: result.success ? AppColors.addGreen : AppColors.dangerRed,
    );
  }

  Future<int> _countExperiments() async {
    try {
      final aggregate = await DatabaseService.experimentsRef
          .where('userId', isEqualTo: _authService.user.id)
          .count()
          .get();
      return aggregate.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _createExperiment(String name) async {
    final userId = _authService.user.id;
    final experiment = SchemaExperiment(
      id: DatabaseService.experimentsRef.doc().id,
      userId: userId,
      name: name,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    await experiment.save();

    if (!mounted) return;
    Navigation.goTo(
      context: context,
      page: ExperimentDetailsPage(experiment: experiment),
    );
  }

  void _openExperiment(SchemaExperiment experiment) {
    Navigation.goTo(
      context: context,
      page: ExperimentDetailsPage(experiment: experiment),
    );
  }

  Stream<QuerySnapshot<SchemaExperiment>>? _experimentsStream() {
    final userId = _authService.user.id;
    if (userId.isEmpty || userId == 'INITIAL') {
      return null;
    }
    return DatabaseService.experimentsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.isDemo ? null : _experimentsStream();

    return OrientationScaffold(
      body: ColoredBox(
        color: AppColors.bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editorial masthead — stays fixed above the scrolling list,
                // with the round account trigger sitting opposite the title
                // (screens.jsx ExperimentsListScreen header row).
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EyebrowText(text: 'Mix Max', color: AppColors.gold),
                            SizedBox(height: 8),
                            DisplayText(text: 'Experiments', fontSize: 40),
                            SizedBox(height: 10),
                            BodyText(
                              text: 'Find the best version of anything.',
                              fontSize: 14.5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: MixMaxRoundButton(
                          glyph: MixMaxGlyph.user,
                          onTap: _openAccount,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildList(stream)),
              ],
            ),

            // Sticky footer action over a gold-into-bg fade.
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
                    stops: [0.0, 0.22],
                  ),
                ),
                child: MixMaxButton(
                  label: 'New experiment',
                  variant: MixMaxButtonVariant.ink,
                  leading: const MixMaxIcon(
                    MixMaxGlyph.plus,
                    size: 20,
                    color: Colors.white,
                  ),
                  onPressed: _addExperiment,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Resolves the body for the current auth / stream state: a sign-in hint
  /// while the user resolves, then the live experiment list.
  Widget _buildList(Stream<QuerySnapshot<SchemaExperiment>>? stream) {
    // Onboarding tour: render the in-memory sample experiment directly.
    if (widget.isDemo) {
      return ExperimentsList(
        experiments: widget.demoExperiments!,
        onOpen: (_) {},
        firstItemKey: widget.spotlightFirstItemKey,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
      );
    }

    if (stream == null) {
      // Signed out entirely (no account chosen yet): show the regular empty
      // state — the gate on "New experiment" handles the choice.
      if (!_authService.hasAccount && !_authService.isLoading) {
        return ExperimentsList(
          experiments: const [],
          onOpen: (_) {},
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        );
      }
      return const Center(
        child: BodyText(
          text: 'Signing you in…',
          textAlign: TextAlign.center,
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<SchemaExperiment>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: BodyText(
                text: 'Could not load experiments.',
                color: AppColors.danger,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        }

        final experiments = (snapshot.data?.docs ?? [])
            .map((d) => d.data())
            .where((e) => e.isValid())
            .toList();

        // Leave room at the bottom for the floating footer button.
        return ExperimentsList(
          experiments: experiments,
          onOpen: _openExperiment,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        );
      },
    );
  }
}
