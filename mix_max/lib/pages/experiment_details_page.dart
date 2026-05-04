import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';

class ExperimentDetailsPage extends StatelessWidget {
  final SchemaExperiment experiment;

  const ExperimentDetailsPage({
    super.key,
    required this.experiment,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationScaffold(
      body: Center(
        child: Text(experiment.name ?? 'Experiment Details'),
      ),
    );
  }
}
