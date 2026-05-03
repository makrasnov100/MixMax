//TODO TEMPLATE: remove this file and package if pattern background wont be used

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:patterns_canvas/patterns_canvas.dart';

enum BackgroundPatternType {
  horizontalStripesThick,
  horizontalStripesLight,
  verticalStripesThick,
  verticalStripesLight,
  diagonalStripesThick,
  diagonalStripesLight,
  checkers,
  crosshatch,
  dots,
  texture,
}

class PatternBackground extends StatefulWidget {
  final List<Color> foregroundColors;
  final List<Color> backgroundColors;
  final List<BackgroundPatternType> patterns;
  const PatternBackground({
    Key? key,
    this.foregroundColors = const [Colors.grey],
    this.backgroundColors = const [Colors.white],
    this.patterns = const [BackgroundPatternType.verticalStripesThick],
  }) : super(key: key);

  @override
  State<PatternBackground> createState() => _PatternBackgroundState();
}

class _PatternBackgroundState extends State<PatternBackground> {
  Color foregroundColor = Colors.grey;
  Color backgroundColor = Colors.white;
  BackgroundPatternType pattern = BackgroundPatternType.verticalStripesThick;

  void chooseRandomColorSettings() {
    //Choose random colors from lists
    int randomForegroundColorIndex = (widget.foregroundColors.length * (1 - 0) * Random().nextDouble()).toInt();
    foregroundColor = widget.foregroundColors[randomForegroundColorIndex];
    int randomBackgroundColorIndex = (widget.backgroundColors.length * (1 - 0) * Random().nextDouble()).toInt();
    backgroundColor = widget.backgroundColors[randomBackgroundColorIndex];
  }

  void chooseRandomPatternSettings() {
    //Choose random pattern from list
    int randomPatternIndex = (widget.patterns.length * (1 - 0) * Random().nextDouble()).toInt();
    pattern = widget.patterns[randomPatternIndex];
  }

  void chooseRandomSettings() {
    chooseRandomColorSettings();
    chooseRandomPatternSettings();
  }

  @override
  void initState() {
    super.initState();
    chooseRandomSettings();
  }

  @override
  void didUpdateWidget(PatternBackground oldWidget) {
    //Check if any of the color arrays have changed
    if (oldWidget.foregroundColors != widget.foregroundColors ||
        oldWidget.backgroundColors != widget.backgroundColors) {
      chooseRandomColorSettings();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ContainerPatternPainter(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        pattern: pattern,
      ),
      child: SizedBox(
        height: double.infinity,
        width: double.infinity,
      ),
    );
  }
}

class ContainerPatternPainter extends CustomPainter {
  Color foregroundColor = Colors.black;
  Color backgroundColor = Colors.white;
  BackgroundPatternType pattern = BackgroundPatternType.verticalStripesThick;

  ContainerPatternPainter({
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.pattern = BackgroundPatternType.verticalStripesThick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == BackgroundPatternType.horizontalStripesThick) {
      HorizontalStripesThick(bgColor: foregroundColor, fgColor: backgroundColor).paintOnWidget(canvas, size);
    } else if (pattern == BackgroundPatternType.horizontalStripesLight) {
      HorizontalStripesLight(bgColor: foregroundColor, fgColor: backgroundColor).paintOnWidget(canvas, size);
    } else if (pattern == BackgroundPatternType.verticalStripesThick) {
      VerticalStripesThick(bgColor: foregroundColor, fgColor: backgroundColor).paintOnWidget(canvas, size);
    } else if (pattern == BackgroundPatternType.verticalStripesLight) {
      VerticalStripesLight(bgColor: foregroundColor, fgColor: backgroundColor).paintOnWidget(canvas, size);
    } else if (pattern == BackgroundPatternType.diagonalStripesThick) {
      DiagonalStripesThick(bgColor: foregroundColor, fgColor: backgroundColor).paintOnWidget(canvas, size);
    } else if (pattern == BackgroundPatternType.diagonalStripesLight) {
      DiagonalStripesLight(bgColor: foregroundColor, fgColor: backgroundColor).paintOnWidget(canvas, size);
    } else if (pattern == BackgroundPatternType.checkers) {
      Checkers(bgColor: foregroundColor, fgColor: backgroundColor).paintOnWidget(canvas, size);
    } else if (pattern == BackgroundPatternType.crosshatch) {
      Crosshatch(bgColor: foregroundColor, fgColor: backgroundColor).paintOnWidget(canvas, size);
    } else if (pattern == BackgroundPatternType.dots) {
      Dots(bgColor: foregroundColor, fgColor: backgroundColor).paintOnWidget(canvas, size);
    } else if (pattern == BackgroundPatternType.texture) {
      VerticalStripesThick(bgColor: foregroundColor, fgColor: backgroundColor).paintOnWidget(canvas, size);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
