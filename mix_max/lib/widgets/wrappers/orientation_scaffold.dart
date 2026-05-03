import 'package:flutter/material.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/ui/size_config.dart';

class OrientationScaffold extends StatelessWidget {
  //Backgroud config
  final Color safeAreaBottomColor;
  final Color safeAreaTopColor;

  //Pass-through scaffold props
  final Widget? body;
  final bool? resizeToAvoidBottomInset;
  final Key? scaffoldKey;

  const OrientationScaffold({
    Key? key,
    this.safeAreaBottomColor = Colors.transparent,
    this.safeAreaTopColor = Colors.transparent,
    this.body,
    this.resizeToAvoidBottomInset,
    this.scaffoldKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColors.black, width: double.infinity, height: double.infinity),
        Center(
          child: Container(color: AppColors.background, width: SizeConfig.screenWidth, height: SizeConfig.screenHeight),
        ),
        OrientationBuilder(
          builder: (context, orientation) {
            return Center(
              child: SizedBox(
                width: SizeConfig.screenWidth,
                height: SizeConfig.screenHeight,
                child: Scaffold(
                  resizeToAvoidBottomInset: resizeToAvoidBottomInset,
                  key: scaffoldKey,
                  backgroundColor: Colors.transparent,
                  body:
                      body != null
                          ? Stack(
                            children: [
                              Positioned(
                                top: 0,
                                child: Container(
                                  width: SizeConfig.screenWidth,
                                  height: SizeConfig.topSafeAreaHeight,
                                  color: safeAreaTopColor,
                                ),
                              ),
                              SafeArea(child: body!),
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  width: SizeConfig.screenWidth,
                                  height: SizeConfig.bottomSafeAreaHeight,
                                  color: safeAreaBottomColor,
                                ),
                              ),
                            ],
                          )
                          : null,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
