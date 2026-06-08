// theme.jsx — Mix Max design tokens ("Quiet Instrument")
// Editorial / calm / premium. Warm off-white, near-black ink, gold signature,
// muted sage (parameters) + violet (outcomes). Serif display + grotesk UI.

const T = {
  // surfaces
  bg:          '#FBF7F0',  // warm off-white app background
  bgAlt:       '#F4EEE3',  // slightly deeper warm
  surface:     '#FFFFFF',  // cards
  surfaceSoft: '#FBF8F2',  // inset fields
  scrim:       'rgba(28,24,20,0.42)',

  // ink
  ink:      '#221F2A',  // primary text / commit buttons
  inkSoft:  '#6E6A75',  // secondary text
  inkFaint: '#A9A4AE',  // placeholders / tertiary
  hairline: '#ECE6DA',  // warm borders
  hairlineStrong: '#E0D9CB',

  // signature
  gold:     '#B5872B',  // optimization / run / active
  goldDeep: '#8A6519',
  goldTint: '#F4EBD4',  // gold soft background
  goldText: '#7C5C16',

  // parameters (sage)
  sage:     '#6E8A63',
  sageTint: '#E9EFE3',
  sageText: '#4C6743',

  // outcomes (violet)
  violet:     '#7E719A',
  violetTint: '#ECE7F2',
  violetText: '#5A4E78',

  // status
  danger:     '#C0492F',
  dangerTint: '#F6E3DC',
  dangerText: '#9A3A24',

  // fonts
  serif: '"Newsreader", Georgia, serif',
  sans:  '"Schibsted Grotesk", system-ui, sans-serif',

  // radius
  rTile: 13,
  rCard: 20,
  rField: 14,
  rBtn: 16,
  rPill: 999,
  rDrawer: 30,
};

// soft card shadow used sparingly on white cards over warm bg
const CARD_SHADOW = '0 1px 2px rgba(34,31,42,0.04), 0 8px 22px -12px rgba(34,31,42,0.10)';
const BTN_SHADOW  = '0 1px 2px rgba(34,31,42,0.06), 0 10px 22px -14px rgba(34,31,42,0.28)';

// parameter type metadata (icon key + human label). All sage-categorized.
const PARAM_TYPES = {
  number:   { label: 'Number',   icon: 'hash',     blurb: 'A measured amount' },
  duration: { label: 'Duration', icon: 'timer',    blurb: 'A length of time' },
  toggle:   { label: 'Toggle',   icon: 'toggle',   blurb: 'On or off' },
  choice:   { label: 'Choice',   icon: 'list',     blurb: 'Pick from options' },
  order:    { label: 'Order',    icon: 'order',    blurb: 'A sequence' },
};

// format a number nicely (drop trailing .0)
function fmt(v, dp) {
  if (v === null || v === undefined || isNaN(v)) return '—';
  const r = dp === undefined ? v : Number(v.toFixed(dp));
  return r === Math.trunc(r) ? String(Math.trunc(r)) : String(r);
}

// toggle-state labels: the parameter's custom on/off labels, falling back to
// the 'On' / 'Off' defaults when none is set.
function onLabelOf(p) {
  const v = p && p.onLabel != null ? String(p.onLabel).trim() : '';
  return v || 'On';
}
function offLabelOf(p) {
  const v = p && p.offLabel != null ? String(p.offLabel).trim() : '';
  return v || 'Off';
}

Object.assign(window, { T, CARD_SHADOW, BTN_SHADOW, PARAM_TYPES, fmt, onLabelOf, offLabelOf });
