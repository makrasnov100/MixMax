import 'package:flutter/material.dart';
import 'package:mix_max/services/ui/size_config.dart';

class SingleButtonHolder extends StatelessWidget {
  final bool smallerForTablets;

  final double? tabletWidth;
  final double? phoneWidth;

  final EdgeInsets? margin;
  final Widget button;

  const SingleButtonHolder({
    Key? key,
    this.smallerForTablets = true,
    this.margin,
    required this.button,
    this.tabletWidth,
    this.phoneWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width:
          SizeConfig.safeBlockHorizontal *
          ((smallerForTablets && SizeConfig.isTablet()) ? tabletWidth ?? 60 : phoneWidth ?? 90),
      child: button,
    );
  }
}
