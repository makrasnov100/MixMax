import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';

/// A single-line text field in the "Quiet Instrument" voice.
///
/// Source: `drawers.jsx` `TextInput`. A `surface`-filled box with a 1.5px
/// hairline border that warms to [AppColors.gold] on focus, the 14px `rField`
/// radius, and sans / 500 copy. Two sizes via [big]: the standard 50px field
/// and the 56px / 19px "name your experiment" hero field.
///
/// The built-in Material character counter is suppressed (the design pairs the
/// field with its own separate counter); [maxLength] is enforced purely as an
/// input limit. Pass a [controller] to read/seed the value, [onChanged] to
/// observe edits, or both.
class MixMaxTextInput extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  final String? placeholder;

  /// Hard character cap. Enforced as an input formatter (no visible counter).
  final int? maxLength;

  final bool autofocus;

  /// The 56px / 19px hero size (e.g. "Name your experiment"). Default is the
  /// standard 50px / 16px field.
  final bool big;

  final TextAlign textAlign;
  final TextInputType? keyboardType;

  /// Supply to share focus state with siblings; otherwise one is created and
  /// owned internally.
  final FocusNode? focusNode;

  const MixMaxTextInput({
    Key? key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.placeholder,
    this.maxLength,
    this.autofocus = false,
    this.big = false,
    this.textAlign = TextAlign.left,
    this.keyboardType,
    this.focusNode,
  }) : super(key: key);

  @override
  State<MixMaxTextInput> createState() => _MixMaxTextInputState();
}

class _MixMaxTextInputState extends State<MixMaxTextInput> {
  late FocusNode _node;
  bool _ownsNode = false;

  @override
  void initState() {
    super.initState();
    _attachNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(MixMaxTextInput old) {
    super.didUpdateWidget(old);
    if (widget.focusNode != old.focusNode) {
      _detachNode();
      _attachNode(widget.focusNode);
    }
  }

  void _attachNode(FocusNode? external) {
    _ownsNode = external == null;
    _node = external ?? FocusNode();
    _node.addListener(_onFocusChange);
  }

  void _detachNode() {
    _node.removeListener(_onFocusChange);
    if (_ownsNode) _node.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _detachNode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final big = widget.big;
    final fontSize = big ? 19.0 : 16.0;
    final textStyle = TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.ink,
      height: 1,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      height: big ? 56 : 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(
          color: _node.hasFocus ? AppColors.gold : AppColors.hairline,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _node,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        autofocus: widget.autofocus,
        textAlign: widget.textAlign,
        keyboardType: widget.keyboardType,
        cursorColor: AppColors.gold,
        style: textStyle,
        inputFormatters: widget.maxLength != null
            ? [LengthLimitingTextInputFormatter(widget.maxLength)]
            : null,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: widget.placeholder,
          hintStyle: textStyle.copyWith(color: AppColors.inkFaint),
        ),
      ),
    );
  }
}

// Border radius — design token `rField` (theme.jsx).
const double _kRadius = 14;
