import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/ui/navigation_service.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/inputs/text_input.dart';
import 'package:mix_max/widgets/design/atoms/progress_dots.dart';
import 'package:mix_max/widgets/design/atoms/round_button.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/molecules/confirm_drawer.dart';
import 'package:mix_max/widgets/design/ions/format.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/display_text.dart';
import 'package:mix_max/widgets/design/molecules/slider_field.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';

enum _RecordPhase { recording, saving, error }

/// The second half of running an iteration. By the time this page opens the
/// [run] already exists in the database (with its parameter values); here the
/// user walks through each outcome and rates what the experiment yielded. The
/// "Next outcome" button advances through the outcomes; on the last one "Save
/// run" writes the measured values, marks the run complete, and returns to the
/// experiment details.
class RecordOutcomesPage extends StatefulWidget {
  final SchemaExperiment experiment;
  final SchemaRun run;

  const RecordOutcomesPage({
    super.key,
    required this.experiment,
    required this.run,
  });

  @override
  State<RecordOutcomesPage> createState() => _RecordOutcomesPageState();
}

class _RecordOutcomesPageState extends State<RecordOutcomesPage> {
  _RecordPhase _phase = _RecordPhase.recording;
  String? _errorMessage;

  final Map<String, double> _outcomeValues = {};
  int _currentOutcomeIndex = 0;

  void _onOutcomeValueSubmitted(SchemaOutcome outcome, double value) {
    _outcomeValues[outcome.id] = value;

    final outcomes = widget.experiment.outcomes ?? [];
    if (_currentOutcomeIndex + 1 >= outcomes.length) {
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

    final discard = await ConfirmDrawer.show(
      context,
      title: 'Discard this run?',
      subtitle: "Suggested values and any outcomes won't be saved.",
      confirmLabel: 'Discard',
      cancelLabel: 'Keep rating',
    );
    if (!discard) return;

    if (!mounted) return;
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
    run.completedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      await DatabaseService.runsRef
          .doc(run.id)
          .set(run, SetOptions(merge: true));
      if (!mounted) return;
      // Pop back past the suggested-run page to the experiment details.
      Navigator.of(context).popUntil(
        (route) => route.settings.name == Destination.experimentDetails.name,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _RecordPhase.recording;
        _errorMessage = 'Could not save run. Please try again.';
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
            _RecordPhase.saving => const _StatusView(message: 'Saving run…'),
            _RecordPhase.error => _ErrorView(
              message: _errorMessage ?? 'Something went wrong.',
              onRetry: () => setState(() => _phase = _RecordPhase.recording),
            ),
            _RecordPhase.recording => _RecordingView(
              experiment: widget.experiment,
              currentIndex: _currentOutcomeIndex,
              existingValue:
                  _outcomeValues[widget
                      .experiment
                      .outcomes![_currentOutcomeIndex]
                      .id],
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
  final SchemaExperiment experiment;
  final int currentIndex;
  final double? existingValue;
  final String? errorMessage;
  final void Function(SchemaOutcome outcome, double value) onSubmit;
  final VoidCallback onBack;

  const _RecordingView({
    required this.experiment,
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

  SchemaOutcome get _outcome =>
      widget.experiment.outcomes![widget.currentIndex];

  bool get _hasBounds =>
      _outcome.min != null &&
      _outcome.max != null &&
      _outcome.max! > _outcome.min!;

  double get _sliderMin => _outcome.min ?? 0.0;
  double get _sliderMax => _outcome.max ?? 1.0;

  double get _step {
    final raw = _outcome.step;
    if (raw == null || raw <= 0) return 1.0;
    return raw;
  }

  double _snapToStep(double v) {
    final range = _sliderMax - _sliderMin;
    if (range <= 0) return _sliderMin;
    final steps = ((v - _sliderMin) / _step).round();
    final snapped = _sliderMin + steps * _step;
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
      _sliderValue = _snapToStep(raw);
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
      widget.onSubmit(_outcome, _snapToStep(_sliderValue));
      return;
    }

    final parsed = double.tryParse(_textController.text.trim());
    if (parsed == null) return;
    widget.onSubmit(_outcome, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final outcomes = widget.experiment.outcomes ?? [];
    final isLast = widget.currentIndex == outcomes.length - 1;
    final canSubmit =
        _hasBounds
            ? true
            : double.tryParse(_textController.text.trim()) != null;

    final name = _outcome.name?.isNotEmpty == true ? _outcome.name! : 'Outcome';
    final unit = _outcome.unit ?? '';

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
                        'Outcome ${widget.currentIndex + 1} of ${outcomes.length}',
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

              // Value + input.
              SizedBox(height: _hasBounds ? 40 : 36),
              if (_hasBounds) ...[
                _ValueReadout(
                  value: MixMaxFormat.number(_sliderValue, decimals: 4),
                  unit: unit,
                ),
                const SizedBox(height: 40),
                MixMaxSliderField(
                  value: _sliderValue,
                  min: _sliderMin,
                  max: _sliderMax,
                  step: _step,
                  onChanged: (v) {
                    setState(() => _sliderValue = _snapToStep(v));
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
              label: isLast ? 'Save run' : 'Next outcome',
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
