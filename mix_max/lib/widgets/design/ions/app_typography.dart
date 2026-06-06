// app_typography.dart — "Quiet Instrument" typography tokens.
//
// Two families carry the whole system (declared in pubspec.yaml):
//   • Newsreader        — serif, editorial display (titles, metrics, hero copy)
//   • Schibsted Grotesk — grotesk sans, all functional UI (labels, body, meta)
//
// Both ship weights 400 / 500 / 600. Sizes are fixed (px) by design intent —
// the system is calm and editorial, not fluidly responsive. Letter-spacing in
// the source design is expressed in `em`; the atoms convert it to logical
// pixels as `fontSize * factor` so tracking stays proportional under overrides.
class AppFonts {
  /// Serif display family — Newsreader. Used for editorial headings, the big
  /// metric numerals, and any "instrument" voice copy.
  static const String serif = 'Newsreader';

  /// Grotesk UI family — Schibsted Grotesk. Used for every functional control:
  /// labels, body, captions, eyebrows, buttons, chips.
  static const String sans = 'Schibsted Grotesk';
}
