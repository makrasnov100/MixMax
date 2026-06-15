import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/pages/experiment_details_page.dart';
import 'package:mix_max/pages/experiments_list_page.dart';
import 'package:mix_max/pages/suggested_run_page.dart';
import 'package:mix_max/services/ui/navigation_service.dart';
import 'package:mix_max/services/ui/onboarding_service.dart';
import 'package:mix_max/widgets/pages/onboarding/onboarding_demo_data.dart';
import 'package:mix_max/widgets/pages/onboarding/onboarding_steps.dart';

/// Drives the first-launch onboarding tour.
///
/// The tour pushes a stack of the *real* app screens — fed the in-memory
/// [OnboardingDemoData] experiment — and overlays a dim + spotlight + explainer
/// card (see `OnboardingOverlay`, mounted via `MaterialApp.builder`). The app
/// underneath is non-interactive; the explainer's "Next" calls [next], which
/// performs the navigation / scrolling for the upcoming step itself.
///
/// Registered as a get_it singleton so both the overlay host and the home page
/// (which starts the tour) share one instance.
class OnboardingController extends ChangeNotifier {
  /// Whether the tour is currently running (drives the overlay's visibility).
  bool active = false;

  /// Zero-based index into [onboardingSteps] / the spotlight targets, 0–5.
  int step = 0;

  int get totalSteps => onboardingSteps.length;
  bool get isLastStep => step >= totalSteps - 1;
  OnboardingStep get currentStep => onboardingSteps[step];

  late SchemaExperiment _demo;
  SchemaExperiment get demo => _demo;
  Map<String, dynamic> get suggestion => OnboardingDemoData.suggestion;

  // Spotlight targets. Each is handed to the real page that owns the highlighted
  // widget (via a constructor param) and wrapped around that widget, so the
  // overlay can read the widget's on-screen rect to cut its spotlight hole.
  final GlobalKey listItemKey = GlobalKey(debugLabel: 'onboarding-list-item');
  final GlobalKey parametersKey = GlobalKey(debugLabel: 'onboarding-parameters');
  final GlobalKey outcomesKey = GlobalKey(debugLabel: 'onboarding-outcomes');
  final GlobalKey runButtonKey = GlobalKey(debugLabel: 'onboarding-run-button');
  final GlobalKey tryTheseKey = GlobalKey(debugLabel: 'onboarding-try-these');
  final GlobalKey bestMixKey = GlobalKey(debugLabel: 'onboarding-best-mix');

  /// The spotlight key for the current step, or null if the step has no target.
  GlobalKey? get currentTargetKey {
    switch (step) {
      case 0:
        return listItemKey;
      case 1:
        return parametersKey;
      case 2:
        return outcomesKey;
      case 3:
        return runButtonKey;
      case 4:
        return tryTheseKey;
      case 5:
        return bestMixKey;
      default:
        return null;
    }
  }

  NavigatorState? get _navigator => Navigation.navigatorKey.currentState;

  /// Begins the tour: builds fresh demo data, marks the tour seen (so it never
  /// auto-starts again, even if abandoned), and pushes the demo experiments
  /// list as step 0.
  void start() {
    if (active) return;
    _demo = OnboardingDemoData.experiment();
    active = true;
    step = 0;
    OnboardingService.markSeen();
    notifyListeners();

    final navigator = _navigator;
    if (navigator == null) return;
    navigator.push(_route(
      ExperimentsListPage(
        demoExperiments: [_demo],
        spotlightFirstItemKey: listItemKey,
      ),
    ));
    _settle();
  }

  /// Advances to the next step, performing its navigation / scrolling. On the
  /// last step this finishes the tour instead.
  void next() {
    if (!active) return;
    if (isLastStep) {
      finish();
      return;
    }

    step += 1;
    notifyListeners();

    switch (step) {
      case 1: // Parameters — open the demo experiment's details.
        _navigator?.push(_route(ExperimentDetailsPage(
          experiment: _demo,
          parametersKey: parametersKey,
          outcomesKey: outcomesKey,
          runButtonKey: runButtonKey,
          bestMixKey: bestMixKey,
        )));
        break;
      case 2: // Outcomes — same page, scroll them into view.
        break;
      case 3: // Run experiment — same page, spotlight the footer button.
        break;
      case 4: // Suggested run — push the real suggested-run screen.
        _navigator?.push(_route(SuggestedRunPage(
          experiment: _demo,
          demoSuggestion: suggestion,
          spotlightKey: tryTheseKey,
        )));
        break;
      case 5: // Best mix — pop back to details and scroll to the banner.
        _navigator?.pop();
        break;
    }

    _settle();
  }

  /// Ends the tour, removing the overlay and popping every screen the tour
  /// pushed so the user lands back on their real (empty) experiments list.
  void finish() {
    if (!active) return;
    active = false;
    notifyListeners();
    _navigator?.popUntil((route) => route.isFirst);
  }

  /// After a navigation, scrolls the current target into view (alignment biased
  /// toward the top so the bottom explainer card never covers it) and repaints
  /// the overlay. Runs once on the next frame and again after the route
  /// transition settles, since scrolling mid-transition can land on the wrong
  /// offset.
  void _settle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTarget();
      notifyListeners();
    });
    Future.delayed(const Duration(milliseconds: 380), _scrollToTarget);
  }

  void _scrollToTarget() {
    if (!active) return;
    final context = currentTargetKey?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.18,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  MaterialPageRoute _route(Widget page) => MaterialPageRoute(builder: (_) => page);
}
