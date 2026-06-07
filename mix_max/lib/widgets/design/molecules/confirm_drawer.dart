import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/drawer_container.dart';
import 'package:mix_max/widgets/design/ions/text/caption_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';

/// A small yes/no confirmation bottom drawer in the "Quiet Instrument" system.
///
/// Source: `design_app/drawers.jsx` `DrawerShell`, trimmed to a question: a
/// [MixMaxDrawerContainer] surface, a centered serif title / soft subtitle, and
/// a pinned footer with two actions — the [confirmLabel] action and a [ghost]
/// [cancelLabel] escape.
///
/// Present it with [show], which returns `true` only if the user taps confirm;
/// dismissing the sheet (scrim tap, swipe, cancel) resolves to `false`.
class ConfirmDrawer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String confirmLabel;
  final String cancelLabel;

  /// The visual voice of the confirm action. Defaults to the primary [ink].
  final MixMaxButtonVariant confirmVariant;

  const ConfirmDrawer({
    super.key,
    required this.title,
    this.subtitle,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmVariant = MixMaxButtonVariant.ink,
  });

  /// Shows the drawer as a modal bottom sheet and resolves to the user's choice:
  /// `true` for confirm, `false` for cancel or any dismissal.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    MixMaxButtonVariant confirmVariant = MixMaxButtonVariant.ink,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ConfirmDrawer(
        title: title,
        subtitle: subtitle,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmVariant: confirmVariant,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MixMaxDrawerContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          _footer(context),
        ],
      ),
    );
  }

  // Centered serif title + soft subtitle. DrawerShell padding '14px 24px 4px'.
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
      child: Column(
        children: [
          TitleText(
            text: title,
            fontSize: 25,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            CaptionText(
              text: subtitle!,
              fontSize: 13.5,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // Pinned footer: cancel (ghost) on the left, confirm on the right.
  // DrawerShell footer padding '10px 24px 26px'.
  Widget _footer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 26),
      child: Row(
        children: [
          Expanded(
            child: MixMaxButton(
              label: cancelLabel,
              variant: MixMaxButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MixMaxButton(
              label: confirmLabel,
              variant: confirmVariant,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      ),
    );
  }
}
