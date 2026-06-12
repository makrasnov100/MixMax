import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/atoms/button.dart';
import 'package:mix_max/widgets/design/atoms/chip.dart';
import 'package:mix_max/widgets/design/atoms/drawer_container.dart';
import 'package:mix_max/widgets/design/atoms/icon.dart';
import 'package:mix_max/widgets/design/atoms/tile.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/design/ions/text/title_text.dart';

/// Destructive confirm before wiping the account.
///
/// Source: `design_app/drawers.jsx` `ConfirmDeleteAccountDrawer`: a centered
/// serif "Delete your account?", a danger alert [MixMaxTile], copy stressing
/// that the on-device experiment data is erased too (not just the cloud copy),
/// and a soft chip counting the experiments that go with it. The pinned footer
/// carries the danger "Delete account" commit and a ghost "Keep my account".
///
/// Nothing is deleted here — [show] resolves to `true` only when the user
/// commits; the caller runs the cloud deletion.
class ConfirmDeleteAccountDrawer extends StatelessWidget {
  final int experimentCount;

  const ConfirmDeleteAccountDrawer({super.key, required this.experimentCount});

  /// Presents the drawer; resolves to `true` only on "Delete account" —
  /// dismissing the sheet any other way resolves to `false`.
  static Future<bool> show(BuildContext context, {required int experimentCount}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ConfirmDeleteAccountDrawer(experimentCount: experimentCount),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MixMaxDrawerContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered serif title. DrawerShell padding '14px 24px 4px'.
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 14, 24, 4),
            child: TitleText(
              text: 'Delete your account?',
              fontSize: 25,
              textAlign: TextAlign.center,
            ),
          ),

          // Body: alert tile, warning blurb, experiment-count chip.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                children: [
                  const MixMaxTile(
                    glyph: MixMaxGlyph.alert,
                    tone: MixMaxTileTone.danger,
                    size: 56,
                    radius: 18,
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 322),
                    child: Text.rich(
                      TextSpan(
                        style: BodyText.styleOf(fontSize: 14.5),
                        children: const [
                          TextSpan(
                            text: 'This permanently deletes your account and erases ',
                          ),
                          TextSpan(
                            text: 'all of your experiment data',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' — including the copies saved on this '
                                'device. This can’t be undone.',
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 18),
                  MixMaxChip(
                    label: '$experimentCount experiment${experimentCount == 1 ? '' : 's'}',
                    tone: MixMaxChipTone.soft,
                    icon: MixMaxGlyph.flask,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Pinned destructive footer: delete commit + ghost escape.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MixMaxButton(
                  label: 'Delete account',
                  variant: MixMaxButtonVariant.danger,
                  onPressed: () => Navigator.of(context).pop(true),
                  leading: const MixMaxIcon(
                    MixMaxGlyph.trash,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                MixMaxButton(
                  label: 'Keep my account',
                  variant: MixMaxButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
