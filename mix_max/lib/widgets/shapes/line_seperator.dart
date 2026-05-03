import 'package:flutter/material.dart';

class LineSeparator extends StatelessWidget {
  final Color? color;
  const LineSeparator({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: color ?? Colors.white,
        height: 1.1,
      ),
    );
  }
}
