import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/label_text.dart';

/// The platform sign-in identities offered in the account drawer.
enum AuthButtonProvider { google, apple }

/// A platform-style sign-in button: brand mark pinned left, label centered.
///
/// Source: `design_app/drawers.jsx` `AuthButton`. Google reads as the light
/// bordered button; Apple as the ink button. Same 56px / 16px-radius bar and
/// press-scale tactility as [MixMaxButton], but with the asymmetric brand-mark
/// layout the platform guidelines ask for.
class AuthButton extends StatefulWidget {
  final AuthButtonProvider provider;
  final String label;

  /// Tap handler. Null renders (and behaves as) disabled — used while another
  /// sign-in is already in flight.
  final VoidCallback? onPressed;

  /// True while this button's own sign-in flow is running — the brand mark
  /// gives way to a spinner so the wait reads on the button that was pressed.
  final bool loading;

  const AuthButton({
    super.key,
    required this.provider,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final apple = widget.provider == AuthButtonProvider.apple;
    final enabled = widget.onPressed != null;
    final fg = apple ? Colors.white : AppColors.ink;

    final body = AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: apple ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: apple
              ? null
              : Border.all(color: AppColors.hairlineStrong, width: 1.5),
          boxShadow: apple ? _inkShadow : _googleShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 20,
              child: widget.loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(
                          apple ? Colors.white : AppColors.gold,
                        ),
                      ),
                    )
                  : apple
                      ? SvgPicture.asset(
                          'assets/svg/icons/apple_mark.svg',
                          width: 21,
                          height: 21,
                          colorFilter:
                              const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        )
                      // Multicolor brand mark — rendered untinted.
                      : SvgPicture.asset(
                          'assets/svg/icons/google_mark.svg',
                          width: 20,
                          height: 20,
                        ),
            ),
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LabelText.styleOf(fontSize: 16, color: fg)
                  .copyWith(letterSpacing: 16 * 0.005, height: 1),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: widget.onPressed,
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

// BTN_SHADOW — the ink button's elevation, as on MixMaxButton.
const List<BoxShadow> _inkShadow = [
  BoxShadow(color: Color(0x0F221F2A), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(color: Color(0x47221F2A), offset: Offset(0, 10), blurRadius: 22, spreadRadius: -14),
];

// '0 1px 2px rgba(34,31,42,0.05)' — the light button's whisper of depth.
const List<BoxShadow> _googleShadow = [
  BoxShadow(color: Color(0x0D221F2A), offset: Offset(0, 1), blurRadius: 2),
];
