import 'package:flutter/material.dart';
import 'package:mix_max/services/ui/size_config.dart';

class PopOnOrientationChange extends StatefulWidget {
  const PopOnOrientationChange({super.key});

  @override
  State<PopOnOrientationChange> createState() => _PopOnOrientationChangeState();
}

class _PopOnOrientationChangeState extends State<PopOnOrientationChange> with WidgetsBindingObserver {
  double width = 0;
  double height = 0;
  int countPop = 0;

  @override
  void initState() {
    super.initState();
    width = SizeConfig.screenWidth;
    height = SizeConfig.screenHeight;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      double newWidth = SizeConfig.screenWidth;
      double newHeight = SizeConfig.screenHeight;
      if (countPop == 0 && mounted && (newWidth != width || newHeight != height)) {
        countPop++;
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();
  }
}
