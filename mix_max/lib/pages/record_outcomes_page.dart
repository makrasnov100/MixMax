import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/ui/navigation_service.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/drawer_container.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/inputs/text_input.dart';
import 'package:mix_max/widgets/design/atoms/progress_dots.dart';
import 'package:mix_max/widgets/design/atoms/round_button.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/molecules/confirm_drawer.dart';
import 'package:mix_max/widgets/design/ions/format.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/display_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';
import 'package:mix_max/widgets/design/molecules/slider_field.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';

enum _RecordPhase { recording, saving, error }

/// The second half of running an iteration. By the time this page opens the
/// [run] already exists in the database (with its parameter values); here the
/// user walks through each outcome and rates what the experiment yielded. The
/// "Next outcome" button advances through the outcomes; on the last one "Save
/// run" writes the measured values, marks the run complete, and returns to the
/// experiment details.
///
/// In [rescore] mode the run is already complete: the same flow re-opens with
/// each step seeded from the run's recorded value, walks the run's own outcome
/// snapshot (so it rescores exactly what was measured), and on the last step
/// saves the new ratings back in place — leaving the run count untouched and
/// returning to the Run Details page it was launched from.
class RecordOutcomesPage extends StatefulWidget {
  final SchemaExperiment experiment;
  final SchemaRun run;

  /// When true, edit an already-recorded run's outcome ratings instead of
  /// recording a fresh run.
  final bool rescore;

  const RecordOutcomesPage({
    super.key,
    required this.experiment,
    required this.run,
    this.rescore = false,
  });

  @override
  State<RecordOutcomesPage> createState() => _RecordOutcomesPageState();
}

class _RecordOutcomesPageState extends State<RecordOutcomesPage> {
  _RecordPhase _phase = _RecordPhase.recording;
  String? _errorMessage;

  final Map<String, double> _outcomeValues = {};
  int _currentOutcomeIndex = 0;

  /// The outcomes being rated. A rescore walks the run's own captured snapshot
  /// (what it was actually measured with); a fresh run uses the experiment's
  /// current outcomes.
  List<SchemaOutcome> get _outcomes => widget.rescore
      ? (widget.run.outcomes ?? widget.experiment.outcomes ?? const [])
      : (widget.experiment.outcomes ?? const []);

  @override
  void initState() {
    super.initState();
    // Seed a rescore with the run's existing ratings so each step opens on the
    // value it currently holds.
    if (widget.rescore) {
      final existing = widget.run.outcomeValues;
      if (existing != null) _outcomeValues.addAll(existing);
    }
  }

  void _onOutcomeValueSubmitted(SchemaOutcome outcome, double value) {
    _outcomeValues[outcome.id] = value;

    if (_currentOutcomeIndex + 1 >= _outcomes.length) {
      _saveRun();
      return;
    }

    setState(() => _currentOutcomeIndex += 1);
  }

  /// The single back path for both the in-app arrow and the system back gesture
  /// (routed here via the [PopScope] in [build]). Stepping back through outcomes
  /// just rewinds the index — no data is lost, so no prompt. Backing out of the
  /// first outcome leaves the whole flow, returning to the experiment details
  /// and skipping past the suggested-run page; since that drops the suggested
  /// run entirely (its parameters and any ratings), we always confirm first.
  Future<void> _handleBackRequest() async {
    if (_currentOutcomeIndex > 0) {
      setState(() => _currentOutcomeIndex -= 1);
      return;
    }

    // A rescore only abandons unsaved edits to an existing run; a fresh run is
    // discarded entirely (its suggested values and ratings).
    final discard = await ConfirmDrawer.show(
      context,
      title: widget.rescore ? 'Discard changes?' : 'Discard this run?',
      subtitle: widget.rescore
          ? "Your new ratings won't be saved."
          : "Suggested values and any outcomes won't be saved.",
      confirmLabel: 'Discard',
      cancelLabel: 'Keep rating',
    );
    if (!discard) return;

    if (!mounted) return;
    if (widget.rescore) {
      // Back to the Run Details page this rescore was launched from. Imperative
      // pop (not maybePop) so [PopScope] doesn't re-route into this handler.
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).popUntil(
      (route) => route.settings.name == Destination.experimentDetails.name,
    );
  }

  Future<void> _saveRun() async {
    setState(() {
      _phase = _RecordPhase.saving;
      _errorMessage = null;
    });

    final run = widget.run;
    run.outcomeValues = Map<String, double>.from(_outcomeValues);
    // Freeze the combined rating onto the document so the highest scoring run
    // can be found by an indexed query (e.g. to re-crown the best run later).
    run.finalRating = run.computeFinalRating();

    try {
      if (widget.rescore) {
        await DatabaseService.runsRef
            .doc(run.id)
            .set(run, SetOptions(merge: true));

        // Re-evaluate the cached best run against the new rating.
        await widget.experiment.applyRescoredRun(run);

        if (!mounted) return;
        // Back to the Run Details page this rescore was launched from. Use an
        // imperative pop (not maybePop) so the [PopScope] below doesn't treat
        // this as a blocked back gesture and re-prompt to discard changes.
        Navigator.of(context).pop();
        return;
      }

      run.completedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await DatabaseService.runsRef
          .doc(run.id)
          .set(run, SetOptions(merge: true));

      await widget.experiment.recordCompletedRun(run);

      if (!mounted) return;
      // Pop back past the suggested-run page to the experiment details.
      Navigator.of(context).popUntil(
        (route) => route.settings.name == Destination.experimentDetails.name,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _RecordPhase.recording;
        _errorMessage = widget.rescore
            ? 'Could not save changes. Please try again.'
            : 'Could not save run. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always intercept the system back / swipe: the default pop would land on
    // the suggested-run page, but back from here belongs to [_handleBackRequest]
    // (rewind an outcome, or leave to the experiment details), matching the
    // in-app arrow.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackRequest();
      },
      child: OrientationScaffold(
        body: ColoredBox(
          color: AppColors.bg,
          child: switch (_phase) {
            _RecordPhase.saving => _StatusView(
              message: widget.rescore ? 'Saving changes…' : 'Saving run…',
            ),
            _RecordPhase.error => _ErrorView(
              message: _errorMessage ?? 'Something went wrong.',
              onRetry: () => setState(() => _phase = _RecordPhase.recording),
            ),
            _RecordPhase.recording => _RecordingView(
              outcomes: _outcomes,
              rescore: widget.rescore,
              currentIndex: _currentOutcomeIndex,
              existingValue:
                  _outcomeValues[_outcomes[_currentOutcomeIndex].id],
              errorMessage: _errorMessage,
              onSubmit: _onOutcomeValueSubmitted,
              onBack: _handleBackRequest,
            ),
          },
        ),
      ),
    );
  }
}

/// One outcome's rating step: the top bar (back, progress, "X of Y"), the
/// centered outcome header with its goal pill, the big serif value readout, and
/// either a [MixMaxSliderField] (bounded outcome) or a number field (unbounded)
/// over a sticky next/save footer.
class _RecordingView extends StatefulWidget {
  final List<SchemaOutcome> outcomes;
  final bool rescore;
  final int currentIndex;
  final double? existingValue;
  final String? errorMessage;
  final void Function(SchemaOutcome outcome, double value) onSubmit;
  final VoidCallback onBack;

  const _RecordingView({
    required this.outcomes,
    required this.rescore,
    required this.currentIndex,
    required this.existingValue,
    required this.errorMessage,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<_RecordingView> createState() => _RecordingViewState();
}

class _RecordingViewState extends State<_RecordingView> {
  late TextEditingController _textController;
  late double _sliderValue;

  SchemaOutcome get _outcome => widget.outcomes[widget.currentIndex];

  bool get _hasBounds =>
      _outcome.min != null &&
      _outcome.max != null &&
      _outcome.max! > _outcome.min!;

  double get _sliderMin => _outcome.min ?? 0.0;
  double get _sliderMax => _outcome.max ?? 1.0;

  double get _increment {
    final raw = _outcome.step;
    if (raw == null || raw <= 0) return 1.0;
    return raw;
  }

  double _snapToIncrement(double v) {
    final range = _sliderMax - _sliderMin;
    if (range <= 0) return _sliderMin;
    final increments = ((v - _sliderMin) / _increment).round();
    final snapped = _sliderMin + increments * _increment;
    return snapped.clamp(_sliderMin, _sliderMax);
  }

  @override
  void initState() {
    super.initState();
    _initFromOutcome();
  }

  @override
  void didUpdateWidget(covariant _RecordingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _initFromOutcome();
    }
  }

  void _initFromOutcome() {
    final initial = widget.existingValue;
    if (_hasBounds) {
      final mid = (_sliderMin + _sliderMax) / 2;
      final raw = (initial ?? mid).clamp(_sliderMin, _sliderMax);
      _sliderValue = _snapToIncrement(raw);
    } else {
      _sliderValue = _sliderMin;
    }
    _textController = TextEditingController(
      text: initial != null ? MixMaxFormat.number(initial, decimals: 4) : '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_hasBounds) {
      // The slider always holds a valid value (it opens at the midpoint), so a
      // bounded outcome is submittable as-is — no need to drag it first.
      widget.onSubmit(_outcome, _snapToIncrement(_sliderValue));
      return;
    }

    final parsed = double.tryParse(_textController.text.trim());
    if (parsed == null) return;
    widget.onSubmit(_outcome, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final outcomes = widget.outcomes;
    final isLast = widget.currentIndex == outcomes.length - 1;
    final canSubmit =
        _hasBounds
            ? true
            : double.tryParse(_textController.text.trim()) != null;

    final name = _outcome.name?.isNotEmpty == true ? _outcome.name! : 'Outcome';
    final unit = _outcome.unit ?? '';
    final guide = _outcome.description?.trim() ?? '';
    final hasGuide = guide.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar: back · progress · counter.
              Row(
                children: [
                  MixMaxRoundButton(
                    glyph: MixMaxGlyph.arrowLeft,
                    onTap: widget.onBack,
                  ),
                  const SizedBox(width: 14),
                  MixMaxProgressDots(
                    total: outcomes.length,
                    index: widget.currentIndex,
                  ),
                  const Spacer(),
                  CaptionText(
                    text:
                        '${widget.rescore ? 'Rescore · ' : ''}Outcome '
                        '${widget.currentIndex + 1} of ${outcomes.length}',
                  ),
                ],
              ),

              // Centered outcome header.
              const SizedBox(height: 30),
              const Center(
                child: MixMaxTile(
                  glyph: MixMaxGlyph.target,
                  tone: MixMaxTileTone.violet,
                  size: 52,
                  radius: 16,
                ),
              ),
              const SizedBox(height: 16),
              DisplayText(
                text: name,
                fontSize: 40,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _GoalPill(outcome: _outcome),

              // The grading guide, when the outcome carries one. The value
              // and slider gaps tighten to make room for it.
              if (hasGuide) ...[
                const SizedBox(height: 16),
                _RatingGuide(text: guide, outcomeName: name),
              ],

              // Value + input.
              SizedBox(height: hasGuide ? 26 : (_hasBounds ? 40 : 36)),
              if (_hasBounds) ...[
                _ValueReadout(
                  value: MixMaxFormat.number(_sliderValue, decimals: 4),
                  unit: unit,
                ),
                SizedBox(height: hasGuide ? 30 : 40),
                MixMaxSliderField(
                  value: _sliderValue,
                  min: _sliderMin,
                  max: _sliderMax,
                  increment: _increment,
                  onChanged: (v) {
                    setState(() => _sliderValue = _snapToIncrement(v));
                  },
                ),
              ] else
                _NumberEntry(
                  controller: _textController,
                  unit: unit,
                  onChanged: (_) => setState(() {}),
                ),

              if (widget.errorMessage != null) ...[
                const SizedBox(height: 18),
                BodyText(
                  text: widget.errorMessage!,
                  color: AppColors.danger,
                  fontSize: 13,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        // Sticky next/save footer over a bg fade.
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
              label: isLast
                  ? (widget.rescore ? 'Save changes' : 'Save run')
                  : 'Next outcome',
              variant:
                  isLast ? MixMaxButtonVariant.gold : MixMaxButtonVariant.ink,
              enabled: canSubmit,
              onPressed: canSubmit ? _submit : null,
              trailing: MixMaxIcon(
                isLast ? MixMaxGlyph.check : MixMaxGlyph.arrowRight,
                size: 20,
                color: canSubmit ? Colors.white : AppColors.inkFaint,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The big serif value readout — the rated number with an optional smaller unit.
///
/// Source: `screens.jsx` `RatingScreen` (serif 84 with a 30px soft-ink unit).
class _ValueReadout extends StatelessWidget {
  final String value;
  final String unit;

  const _ValueReadout({required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: value,
        style: DisplayText.styleOf(fontSize: 84),
        children: [
          if (unit.isNotEmpty)
            TextSpan(
              text: ' $unit',
              style: DisplayText.styleOf(
                fontSize: 30,
                color: AppColors.inkSoft,
              ),
            ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// The maximize / minimize hint pill beneath the outcome name. Gold-tinted for
/// "higher is better", violet-tinted for "lower is better"; nothing when the
/// outcome has no goal.
///
/// Source: `screens.jsx` `RatingScreen` goal pill.
class _GoalPill extends StatelessWidget {
  final SchemaOutcome outcome;

  const _GoalPill({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final goal = outcome.goal;
    if (goal != OutcomeGoal.maximize && goal != OutcomeGoal.minimize) {
      return const SizedBox(height: 0);
    }
    final maxi = goal == OutcomeGoal.maximize;
    final fg = maxi ? AppColors.goldText : AppColors.violetText;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: maxi ? AppColors.goldTint : AppColors.violetTint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MixMaxIcon(
              maxi ? MixMaxGlyph.up : MixMaxGlyph.down,
              size: 15,
              color: fg,
            ),
            const SizedBox(width: 6),
            CaptionText(
              text: maxi ? 'higher is better' : 'lower is better',
              fontSize: 13,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}

/// The outcome's grading guide, shown while rating so scores stay consistent.
/// Clamped to 3 lines in place; "Show more" opens a bottom drawer with the
/// full text, so the value + slider never get pushed out of view.
///
/// Source: `screens.jsx` `RatingScreen` `RatingGuide` (the inline alert): a
/// hairline `surface` card with a violet info glyph, sans-13 soft-ink copy,
/// and a violet "Show more" link that only renders when the text overflows.
class _RatingGuide extends StatelessWidget {
  final String text;
  final String outcomeName;

  const _RatingGuide({required this.text, required this.outcomeName});

  static const int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final style = BodyText.styleOf(fontSize: 13);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: MixMaxIcon(
              MixMaxGlyph.info,
              size: 15,
              color: AppColors.violetText,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            // Measure whether the guide overflows its 3-line clamp at this
            // exact width so "Show more" only appears when there's more.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final painter = TextPainter(
                  text: TextSpan(text: text, style: style),
                  maxLines: _maxLines,
                  textDirection: TextDirection.ltr,
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout(maxWidth: constraints.maxWidth);
                final clamped = painter.didExceedMaxLines;
                painter.dispose();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: style,
                      maxLines: _maxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (clamped)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _RatingGuideDrawer.show(
                          context,
                          outcomeName: outcomeName,
                          text: text,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: BodyText(
                            text: 'Show more',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.violetText,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The "How to rate" bottom drawer with an outcome's full grading guide.
///
/// Source: `screens.jsx` `RatingGuide` (the `DrawerShell` it opens): a
/// centered serif "How to rate" title over the outcome's name, then the
/// untruncated guide as relaxed reading copy.
class _RatingGuideDrawer extends StatelessWidget {
  final String outcomeName;
  final String text;

  const _RatingGuideDrawer({required this.outcomeName, required this.text});

  static Future<void> show(
    BuildContext context, {
    required String outcomeName,
    required String text,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RatingGuideDrawer(outcomeName: outcomeName, text: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MixMaxDrawerContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered serif title + soft subtitle. DrawerShell padding
          // '14px 24px 4px'.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
            child: Column(
              children: [
                const TitleText(
                  text: 'How to rate',
                  fontSize: 25,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                CaptionText(
                  text: outcomeName,
                  fontSize: 13.5,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: AppFonts.sans,
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The unbounded-outcome fallback: a centered number field for outcomes that
/// carry no min/max to slide between.
class _NumberEntry extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final ValueChanged<String> onChanged;

  const _NumberEntry({
    required this.controller,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: CaptionText(text: 'Enter measured value')),
        const SizedBox(height: 14),
        MixMaxTextInput(
          controller: controller,
          onChanged: onChanged,
          autofocus: true,
          big: true,
          textAlign: TextAlign.center,
          placeholder: unit.isNotEmpty ? 'value ($unit)' : 'value',
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
        ),
      ],
    );
  }
}

/// A centered spinner + caption — the saving state.
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

/// The error state: a danger glyph, the message, and a retry button.
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
