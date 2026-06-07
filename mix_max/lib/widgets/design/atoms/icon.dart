import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mix_max/widgets/design/ions/app_colors.dart';

/// The "Quiet Instrument" line-icon set (source: `icons.jsx`).
///
/// Type-safe handle for each glyph in `assets/svg/icons/`. The icons are
/// authored as single-color strokes with `currentColor`, so [MixMaxIcon] tints
/// them at render time — pick the glyph here, set the color on the widget.
enum MixMaxGlyph {
  hash,
  timer,
  toggle,
  list,
  order,
  up,
  down,
  play,
  plus,
  chevRight,
  chevLeft,
  arrowRight,
  arrowLeft,
  check,
  close,
  sparkle,
  spark2,
  flask,
  beaker,
  edit,
  grip,
  info,
  target,
  trophy,
  ruler,
  bag,
  trash,
  clock,
  more,
  alert,
}

/// Asset basename per glyph. Kept explicit (rather than derived from `.name`)
/// so the renamed entries — chevRight → chev_right, close → close (was `x`) —
/// stay unambiguous and a typo can't silently point at a missing file.
const Map<MixMaxGlyph, String> _glyphAsset = {
  MixMaxGlyph.hash: 'hash',
  MixMaxGlyph.timer: 'timer',
  MixMaxGlyph.toggle: 'toggle',
  MixMaxGlyph.list: 'list',
  MixMaxGlyph.order: 'order',
  MixMaxGlyph.up: 'up',
  MixMaxGlyph.down: 'down',
  MixMaxGlyph.play: 'play',
  MixMaxGlyph.plus: 'plus',
  MixMaxGlyph.chevRight: 'chev_right',
  MixMaxGlyph.chevLeft: 'chev_left',
  MixMaxGlyph.arrowRight: 'arrow_right',
  MixMaxGlyph.arrowLeft: 'arrow_left',
  MixMaxGlyph.check: 'check',
  MixMaxGlyph.close: 'close',
  MixMaxGlyph.sparkle: 'sparkle',
  MixMaxGlyph.spark2: 'spark2',
  MixMaxGlyph.flask: 'flask',
  MixMaxGlyph.beaker: 'beaker',
  MixMaxGlyph.edit: 'edit',
  MixMaxGlyph.grip: 'grip',
  MixMaxGlyph.info: 'info',
  MixMaxGlyph.target: 'target',
  MixMaxGlyph.trophy: 'trophy',
  MixMaxGlyph.ruler: 'ruler',
  MixMaxGlyph.bag: 'bag',
  MixMaxGlyph.trash: 'trash',
  MixMaxGlyph.clock: 'clock',
  MixMaxGlyph.more: 'more',
  MixMaxGlyph.alert: 'alert',
};

/// A single line icon, sized square and tinted to one color.
///
/// Source: `icons.jsx` `Icon`. Note the stroke weight is baked into the SVGs
/// (2.0) — unlike the JS version it is not a render-time knob, a tradeoff of
/// the asset-based approach. Size and color are fully dynamic.
class MixMaxIcon extends StatelessWidget {
  final MixMaxGlyph glyph;
  final double size;
  final Color color;

  const MixMaxIcon(
    this.glyph, {
    Key? key,
    this.size = 22,
    this.color = AppColors.ink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/icons/${_glyphAsset[glyph]}.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
