import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';

/// A fixed-height multi-line text field in the "Quiet Instrument" voice.
///
/// Source: `drawers.jsx` `TextArea`. The multi-line sibling of
/// `MixMaxTextInput`: the same `surface`-filled box with a 1.5px hairline
/// border that warms to [AppColors.gold] on focus and the 14px `rField`
/// radius, but sized to a fixed [rows]-line block (resize: none) that scrolls
/// internally, with relaxed 1.5 line-height reading copy.
///
/// Like the single-line input, the built-in Material counter is suppressed —
/// the design pairs the field with its own separate counter; [maxLength] is
/// enforced purely as an input limit.
class MixMaxTextArea extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  final String? placeholder;

  /// Hard character cap. Enforced as an input formatter (no visible counter).
  final int? maxLength;

  /// Fixed height of the field, in text lines (the textarea's `rows`).
  final int rows;

  const MixMaxTextArea({
    Key? key,
    this.controller,
    this.onChanged,
    this.placeholder,
    this.maxLength,
    this.rows = 3,
  }) : super(key: key);

  @override
  State<MixMaxTextArea> createState() => _MixMaxTextAreaState();
}

class _MixMaxTextAreaState extends State<MixMaxTextArea> {
  final FocusNode _node = FocusNode();

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppColors.ink,
      height: 1.5,
    );

    final field = TextField(
      controller: widget.controller,
      focusNode: _node,
      onChanged: widget.onChanged,
      minLines: widget.rows,
      maxLines: widget.rows,
      keyboardType: TextInputType.multiline,
      cursorColor: AppColors.gold,
      style: textStyle,
      inputFormatters: widget.maxLength != null
          ? [LengthLimitingTextInputFormatter(widget.maxLength)]
          : null,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        hintText: widget.placeholder,
        hintStyle: textStyle.copyWith(color: AppColors.inkFaint),
      ),
    );

    // Drive the border colour off the focus node directly so toggling focus
    // animates the hairline without rebuilding the field subtree.
    return AnimatedBuilder(
      animation: _node,
      child: field,
      builder: (context, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(_kRadius),
          border: Border.all(
            color: _node.hasFocus ? AppColors.gold : AppColors.hairline,
            width: 1.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

// Border radius — design token `rField` (theme.jsx).
const double _kRadius = 14;
