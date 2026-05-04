import 'package:flutter/material.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';

class ExperimentDetailsPage extends StatelessWidget {
  const ExperimentDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationScaffold(
      body: const Center(
        child: Text('Experiment Details'),
      ),
    );
  }
}
