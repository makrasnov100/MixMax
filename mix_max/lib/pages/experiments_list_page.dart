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
import 'package:mix_max/widgets/pages/experiments_list/create_experiment_drawer.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
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

  /// Prompts for a name first. Nothing is persisted until the user saves —
  /// dismissing the drawer creates no experiment.
  void _addExperiment() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CreateExperimentDrawer(
        onSave: _createExperiment,
      ),
    );
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
                // Editorial masthead — stays fixed above the scrolling list.
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
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
