import 'package:flutter/material.dart';

/// Shared base for every "Quiet Instrument" text atom.
///
/// It owns the boilerplate of rendering a [Text] (line clamping, alignment,
/// overflow, soft-wrap) so each named atom only has to describe *its* style.
/// You normally reach for a named atom (DisplayText, BodyText, …) rather than
/// this directly — but it is public so one-off styles can reuse the plumbing.
class MixMaxText extends StatelessWidget {
  /// The string to render. Null falls back to an empty string so callers can
  /// pass nullable model fields without guarding every site.
  final String? text;

  /// Fully-resolved style for this run of text. Named atoms build this for you.
  final TextStyle style;

  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const MixMaxText({
    Key? key,
    required this.text,
    required this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? '',
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
