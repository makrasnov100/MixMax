import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mix_max/services/firebase/auth_service.dart';
import 'package:mix_max/services/general_info_service.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/services/ui/link_service.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/drawer_container.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tap_ripple.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/label_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';
import 'package:mix_max/widgets/pages/account/auth_button.dart';

/// How the account drawer was dismissed, for the caller to act on.
enum AccountDrawerResult {
  /// The user picked how to use the app (guest, Google or Apple) — a gated
  /// "New experiment" can now proceed.
  chose,

  /// The user signed out (back to a fresh guest account).
  signedOut,

  /// The user asked to delete the account; the caller shows the confirm drawer.
  deleteRequested,
}

/// The account bottom drawer.
///
/// Source: `design_app/drawers.jsx` `AccountDrawer`. Three voices off one
/// surface, derived live from [AuthService]:
///  • signed out, never chose — "Let's begin": Google / Apple / guest gate;
///  • guest — "Save your progress": the same sign-in options, no guest row;
///  • signed in — "Your account": account card, sign out, delete-account link.
///
/// The sign-in buttons run the real [AuthService] flows; the legal fine print
/// links to the Terms of Service / Privacy Policy from [GeneralInfoService] —
/// which is why anonymous (guest) sign-up happens here and not at app launch.
/// On Android only Google is offered; Apple shows on iOS.
class AccountDrawer extends StatefulWidget {
  const AccountDrawer({super.key});

  /// Presents the drawer and resolves to how it was dismissed (null when simply
  /// closed).
  static Future<AccountDrawerResult?> show(BuildContext context) {
    return showModalBottomSheet<AccountDrawerResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AccountDrawer(),
    );
  }

  @override
  State<AccountDrawer> createState() => _AccountDrawerState();
}

class _AccountDrawerState extends State<AccountDrawer> {
  late final AuthService _authService;

  /// True while a sign-in / sign-out is in flight. The drawer swaps its body
  /// for an in-place spinner ([_loadingBody]) and a [PopScope] keeps it open
  /// until the operation settles, so the loading state lives in the drawer
  /// rather than as a separate full-screen overlay.
  bool _busy = false;

  /// What the in-drawer spinner says while [_busy] (e.g. 'Signing in…').
  String? _busyMessage;

  /// Inline failure message under the actions (a snackbar would hide behind
  /// the modal sheet).
  String? _error;

  @override
  void initState() {
    super.initState();
    _authService = getIt<AuthService>();
  }

  Future<void> _signIn(AuthButtonProvider provider) async {
    setState(() {
      _busy = true;
      _busyMessage = 'Signing in…';
      _error = null;
    });

    final result = await (provider == AuthButtonProvider.google
        ? _authService.signInWithGoogle()
        : _authService.signInWithApple());
    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pop(AccountDrawerResult.chose);
      return;
    }
    // Failure: drop the spinner and offer the sign-in options again.
    setState(() {
      _busy = false;
      _busyMessage = null;
      // A null auth token means the user dismissed the platform sheet — that's
      // a cancel, not an error worth surfacing.
      _error = result.message.contains('Auth token is null') ? null : result.message;
    });
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _busy = true;
      _busyMessage = 'Setting up your account…';
      _error = null;
    });

    final success = await _authService.signInAsGuest();
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(AccountDrawerResult.chose);
      return;
    }
    setState(() {
      _busy = false;
      _busyMessage = null;
      _error = 'Could not continue as guest. Please try again.';
    });
  }

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _busyMessage = 'Signing out…';
    });
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pop(AccountDrawerResult.signedOut);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _authService.isSignedIn();

    return PopScope(
      // Block dismissal (back gesture / barrier tap) while an auth call is in
      // flight, so the in-drawer spinner can't be swiped away mid-operation.
      canPop: !_busy,
      child: MixMaxDrawerContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(signedIn: signedIn, guest: _authService.isGuest),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
                child: _busy
                    ? _loadingBody()
                    : (signedIn ? _signedInBody() : _signedOutBody()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── In-flight: a centered spinner + message that lives inside the drawer
  //    surface, replacing the action buttons (no full-screen overlay). ──
  Widget _loadingBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Column(
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          const SizedBox(height: 16),
          CaptionText(
            text: _busyMessage ?? 'Working…',
            fontSize: 14,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Centered serif title + soft subtitle. DrawerShell padding '14px 24px 4px'.
  Widget _header({required bool signedIn, required bool guest}) {
    final String title;
    final String subtitle;
    if (signedIn) {
      title = 'Your account';
      subtitle = 'Signed in & synced to the cloud';
    } else if (guest) {
      title = 'Save your progress';
      subtitle = "You're not signed in";
    } else {
      title = "Let's begin";
      subtitle = 'Choose how to use the app.';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
      child: Column(
        children: [
          TitleText(text: title, fontSize: 25, textAlign: TextAlign.center),
          const SizedBox(height: 3),
          CaptionText(text: subtitle, fontSize: 13.5, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Not signed in: a guest sees the upgrade prompt; a brand-new user who
  //    hasn't chosen yet must pick how to use the app. ──
  Widget _signedOutBody() {
    final guest = _authService.isGuest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CloudSyncCard(),
        const SizedBox(height: 18),
        AuthButton(
          provider: AuthButtonProvider.google,
          label: 'Continue with Google',
          onPressed: _busy ? null : () => _signIn(AuthButtonProvider.google),
        ),
        // Apple sign-in is an iOS affordance — Android offers Google only.
        if (Platform.isIOS) ...[
          const SizedBox(height: 10),
          AuthButton(
            provider: AuthButtonProvider.apple,
            label: 'Continue with Apple',
            onPressed: _busy ? null : () => _signIn(AuthButtonProvider.apple),
          ),
        ],
        if (!guest) ...[
          const _OrDivider(),
          _GuestButton(onPressed: _busy ? null : _continueAsGuest),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          CaptionText(
            text: _error!,
            fontSize: 13,
            color: AppColors.danger,
            textAlign: TextAlign.center,
          ),
        ],
        const _LegalLine(),
        const SizedBox(height: 6),
      ],
    );
  }

  // ── Signed in: sign out (primary) + a smaller delete-account link. ──
  Widget _signedInBody() {
    final email = _email();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.hairline, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.goldTint,
                  shape: BoxShape.circle,
                ),
                child: const MixMaxIcon(MixMaxGlyph.user, size: 24, color: AppColors.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LabelText(
                      text: 'Mix Max Standard',
                      fontSize: 16,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    CaptionText(
                      text: email,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        MixMaxButton(
          label: 'Sign out',
          variant: MixMaxButtonVariant.ghost,
          enabled: !_busy,
          onPressed: _signOut,
          leading: const MixMaxIcon(MixMaxGlyph.signout, size: 20, color: AppColors.ink),
        ),
        const SizedBox(height: 14),
        Center(
          child: MixMaxInk(
            onTap: _busy
                ? null
                : () => Navigator.of(context).pop(AccountDrawerResult.deleteRequested),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                'Delete account',
                style: LabelText.styleOf(fontSize: 13.5, color: AppColors.danger),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// The line under "Mix Max Standard" — the account's email, with a provider
  /// fallback when none is exposed (e.g. a hidden Apple relay address).
  String _email() {
    final email = _authService.user.email ?? _authService.firebaseUser?.email;
    if (email != null && email.isNotEmpty) return email;
    return _authService.lastProvider == AcceptedProviders.apple
        ? 'Signed in with Apple'
        : 'Signed in with Google';
  }
}

/// The gold "Synced across your devices" explainer card above the sign-in
/// buttons. Source: the goldTint flex card in `AccountDrawer` (drawers.jsx).
class _CloudSyncCard extends StatelessWidget {
  const _CloudSyncCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MixMaxTile(glyph: MixMaxGlyph.cloud, tone: MixMaxTileTone.gold, size: 42),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LabelText(text: 'Synced across your devices', fontSize: 15),
                const SizedBox(height: 3),
                Text(
                  'Your experiments are always backed up in the cloud. Sign in '
                  'to reach them from any device and keep them if you switch phones.',
                  style: CaptionText.styleOf(
                    fontSize: 13.5,
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w400,
                  ).copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "or" rule between the platform sign-in buttons and the guest option.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: ColoredBox(color: AppColors.hairline, child: SizedBox(height: 1))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'OR',
              style: LabelText.styleOf(fontSize: 12, color: AppColors.inkFaint)
                  .copyWith(letterSpacing: 12 * 0.1),
            ),
          ),
          const Expanded(child: ColoredBox(color: AppColors.hairline, child: SizedBox(height: 1))),
        ],
      ),
    );
  }
}

/// "Continue as guest" — outlined like a ghost button but voiced in the softer
/// secondary ink, with a trailing arrow. Source: `GuestButton` (drawers.jsx).
class _GuestButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _GuestButton({this.onPressed});

  @override
  State<_GuestButton> createState() => _GuestButtonState();
}

class _GuestButtonState extends State<_GuestButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.hairlineStrong, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue as guest',
                  style: LabelText.styleOf(fontSize: 16, color: AppColors.inkSoft)
                      .copyWith(letterSpacing: 16 * 0.005, height: 1),
                ),
                const SizedBox(width: 8),
                const MixMaxIcon(MixMaxGlyph.arrowRight, size: 19, color: AppColors.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fine print under the sign-in buttons; the two phrases are live links to the
/// URLs synced by [GeneralInfoService]. Source: `LegalLine` (drawers.jsx).
class _LegalLine extends StatefulWidget {
  const _LegalLine();

  @override
  State<_LegalLine> createState() => _LegalLineState();
}

class _LegalLineState extends State<_LegalLine> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    final info = getIt<GeneralInfoService>();
    _termsTap = TapGestureRecognizer()..onTap = () => launchLink(info.termsOfService);
    _privacyTap = TapGestureRecognizer()..onTap = () => launchLink(info.privacyPolicy);
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = LabelText.styleOf(fontSize: 12.5, color: AppColors.goldText).copyWith(
      decoration: TextDecoration.underline,
      decorationColor: AppColors.hairlineStrong,
      height: 1.55,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 16, 6, 0),
      child: Text.rich(
        TextSpan(
          style: CaptionText.styleOf(
            fontSize: 12.5,
            color: AppColors.inkFaint,
            fontWeight: FontWeight.w400,
          ).copyWith(height: 1.55),
          children: [
            const TextSpan(text: 'By continuing you agree to our '),
            TextSpan(text: 'Terms of Service', style: linkStyle, recognizer: _termsTap),
            const TextSpan(text: ' and '),
            TextSpan(text: 'Privacy Policy', style: linkStyle, recognizer: _privacyTap),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
