import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/text.dart';
import 'package:mix_max/widgets/design/ions/text/label_text.dart';

/// The visual voices a [MixMaxButton] can take, ported from `ui.jsx`
/// `BTN_VARIANTS`. Each variant carries its own fill / ink / elevation:
///   • [ink]    — primary commit. Near-black fill, soft drop shadow.
///   • [gold]   — the signature "run / optimize" action. Warm gold + glow.
///   • [sage]   — quiet parameter-tinted action (tint fill, no elevation).
///   • [violet] — quiet outcome-tinted action (tint fill, no elevation).
///   • [ghost]  — low-emphasis. Transparent with a hairline outline.
enum MixMaxButtonVariant { ink, gold, sage, violet, ghost }

/// Primary labelled action button for the "Quiet Instrument" system.
///
/// Source: `ui.jsx` `Btn`. A pill-cornered (16px) bar, 56px tall by default,
/// sans / 600 / 16 label with faint positive tracking, optional leading and
/// trailing icon slots, and a subtle press-scale (0.985) for tactility.
///
/// Disabled when [onPressed] is null or [enabled] is false: it adopts the muted
/// hairline fill, drops any elevation, and ignores taps.
class MixMaxButton extends StatefulWidget {
  final String label;
  final MixMaxButtonVariant variant;

  /// Tap handler. Null renders (and behaves as) disabled.
  final VoidCallback? onPressed;

  /// Hard override to force the disabled look even with a handler attached.
  final bool enabled;

  /// Stretch to the parent's width (default) or hug the label.
  final bool fullWidth;

  final double height;
  final double fontSize;

  /// Optional widgets flanking the label — typically an icon. They inherit the
  /// variant's foreground color and a 20px size via an [IconTheme], so a bare
  /// `Icon(...)` or `SvgPicture(...)` slots in without restating the color.
  final Widget? leading;
  final Widget? trailing;

  const MixMaxButton({
    Key? key,
    required this.label,
    this.variant = MixMaxButtonVariant.ink,
    this.onPressed,
    this.enabled = true,
    this.fullWidth = true,
    this.height = 56,
    this.fontSize = 16,
    this.leading,
    this.trailing,
  }) : super(key: key);

  bool get _isEnabled => enabled && onPressed != null;

  @override
  State<MixMaxButton> createState() => _MixMaxButtonState();
}

class _MixMaxButtonState extends State<MixMaxButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget._isEnabled;
    final style = _MixMaxButtonStyle.resolve(enabled ? widget.variant : null);

    final label = MixMaxText(
      text: widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      // Reuse the LabelText scale (sans / 600 / 16) so the button stays welded
      // to the type system; nudge tracking + collapse leading for the bar.
      style: LabelText.styleOf(fontSize: widget.fontSize, color: style.fg)
          .copyWith(letterSpacing: widget.fontSize * 0.005, height: 1),
    );

    final row = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 10)],
        Flexible(child: label),
        if (widget.trailing != null) ...[const SizedBox(width: 10), widget.trailing!],
      ],
    );

    final body = AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(_kRadius),
          border: style.border,
          boxShadow: style.shadow,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: style.fg, size: 20),
          child: row,
        ),
      ),
    );

    return GestureDetector(
      onTap: enabled ? widget.onPressed : null,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: body,
      ),
    );
  }
}

// Border radius — design token `rBtn` (theme.jsx).
const double _kRadius = 16;

/// Resolved paint for a single button variant: fill, foreground ink, optional
/// outline, and optional elevation. Mirrors `BTN_VARIANTS` in `ui.jsx`.
class _MixMaxButtonStyle {
  final Color bg;
  final Color fg;
  final Border? border;
  final List<BoxShadow>? shadow;

  const _MixMaxButtonStyle({
    required this.bg,
    required this.fg,
    this.border,
    this.shadow,
  });

  /// Pass null to get the disabled appearance.
  static _MixMaxButtonStyle resolve(MixMaxButtonVariant? variant) {
    switch (variant) {
      case MixMaxButtonVariant.ink:
        return const _MixMaxButtonStyle(
          bg: AppColors.ink,
          fg: Colors.white,
          shadow: _inkShadow,
        );
      case MixMaxButtonVariant.gold:
        return const _MixMaxButtonStyle(
          bg: AppColors.gold,
          fg: Colors.white,
          shadow: _goldShadow,
        );
      case MixMaxButtonVariant.sage:
        return const _MixMaxButtonStyle(
          bg: AppColors.sageTint,
          fg: AppColors.sageText,
        );
      case MixMaxButtonVariant.violet:
        return const _MixMaxButtonStyle(
          bg: AppColors.violetTint,
          fg: AppColors.violetText,
        );
      case MixMaxButtonVariant.ghost:
        return const _MixMaxButtonStyle(
          bg: Colors.transparent,
          fg: AppColors.ink,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.hairlineStrong, width: 1.5),
          ),
        );
      case null: // disabled
        return const _MixMaxButtonStyle(
          bg: AppColors.hairline,
          fg: AppColors.inkFaint,
        );
    }
  }

  // BTN_SHADOW — '0 1px 2px rgba(34,31,42,0.06), 0 10px 22px -14px rgba(34,31,42,0.28)'
  static const List<BoxShadow> _inkShadow = [
    BoxShadow(color: Color(0x0F221F2A), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x47221F2A), offset: Offset(0, 10), blurRadius: 22, spreadRadius: -14),
  ];

  // Gold glow — '0 1px 2px rgba(120,90,20,0.18), 0 12px 24px -14px rgba(150,110,30,0.6)'
  static const List<BoxShadow> _goldShadow = [
    BoxShadow(color: Color(0x2E785A14), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x99966E1E), offset: Offset(0, 12), blurRadius: 24, spreadRadius: -14),
  ];
}
