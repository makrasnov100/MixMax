/// One step of the onboarding tour: the explainer copy shown in the bottom card
/// while a particular part of a real screen is spotlit.
///
/// The screen each step lives on, and which widget it highlights, is owned by
/// `OnboardingController` (it holds the spotlight keys and drives navigation) —
/// this file is just the human-facing script.
class OnboardingStep {
  /// Tiny gold kicker above the title (e.g. "The idea").
  final String eyebrow;

  /// Serif heading of the explainer card.
  final String title;

  /// One or two sentences explaining what is highlighted.
  final String body;

  const OnboardingStep({
    required this.eyebrow,
    required this.title,
    required this.body,
  });
}

/// The six-step script, in order. Indices line up with the controller's step
/// index and spotlight targets:
///   0 → an experiment card on the list
///   1 → the Parameters card on details
///   2 → the Outcomes card on details
///   3 → the "Run experiment" button on details
///   4 → the suggested next run
///   5 → the "Best mix so far" banner
const List<OnboardingStep> onboardingSteps = [
  OnboardingStep(
    eyebrow: 'The idea',
    title: 'Start with an experiment',
    body:
        'An experiment is one thing you want to perfect, like this cold brew '
        'coffee. Everything you tune and measure lives inside it.',
  ),
  OnboardingStep(
    eyebrow: 'Step 1 · Parameters',
    title: 'Set the knobs to tune',
    body:
        'Parameters are the inputs you can change, like grams of coffee or '
        'hours of steeping. Mix Max decides what to try next for each one.',
  ),
  OnboardingStep(
    eyebrow: 'Step 2 · Outcomes',
    title: 'Choose what to measure',
    body:
        'Outcomes are how you score a batch. Stronger is better, bitter is '
        'worse. After each run you rate these so Mix Max learns what "good" means.',
  ),
  OnboardingStep(
    eyebrow: 'Step 3 · Run',
    title: 'Start a new run',
    body:
        'When your knobs and measures are set, tap "Run experiment" here to '
        'kick off the next batch. This is how you start every run.',
  ),
  OnboardingStep(
    eyebrow: 'Step 4 · Suggested',
    title: 'Get a smart next batch',
    body:
        'Mix Max suggests the exact parameters to try next, picked from '
        'everything your past runs have taught it. You may tweak any value to '
        'your liking.',
  ),
  OnboardingStep(
    eyebrow: 'The payoff',
    title: 'Watch your best mix rise',
    body:
        'As you record runs, the highest scoring one is crowned here. This is '
        'your best mix so far, and it keeps getting better. You\'re ready!',
  ),
];
