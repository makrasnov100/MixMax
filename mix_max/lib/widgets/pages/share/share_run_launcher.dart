import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mix_max/classes/schema/run.dart';
import 'package:mix_max/classes/schema/experiment.dart';
import 'package:mix_max/services/firebase/auth_service.dart';
import 'package:mix_max/services/firebase/database_service.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/text/body_text.dart';
import 'package:mix_max/widgets/pages/share/share_card.dart';

/// Renders a run as a [ShareCard] image and opens the system share sheet, with
/// no intermediate screen — the native sheet appears as soon as the user taps
/// "Share".
///
/// Used by the "Share run" action on Run Details and the "Share best run" action
/// on the Experiment Details actions sheet. It briefly shows a "Preparing…"
/// overlay while it loads the experiment's runs (to stamp the card with the
/// run's best-run flag — the same figure the run-history list derives),
/// rasterises the card crisply via a [ScreenshotController], and hands the PNG
/// to `share_plus`.
class RunShareLauncher {
  const RunShareLauncher._();

  /// Captures [run] as a share image and opens the share sheet. Shows a
  /// snackbar on failure. Safe to call straight from a drawer action.
  static Future<void> launch({
    required BuildContext context,
    required SchemaExperiment experiment,
    required SchemaRun run,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final messenger = ScaffoldMessenger.of(context);

    // Anchor the iPad share popover to the calling page, read synchronously.
    final anchor = context.findRenderObject() as RenderBox?;
    final origin = anchor != null
        ? (anchor.localToGlobal(Offset.zero) & anchor.size)
        : null;

    final progress = OverlayEntry(builder: (_) => const _PreparingOverlay());
    overlay.insert(progress);
    OverlayEntry? cardEntry;

    try {
      final figures = await _prepare(experiment, run);

      // Mount the card off-screen (but on-stage, so its SVG glyphs actually
      // paint) inside the live overlay, then capture it at full resolution.
      final controller = ScreenshotController();
      cardEntry = OverlayEntry(
        builder: (_) => Positioned(
          left: 0,
          top: -10000,
          // A transparent Material gives the card's Text widgets the ancestor
          // they need (without one, debug builds paint a yellow underline that
          // would end up in the captured image).
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              type: MaterialType.transparency,
              child: Screenshot(
                controller: controller,
                child: ShareCard(
                  experimentName: figures.name,
                  rating: figures.rating,
                  isBest: figures.isBest,
                  mix: figures.mix,
                  outcomes: figures.outcomes,
                ),
              ),
            ),
          ),
        ),
      );
      overlay.insert(cardEntry);

      // Let the off-screen card lay out and its icon assets load before capture.
      await _settle();

      final Uint8List? bytes = await controller.capture(
        pixelRatio: 3,
        delay: const Duration(milliseconds: 40),
      );
      cardEntry.remove();
      cardEntry = null;
      if (bytes == null) throw StateError('Capture returned no image.');

      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/mixmax-run.png').writeAsBytes(bytes);

      progress.remove();

      final note = figures.isBest
          ? 'My best mix for "${figures.name}" on Mix Max.'
          : 'My mix for "${figures.name}" on Mix Max.';

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: note,
        subject: 'Mix Max — ${figures.name}',
        sharePositionOrigin: origin,
      ));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not share the image.\n$e')),
      );
    } finally {
      cardEntry?.remove();
      if (progress.mounted) progress.remove();
    }
  }

  /// Waits a few frames plus a short delay so the freshly-inserted off-screen
  /// card has been laid out and its (async-loaded) SVG glyphs have painted.
  static Future<void> _settle() async {
    final binding = WidgetsBinding.instance;
    await binding.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 250));
    await binding.endOfFrame;
  }

  /// Loads the experiment's completed runs and derives the target run's
  /// best-run flag, rating and card entries. Mirrors `run_history_page`'s
  /// scoring.
  static Future<_ShareFigures> _prepare(
    SchemaExperiment experiment,
    SchemaRun run,
  ) async {
    final userId = getIt<AuthService>().user.id;
    if (userId.isEmpty || userId == 'INITIAL') {
      throw StateError('Not signed in yet. Please try again in a moment.');
    }

    final snapshot = await DatabaseService.runsRef
        .where('userId', isEqualTo: userId)
        .where('experimentId', isEqualTo: experiment.id)
        .get();

    final runs = snapshot.docs
        .map((d) => d.data())
        .where((r) => r.isValid() && r.outcomeValues != null)
        .toList();

    // Keep the target in the set even if the query lags a very recent write.
    if (!runs.any((r) => r.id == run.id)) runs.add(run);

    double scoreOf(SchemaRun r) => r.outcomes != null
        ? r.computeFinalRating()
        : r.computeFinalRating(experiment.outcomes ?? const []);
    final target = runs.firstWhere(
      (r) => r.id == run.id,
      orElse: () => run,
    );

    final ranked = [...runs]..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    final isBest = ranked.isNotEmpty && ranked.first.id == target.id;

    final params =
        target.parameters ?? experiment.parameters ?? const [];
    final outs = target.outcomes ?? experiment.outcomes ?? const [];

    return _ShareFigures(
      name: experiment.name?.isNotEmpty == true
          ? experiment.name!
          : 'Untitled experiment',
      rating: scoreOf(target) * 10,
      isBest: isBest,
      mix: ShareCard.mixFrom(params, target.parameterValues ?? const {}),
      outcomes:
          ShareCard.outcomesFrom(outs, target.outcomeValues ?? const {}),
    );
  }
}

/// Resolved figures for one share card.
class _ShareFigures {
  final String name;
  final double rating;
  final bool isBest;
  final List<ShareMixEntry> mix;
  final List<ShareOutcomeEntry> outcomes;

  const _ShareFigures({
    required this.name,
    required this.rating,
    required this.isBest,
    required this.mix,
    required this.outcomes,
  });
}

/// A dimmed, tap-blocking "Preparing your image…" overlay shown while the card
/// is being captured.
class _PreparingOverlay extends StatelessWidget {
  const _PreparingOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: AppColors.scrim),
        Center(
          // A Material ancestor so the caption renders cleanly (without one,
          // debug builds paint the yellow "missing Material" underline).
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.hairline, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(AppColors.gold),
                    ),
                  ),
                  SizedBox(width: 16),
                  BodyText(text: 'Preparing your image…', color: AppColors.ink),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
