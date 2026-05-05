import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/classes/schema/outcome.dart';
import 'package:mix_max/classes/schema/parameter.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/ui/size_config.dart';
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

  Future<void> _addParameter() async {
    final id = DatabaseService.experimentsRef.doc().id;
    final parameter = SchemaParameter(id: id, name: 'New Parameter');
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

  Future<void> _addOutcome() async {
    final id = DatabaseService.experimentsRef.doc().id;
    final outcome = SchemaOutcome(id: id, name: 'New Outcome');
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

  @override
  Widget build(BuildContext context) {
    final hPad = SizeConfig.safeBlockHorizontal * 5;
    final parameters = _experiment.parameters ?? [];
    final outcomes = _experiment.outcomes ?? [];

    return OrientationScaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              hPad,
              SizeConfig.safeBlockVertical * 3,
              hPad,
              SizeConfig.safeBlockVertical * 22,
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
                  NormalText(
                    text: 'No parameters yet.',
                    color: AppColors.grey,
                  )
                else
                  ...parameters.map(
                    (p) => Padding(
                      padding: EdgeInsets.symmetric(vertical: SizeConfig.safeBlockVertical * 0.5),
                      child: NormalText(
                        text: p.name ?? '',
                        color: AppColors.dark,
                      ),
                    ),
                  ),

                SizedBox(height: SizeConfig.safeBlockVertical * 4),

                // Outcomes section
                NormalText(
                  text: 'Outcomes',
                  color: AppColors.dark,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.safeBlockVertical * 1),
                if (outcomes.isEmpty)
                  NormalText(
                    text: 'No outcomes yet.',
                    color: AppColors.grey,
                  )
                else
                  ...outcomes.map(
                    (o) => Padding(
                      padding: EdgeInsets.symmetric(vertical: SizeConfig.safeBlockVertical * 0.5),
                      child: NormalText(
                        text: o.name ?? '',
                        color: AppColors.dark,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: SizeConfig.safeBlockVertical * 3,
            left: hPad,
            right: hPad,
            child: Column(
              children: [
                AppIconButton(
                  text: 'Add Parameter',
                  iconEnd: Icons.add,
                  color: AppColors.addGreen,
                  spaceOutside: true,
                  onPressed: _addParameter,
                ),
                AppIconButton(
                  text: 'Add Outcome',
                  iconEnd: Icons.add,
                  color: AppColors.addGreen,
                  spaceOutside: true,
                  onPressed: _addOutcome,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
