import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/widgets/experiments/add_output_drawer.dart';
import 'package:mix_max/widgets/experiments/add_parameter_drawer.dart';
import 'package:mix_max/widgets/input/icon_button/icon_button.dart';
import 'package:mix_max/widgets/text/headline_text.dart';
import 'package:mix_max/widgets/text/normal_text.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';

class ExperimentDetailsPage extends StatefulWidget {
  final SchemaExperiment experiment;

  const ExperimentDetailsPage({
    super.key,
    required this.experiment,
  });

  @override
  State<ExperimentDetailsPage> createState() => _ExperimentDetailsPageState();
}

class _ExperimentDetailsPageState extends State<ExperimentDetailsPage> {
  late SchemaExperiment _experiment;

  @override
  void initState() {
    super.initState();
    _experiment = widget.experiment;
  }

  void _showAddParameterDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddParameterDrawer(onSave: _saveParameter),
    );
  }

  Future<void> _saveParameter(SchemaParameter parameter) async {
    final updated = SchemaExperiment(
      id: _experiment.id,
      userId: _experiment.userId,
      name: _experiment.name,
      parameters: [...(_experiment.parameters ?? []), parameter],
      outcomes: _experiment.outcomes,
    );
    await DatabaseService.experimentsRef.doc(_experiment.id).set(updated);
    setState(() => _experiment = updated);
  }

  void _showAddOutputDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddOutputDrawer(onSave: _saveOutcome),
    );
  }

  Future<void> _saveOutcome(SchemaOutcome outcome) async {
    final updated = SchemaExperiment(
      id: _experiment.id,
      userId: _experiment.userId,
      name: _experiment.name,
      parameters: _experiment.parameters,
      outcomes: [...(_experiment.outcomes ?? []), outcome],
    );
    await DatabaseService.experimentsRef.doc(_experiment.id).set(updated);
    setState(() => _experiment = updated);
  }

  String _parameterSubtitle(SchemaParameter p) {
    final parts = <String>[];

    switch (p.type) {
      case ParameterType.number:
        if (p.unit != null) parts.add(p.unit!);
        if (p.min != null && p.max != null) {
          parts.add('${_fmt(p.min!)}–${_fmt(p.max!)}');
        } else if (p.min != null) {
          parts.add('≥ ${_fmt(p.min!)}');
        } else if (p.max != null) {
          parts.add('≤ ${_fmt(p.max!)}');
        }
      case ParameterType.choice:
        if (p.options != null && p.options!.isNotEmpty) {
          parts.add(p.options!.join(', '));
        }
      case ParameterType.order:
        if (p.items != null && p.items!.isNotEmpty) {
          parts.add(p.items!.join(' → '));
        }
      case ParameterType.duration:
        if (p.unit != null) parts.add(p.unit!);
        if (p.min != null && p.max != null) {
          parts.add('${_fmt(p.min!)}–${_fmt(p.max!)}');
        } else if (p.min != null) {
          parts.add('≥ ${_fmt(p.min!)}');
        } else if (p.max != null) {
          parts.add('≤ ${_fmt(p.max!)}');
        }
      case ParameterType.toggle:
      case null:
        break;
    }

    return parts.join('  ·  ');
  }

  String _fmt(double v) => v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final hPad = SizeConfig.safeBlockHorizontal * 5;
    final parameters = _experiment.parameters ?? [];
    final outcomes = _experiment.outcomes ?? [];

    return OrientationScaffold(
      body: Stack(
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
                HeadlineText(
                  text: _experiment.name ?? 'Experiment Details',
                  color: AppColors.dark,
                ),
                SizedBox(height: SizeConfig.safeBlockVertical * 4),

                // Parameters section
                NormalText(
                  text: 'Parameters',
                  color: AppColors.dark,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.safeBlockVertical * 1),
                if (parameters.isEmpty)
                  NormalText(text: 'No parameters yet.', color: AppColors.grey)
                else
                  ...parameters.map((p) => _ParameterRow(
                        name: p.name ?? '',
                        typeLabel: p.type?.name ?? '',
                        subtitle: _parameterSubtitle(p),
                      )),

                SizedBox(height: SizeConfig.safeBlockVertical * 4),

                // Outcomes section
                NormalText(
                  text: 'Outcomes',
                  color: AppColors.dark,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.safeBlockVertical * 1),
                if (outcomes.isEmpty)
                  NormalText(text: 'No outputs yet.', color: AppColors.grey)
                else
                  ...outcomes.map((o) => _OutcomeRow(outcome: o)),
              ],
            ),
          ),
          Positioned(
            bottom: SizeConfig.safeBlockVertical * 3,
            left: hPad,
            right: hPad,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: AppIconButton(
                    text: 'Add Parameter',
                    iconEnd: Icons.add,
                    color: AppColors.addGreen,
                    spaceOutside: true,
                    customButtonMargin: EdgeInsets.zero,
                    onPressed: _showAddParameterDrawer,
                  ),
                ),
                SizedBox(width: SizeConfig.safeBlockHorizontal * 3),
                Expanded(
                  child: AppIconButton(
                    text: 'Add Output',
                    iconEnd: Icons.add,
                    color: AppColors.actionOrange,
                    spaceOutside: true,
                    customButtonMargin: EdgeInsets.zero,
                    onPressed: _showAddOutputDrawer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  final SchemaOutcome outcome;

  const _OutcomeRow({required this.outcome});

  String _subtitle() {
    final parts = <String>[];
    if (outcome.unit != null) parts.add(outcome.unit!);
    if (outcome.min != null && outcome.max != null) {
      parts.add('${_fmt(outcome.min!)}–${_fmt(outcome.max!)}');
    } else if (outcome.min != null) {
      parts.add('≥ ${_fmt(outcome.min!)}');
    } else if (outcome.max != null) {
      parts.add('≤ ${_fmt(outcome.max!)}');
    }
    return parts.join('  ·  ');
  }

  String _fmt(double v) => v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle();
    final goal = outcome.goal;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.safeBlockVertical * 0.8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NormalText(text: outcome.name ?? '', color: AppColors.dark, fontWeight: FontWeight.w500),
                if (subtitle.isNotEmpty)
                  NormalText(
                    text: subtitle,
                    color: AppColors.grey,
                    fontSize: SizeConfig.getFontSize(2.8),
                  ),
              ],
            ),
          ),
          if (goal != null)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.safeBlockHorizontal * 2.5,
                vertical: SizeConfig.safeBlockVertical * 0.4,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    goal == OutcomeGoal.minimize ? Icons.arrow_downward : Icons.arrow_upward,
                    size: SizeConfig.getFontSize(2.8),
                    color: AppColors.dark,
                  ),
                  SizedBox(width: SizeConfig.safeBlockHorizontal * 1),
                  NormalText(
                    text: goal == OutcomeGoal.minimize ? 'minimize' : 'maximize',
                    color: AppColors.dark,
                    fontSize: SizeConfig.getFontSize(2.6),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ParameterRow extends StatelessWidget {
  final String name;
  final String typeLabel;
  final String subtitle;

  const _ParameterRow({
    required this.name,
    required this.typeLabel,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.safeBlockVertical * 0.8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NormalText(text: name, color: AppColors.dark, fontWeight: FontWeight.w500),
                if (subtitle.isNotEmpty)
                  NormalText(
                    text: subtitle,
                    color: AppColors.grey,
                    fontSize: SizeConfig.getFontSize(2.8),
                  ),
              ],
            ),
          ),
          if (typeLabel.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.safeBlockHorizontal * 2.5,
                vertical: SizeConfig.safeBlockVertical * 0.4,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 1.5),
              ),
              child: NormalText(
                text: typeLabel,
                color: AppColors.dark,
                fontSize: SizeConfig.getFontSize(2.6),
              ),
            ),
        ],
      ),
    );
  }
}
