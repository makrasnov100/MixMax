import 'package:flutter/material.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';
import 'package:mix_max/widgets/design/ions/app_typography.dart';
import 'package:mix_max/widgets/design/ions/format.dart';

/// Compact bounded-range visual: `[min] ——●———●—— [max]  unit`.
///
/// Source: `ui.jsx` `RangePips`. Two boxed numeral "caps" joined by a thin rail
/// with a sage end-dot at each bound, plus an optional trailing unit. Used as
/// the value preview for a number/duration parameter that has both a minimum
/// and a maximum. The rail flexes to fill the available width, so drop this in
/// an [Expanded]/row slot.
class RangePips extends StatelessWidget {
  final double? min;
  final double? max;
  final String? unit;

  /// Formats each bound's numeral. Defaults to [MixMaxFormat.number]; a
  /// duration parameter passes its own `formatDuration` so the caps read as
  /// `1m` / `10m` (in which case [unit] is left null — it's already embedded).
  final String Function(num?)? format;

  const RangePips({
    Key? key,
    required this.min,
    required this.max,
    this.unit,
    this.format,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String Function(num?) fmt =
        format ?? (num? v) => MixMaxFormat.number(v?.toDouble());
    return Row(
      children: [
        _Cap(text: fmt(min)),
        const SizedBox(width: 7),
        const Expanded(child: _Rail()),
        const SizedBox(width: 7),
        _Cap(text: fmt(max)),
        if (unit != null && unit!.isNotEmpty) ...[
          const SizedBox(width: 7),
          Text(
            unit!,
            style: const TextStyle(
              fontFamily: AppFonts.sans,
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
              color: AppColors.inkFaint,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}

/// A boxed bound value — soft inset fill, hairline ring, semibold numeral.
class _Cap extends StatelessWidget {
  final String text;

  const _Cap({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppFonts.sans,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.ink,
          height: 1,
        ),
      ),
    );
  }
}

/// The connecting rail: a 2px hairline bar with a 7px sage dot at each end.
class _Rail extends StatelessWidget {
  const _Rail();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 7,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 2.5,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.hairlineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Positioned(left: 0, top: 0, child: _Dot()),
          const Positioned(right: 0, top: 0, child: _Dot()),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: AppColors.sage,
        shape: BoxShape.circle,
      ),
    );
  }
}
