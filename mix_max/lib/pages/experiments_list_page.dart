import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/services/firebase/auth_service.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/ui/navigation_service.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/pages/experiment_details_page.dart';
import 'package:mix_max/widgets/input/icon_button/icon_button.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';

class ExperimentsListPage extends StatelessWidget {
  const ExperimentsListPage({super.key});

  Future<void> _addExperiment(BuildContext context) async {
    final userId = getIt<AuthService>().user.id;
    final docRef = DatabaseService.experimentsRef.doc();
    final experiment = SchemaExperiment(
      id: docRef.id,
      userId: userId,
      name: 'New Experiment',
    );
    await docRef.set(experiment);

    if (!context.mounted) return;
    Navigation.goTo(
      context: context,
      page: ExperimentDetailsPage(experiment: experiment),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationScaffold(
      body: Stack(
        children: [
          const Center(
            child: Text('Experiments List'),
          ),
          Positioned(
            bottom: SizeConfig.safeBlockVertical * 3,
            left: SizeConfig.safeBlockHorizontal * 5,
            right: SizeConfig.safeBlockHorizontal * 5,
            child: AppIconButton(
              text: 'Add Experiment',
              iconEnd: Icons.add,
              color: AppColors.addGreen,
              spaceOutside: true,
              onPressed: () => _addExperiment(context),
            ),
          ),
        ],
      ),
    );
  }
}
