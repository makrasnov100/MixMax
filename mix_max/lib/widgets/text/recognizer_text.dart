import 'package:flutter/material.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/ui/size_config.dart';
import 'package:mix_max/widgets/text/normal_text.dart';

class RecognizerText extends StatefulWidget {
  final Function()? onPressed;
  final String text;
  final Color? color;
  final double? fontSize;
  final String? action;

  final String? analyticsEvent;
  final Map<String, String?>? analyticsParams;

  const RecognizerText({
    Key? key,
    required this.text,
    this.onPressed,
    this.color,
    this.fontSize,
    this.action,
    this.analyticsEvent,
    this.analyticsParams,
  }) : super(key: key);

  @override
  State<RecognizerText> createState() => _RecognizerTextState();
}

class _RecognizerTextState extends State<RecognizerText> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        widget.onPressed?.call();
      },
      child: NormalText(
        text: widget.text,
        textAlign: TextAlign.center,
        fontSize: widget.fontSize ?? SizeConfig.safeBlockVertical * 2,
        color: widget.color ?? AppColors.primaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
