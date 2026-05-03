import 'package:flutter/material.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/widgets/shapes/line_seperator.dart';
import 'package:mix_max/widgets/text/normal_text.dart';

class WordSeparator extends StatelessWidget {
  final String? text;
  final Color? color;
  const WordSeparator({Key? key, this.text, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SizeConfig.safeBlockHorizontal * 80,
      margin: EdgeInsets.symmetric(vertical: SizeConfig.safeBlockVertical * 2),
      child: Row(
        children: [
          LineSeparator(color: color),
          if (text != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: SizeConfig.safeBlockHorizontal * 8),
              child: NormalText(text: text ?? "", color: color),
            ),
          if (text != null) LineSeparator(color: color),
        ],
      ),
    );
  }
}
