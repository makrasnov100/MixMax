import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/services/bayesian_optimization_service.dart';
import 'package:mix_max/services/firebase/auth_service.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/widgets/input/icon_button/icon_button.dart';
import 'package:mix_max/widgets/text/headline_text.dart';
import 'package:mix_max/widgets/text/normal_text.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';

enum _RunPhase { loading, ready, recording, saving, error }

class RunIterationPage extends StatefulWidget {
  final SchemaExperiment experiment;

  const RunIterationPage({super.key, required this.experiment});

  @override
  State<RunIterationPage> createState() => _RunIterationPageState();
}

class _RunIterationPageState extends State<RunIterationPage> {
  _RunPhase _phase = _RunPhase.loading;
  String? _errorMessage;

  Map<String, dynamic> _suggestedParameters = const <String, dynamic>{};
  final Map<String, double> _outcomeValues = {};
  int _currentOutcomeIndex = 0;

  SchemaRun? _draftRun;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    setState(() {
      _phase = _RunPhase.loading;
      _errorMessage = null;
    });

    try {
      final userId = getIt<AuthService>().user.id;
      if (userId.isEmpty || userId == 'INITIAL') {
        throw StateError('Not signed in yet. Please try again in a moment.');
      }

      final pastRunsSnapshot = await DatabaseService.runsRef
          .where('userId', isEqualTo: userId)
          .where('experimentId', isEqualTo: widget.experiment.id)
          .get();

      final pastRuns = pastRunsSnapshot.docs
          .map((d) => d.data())
          .where((r) => r.isValid())
          .toList();

      final suggestion = BayesianOptimizationService.suggestNextParameters(
        experiment: widget.experiment,
        pastRuns: pastRuns,
      );

      final docRef = DatabaseService.runsRef.doc();
      final draft = SchemaRun(
        id: docRef.id,
        experimentId: widget.experiment.id,
        userId: userId,
        parameterValues: suggestion,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      if (!mounted) return;
      setState(() {
        _suggestedParameters = suggestion;
        _draftRun = draft;
        _phase = _RunPhase.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not generate next run.\n$e';
        _phase = _RunPhase.error;
      });
    }
  }

  void _startRecording() {
    final outcomes = widget.experiment.outcomes ?? [];
    if (outcomes.isEmpty) return;
    setState(() {
      _currentOutcomeIndex = 0;
      _phase = _RunPhase.recording;
    });
  }

  void _onOutcomeValueSubmitted(SchemaOutcome outcome, double value) {
    _outcomeValues[outcome.id] = value;

    final outcomes = widget.experiment.outcomes ?? [];
    if (_currentOutcomeIndex + 1 >= outcomes.length) {
      _saveRun();
      return;
    }

    setState(() => _currentOutcomeIndex += 1);
  }

  void _onGoBackInRecording() {
    if (_currentOutcomeIndex == 0) {
      setState(() => _phase = _RunPhase.ready);
      return;
    }
    setState(() => _currentOutcomeIndex -= 1);
  }

  Future<void> _saveRun() async {
    final draft = _draftRun;
    if (draft == null) {
      setState(() {
        _phase = _RunPhase.error;
        _errorMessage = 'Could not save run. Please try again.';
      });
      return;
    }

    setState(() => _phase = _RunPhase.saving);

    draft.outcomeValues = Map<String, double>.from(_outcomeValues);
    draft.completedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      await DatabaseService.runsRef
          .doc(draft.id)
          .set(draft, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _RunPhase.recording;
        _errorMessage = 'Could not save run. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationScaffold(
      body: SafeArea(
        child: switch (_phase) {
          _RunPhase.loading => const _LoadingView(),
          _RunPhase.saving => const _LoadingView(message: 'Saving run…'),
          _RunPhase.error => _ErrorView(
              message: _errorMessage ?? 'Something went wrong.',
              onRetry: _bootstrap,
            ),
          _RunPhase.ready => _ReadyView(
              experiment: widget.experiment,
              suggestion: _suggestedParameters,
              errorMessage: _errorMessage,
              onRecordOutcomes: _startRecording,
            ),
          _RunPhase.recording => _RecordingView(
              experiment: widget.experiment,
              currentIndex: _currentOutcomeIndex,
              existingValue: _outcomeValues[
                  widget.experiment.outcomes![_currentOutcomeIndex].id],
              errorMessage: _errorMessage,
              onSubmit: _onOutcomeValueSubmitted,
              onBack: _onGoBackInRecording,
            ),
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final hPad = SizeConfig.safeBlockHorizontal * 8;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.dangerRed,
            size: SizeConfig.getFontSize(10),
          ),
          SizedBox(height: SizeConfig.safeBlockVertical * 2),
          NormalText(
            text: message,
            color: AppColors.dark,
            textAlign: TextAlign.center,
            fontSize: SizeConfig.getFontSize(3.2),
          ),
          SizedBox(height: SizeConfig.safeBlockVertical * 4),
          AppIconButton(
            text: 'Try Again',
            iconEnd: Icons.refresh_rounded,
            color: AppColors.optionDarkBlue,
            spaceOutside: true,
            customButtonMargin: EdgeInsets.zero,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final String message;
  const _LoadingView({this.message = 'Generating next run…'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: SizeConfig.safeBlockVertical * 3),
          NormalText(text: message, color: AppColors.grey),
        ],
      ),
    );
  }
}

class _ReadyView extends StatelessWidget {
  final SchemaExperiment experiment;
  final Map<String, dynamic> suggestion;
  final String? errorMessage;
  final VoidCallback onRecordOutcomes;

  const _ReadyView({
    required this.experiment,
    required this.suggestion,
    required this.errorMessage,
    required this.onRecordOutcomes,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = SizeConfig.safeBlockHorizontal * 5;
    final parameters = experiment.parameters ?? [];

    return Stack(
      fit: StackFit.expand,
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            hPad,
            SizeConfig.safeBlockVertical * 3,
            hPad,
            SizeConfig.safeBlockVertical * 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NormalText(
                text: 'Next Run',
                color: AppColors.grey,
                fontSize: SizeConfig.getFontSize(3),
                fontWeight: FontWeight.w500,
              ),
              SizedBox(height: SizeConfig.safeBlockVertical * 0.6),
              HeadlineText(
                text: experiment.name?.isNotEmpty == true
                    ? experiment.name!
                    : 'Untitled experiment',
                color: AppColors.dark,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.safeBlockVertical * 4),
              NormalText(
                text: 'Try these parameters',
                color: AppColors.dark,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: SizeConfig.safeBlockVertical * 1.5),
              if (parameters.isEmpty)
                NormalText(text: 'No parameters set.', color: AppColors.grey)
              else
                ...parameters.map(
                  (p) => _SuggestedParameterCard(
                    parameter: p,
                    value: suggestion[p.id],
                  ),
                ),
              if (errorMessage != null) ...[
                SizedBox(height: SizeConfig.safeBlockVertical * 2),
                NormalText(
                  text: errorMessage!,
                  color: AppColors.dangerRed,
                ),
              ],
            ],
          ),
        ),
        Positioned(
          bottom: SizeConfig.safeBlockVertical * 3,
          left: hPad,
          right: hPad,
          child: AppIconButton(
            text: 'Record Outcomes',
            iconEnd: Icons.arrow_forward_rounded,
            color: AppColors.actionOrange,
            spaceOutside: true,
            customButtonMargin: EdgeInsets.zero,
            onPressed: (experiment.outcomes ?? []).isEmpty ? null : onRecordOutcomes,
          ),
        ),
      ],
    );
  }
}

class _SuggestedParameterCard extends StatelessWidget {
  final SchemaParameter parameter;
  final dynamic value;

  const _SuggestedParameterCard({required this.parameter, required this.value});

  String _formatValue() {
    switch (parameter.type) {
      case ParameterType.number:
      case ParameterType.duration:
        if (value is num) {
          final v = (value as num).toDouble();
          final rounded = double.parse(v.toStringAsFixed(3));
          final asStr = rounded == rounded.truncateToDouble()
              ? rounded.toInt().toString()
              : rounded.toString();
          return parameter.unit != null ? '$asStr ${parameter.unit}' : asStr;
        }
        return '—';
      case ParameterType.toggle:
        return value == true ? 'On' : 'Off';
      case ParameterType.choice:
        return value?.toString() ?? '—';
      case ParameterType.order:
        if (value is List) {
          return (value as List).join(' → ');
        }
        return '—';
      case null:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.safeBlockVertical * 1.2),
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.safeBlockHorizontal * 4,
        vertical: SizeConfig.safeBlockVertical * 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius:
            BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2.6),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NormalText(
                  text: parameter.name ?? '',
                  color: AppColors.grey,
                  fontSize: SizeConfig.getFontSize(2.8),
                ),
                SizedBox(height: SizeConfig.safeBlockVertical * 0.4),
                NormalText(
                  text: _formatValue(),
                  color: AppColors.dark,
                  fontWeight: FontWeight.w500,
                  fontSize: SizeConfig.getFontSize(3.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
  bool _hasSliderMoved = false;

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
      _hasSliderMoved = initial != null;
    }
    _textController = TextEditingController(
      text: initial != null ? _fmt(initial) : '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    final rounded = double.parse(v.toStringAsFixed(3));
    return rounded == rounded.truncateToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }

  void _submit() {
    if (_hasBounds) {
      if (!_hasSliderMoved && widget.existingValue == null) return;
      widget.onSubmit(_outcome, _snapToStep(_sliderValue));
      return;
    }

    final parsed = double.tryParse(_textController.text.trim());
    if (parsed == null) return;
    widget.onSubmit(_outcome, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final hPad = SizeConfig.safeBlockHorizontal * 5;
    final outcomes = widget.experiment.outcomes ?? [];
    final isLast = widget.currentIndex == outcomes.length - 1;
    final canSubmit = _hasBounds
        ? (_hasSliderMoved || widget.existingValue != null)
        : double.tryParse(_textController.text.trim()) != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            hPad,
            SizeConfig.safeBlockVertical * 3,
            hPad,
            SizeConfig.safeBlockVertical * 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onBack,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.dark,
                      size: SizeConfig.getFontSize(5),
                    ),
                  ),
                  SizedBox(width: SizeConfig.safeBlockHorizontal * 3),
                  NormalText(
                    text:
                        'Outcome ${widget.currentIndex + 1} of ${outcomes.length}',
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.safeBlockVertical * 4),
              HeadlineText(
                text: _outcome.name?.isNotEmpty == true ? _outcome.name! : 'Outcome',
                color: AppColors.dark,
                maxLines: 2,
              ),
              SizedBox(height: SizeConfig.safeBlockVertical * 1),
              _GoalHint(outcome: _outcome),
              SizedBox(height: SizeConfig.safeBlockVertical * 5),
              if (_hasBounds)
                _SliderInput(
                  outcome: _outcome,
                  value: _sliderValue,
                  onChanged: (v) {
                    setState(() {
                      _sliderValue = v;
                      _hasSliderMoved = true;
                    });
                  },
                )
              else
                _NumberInput(
                  controller: _textController,
                  outcome: _outcome,
                  onChanged: (_) => setState(() {}),
                ),
              if (widget.errorMessage != null) ...[
                SizedBox(height: SizeConfig.safeBlockVertical * 2),
                NormalText(
                  text: widget.errorMessage!,
                  color: AppColors.dangerRed,
                ),
              ],
            ],
          ),
        ),
        Positioned(
          bottom: SizeConfig.safeBlockVertical * 3,
          left: hPad,
          right: hPad,
          child: AppIconButton(
            text: isLast ? 'Save Run' : 'Next Outcome',
            iconEnd: isLast ? Icons.check : Icons.arrow_forward_rounded,
            color: canSubmit
                ? (isLast ? AppColors.addGreen : AppColors.actionOrange)
                : AppColors.grey,
            spaceOutside: true,
            customButtonMargin: EdgeInsets.zero,
            onPressed: canSubmit ? _submit : null,
          ),
        ),
      ],
    );
  }
}

class _GoalHint extends StatelessWidget {
  final SchemaOutcome outcome;
  const _GoalHint({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final goal = outcome.goal;
    final parts = <String>[];
    if (outcome.unit != null) parts.add(outcome.unit!);
    if (goal == OutcomeGoal.minimize) {
      parts.add('lower is better');
    } else if (goal == OutcomeGoal.maximize) {
      parts.add('higher is better');
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    return NormalText(
      text: parts.join('  ·  '),
      color: AppColors.grey,
      fontSize: SizeConfig.getFontSize(3),
    );
  }
}

class _SliderInput extends StatelessWidget {
  final SchemaOutcome outcome;
  final double value;
  final ValueChanged<double> onChanged;

  const _SliderInput({
    required this.outcome,
    required this.value,
    required this.onChanged,
  });

  double get _step {
    final raw = outcome.step;
    if (raw == null || raw <= 0) return 1.0;
    return raw;
  }

  int _decimalsForStep() {
    final s = _step;
    if (s >= 1 && s == s.truncateToDouble()) return 0;
    final str = s.toString();
    final dot = str.indexOf('.');
    if (dot < 0) return 0;
    return (str.length - dot - 1).clamp(0, 4);
  }

  String _fmt(double v) {
    final decimals = _decimalsForStep();
    if (decimals == 0) return v.round().toString();
    return v.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
    final min = outcome.min ?? 0.0;
    final max = outcome.max ?? 1.0;
    final unit = outcome.unit ?? '';
    final range = max - min;
    final divisions = range > 0 ? (range / _step).round().clamp(1, 10000) : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        NormalText(
          text: unit.isEmpty ? _fmt(value) : '${_fmt(value)} $unit',
          color: AppColors.dark,
          fontSize: SizeConfig.getFontSize(8),
          fontWeight: FontWeight.w500,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: SizeConfig.safeBlockVertical * 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.dark,
            inactiveTrackColor: AppColors.lightGrey,
            thumbColor: AppColors.dark,
            overlayColor: AppColors.dark.withValues(alpha: 0.1),
            trackHeight: SizeConfig.safeBlockVertical * 0.8,
          ),
          child: Slider(
            min: min,
            max: max,
            divisions: divisions,
            value: value.clamp(min, max),
            label: unit.isEmpty ? _fmt(value) : '${_fmt(value)} $unit',
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.safeBlockHorizontal * 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NormalText(
                text: _fmt(min),
                color: AppColors.grey,
                fontSize: SizeConfig.getFontSize(2.8),
              ),
              NormalText(
                text: _fmt(max),
                color: AppColors.grey,
                fontSize: SizeConfig.getFontSize(2.8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final SchemaOutcome outcome;
  final ValueChanged<String> onChanged;

  const _NumberInput({
    required this.controller,
    required this.outcome,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NormalText(
          text: 'Enter measured value',
          color: AppColors.grey,
          fontSize: SizeConfig.getFontSize(3),
        ),
        SizedBox(height: SizeConfig.safeBlockVertical * 1),
        TextField(
          controller: controller,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true, signed: true),
          onChanged: onChanged,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\.\-]')),
          ],
          style: TextStyle(
            fontSize: SizeConfig.getFontSize(5),
            color: AppColors.dark,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: outcome.unit != null ? 'value (${outcome.unit})' : 'value',
            hintStyle: TextStyle(
              color: AppColors.grey,
              fontSize: SizeConfig.getFontSize(5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: SizeConfig.safeBlockHorizontal * 3,
              vertical: SizeConfig.safeBlockVertical * 1.5,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2),
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2),
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2),
              borderSide: const BorderSide(color: AppColors.dark),
            ),
          ),
        ),
      ],
    );
  }
}
