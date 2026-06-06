import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/services/firebase/auth_service.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/services/ui/navigation_service.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/pages/experiment_details_page.dart';
import 'package:mix_max/widgets/input/icon_button/icon_button.dart';
import 'package:mix_max/widgets/text/headline_text.dart';
import 'package:mix_max/widgets/text/normal_text.dart';
import 'package:mix_max/widgets/wrappers/orientation_scaffold.dart';

class ExperimentsListPage extends StatefulWidget {
  const ExperimentsListPage({super.key});

  @override
  State<ExperimentsListPage> createState() => _ExperimentsListPageState();
}

class _ExperimentsListPageState extends State<ExperimentsListPage> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = getIt<AuthService>();
    _authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _addExperiment() async {
    final userId = _authService.user.id;
    final docRef = DatabaseService.experimentsRef.doc();
    final experiment = SchemaExperiment(
      id: docRef.id,
      userId: userId,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    await docRef.set(experiment, SetOptions(merge: true));

    if (!mounted) return;
    Navigation.goTo(
      context: context,
      page: ExperimentDetailsPage(
        experiment: experiment,
        autoPromptName: true,
      ),
    );
  }

  Stream<QuerySnapshot<SchemaExperiment>>? _experimentsStream() {
    final userId = _authService.user.id;
    if (userId.isEmpty || userId == 'INITIAL') {
      return null;
    }
    return DatabaseService.experimentsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = SizeConfig.safeBlockHorizontal * 5;
    final stream = _experimentsStream();

    return OrientationScaffold(
      body: Stack(
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
                HeadlineText(
                  text: 'Experiments',
                  color: AppColors.dark,
                ),
                SizedBox(height: SizeConfig.safeBlockVertical * 3),
                Expanded(
                  child: stream == null
                      ? Center(
                          child: NormalText(
                            text: 'Signing you in…',
                            color: AppColors.grey,
                          ),
                        )
                      : StreamBuilder<QuerySnapshot<SchemaExperiment>>(
                          stream: stream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: NormalText(
                                  text: 'Could not load experiments.',
                                  color: AppColors.dangerRed,
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final docs = snapshot.data?.docs ?? [];
                            final experiments = docs
                                .map((d) => d.data())
                                .where((e) => e.isValid())
                                .toList();

                            if (experiments.isEmpty) {
                              return Center(
                                child: NormalText(
                                  text: 'No experiments yet. Tap "Add Experiment" to start.',
                                  color: AppColors.grey,
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            return ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: experiments.length,
                              separatorBuilder: (_, __) => SizedBox(
                                height: SizeConfig.safeBlockVertical * 1.2,
                              ),
                              itemBuilder: (_, index) => _ExperimentRow(
                                experiment: experiments[index],
                                onTap: () => Navigation.goTo(
                                  context: context,
                                  page: ExperimentDetailsPage(
                                    experiment: experiments[index],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: SizeConfig.safeBlockVertical * 3,
            left: hPad,
            right: hPad,
            child: AppIconButton(
              text: 'Add Experiment',
              iconEnd: Icons.add,
              color: AppColors.addGreen,
              spaceOutside: true,
              customButtonMargin: EdgeInsets.zero,
              onPressed: _addExperiment,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperimentRow extends StatelessWidget {
  final SchemaExperiment experiment;
  final VoidCallback onTap;

  const _ExperimentRow({required this.experiment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final paramCount = experiment.parameters?.length ?? 0;
    final outcomeCount = experiment.outcomes?.length ?? 0;
    final subtitleParts = <String>[
      '$paramCount parameter${paramCount == 1 ? '' : 's'}',
      '$outcomeCount outcome${outcomeCount == 1 ? '' : 's'}',
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2.6),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.safeBlockHorizontal * 4,
          vertical: SizeConfig.safeBlockVertical * 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.safeBlockHorizontal * 2.6),
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NormalText(
                    text: experiment.name?.isNotEmpty == true ? experiment.name! : 'Untitled experiment',
                    color: AppColors.dark,
                    fontWeight: FontWeight.w500,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: SizeConfig.safeBlockVertical * 0.4),
                  NormalText(
                    text: subtitleParts.join('  ·  '),
                    color: AppColors.grey,
                    fontSize: SizeConfig.getFontSize(2.8),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
