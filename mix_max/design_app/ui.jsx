// ui.jsx — Mix Max UI primitives

// ── Layout ───────────────────────────────────────────────
// A screen = full-height column: scrollable body + sticky footer actions.
function Screen({ children, footer, footerTone }) {
  return (
    <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', background: T.bg }}>
      <div className="mm-scroll" style={{ flex: 1, overflowY: 'auto', overflowX: 'hidden' }}>
        {children}
      </div>
      {footer && (
        <div style={{
          flexShrink: 0,
          padding: '14px 20px 30px',
          background: `linear-gradient(180deg, rgba(251,247,240,0) 0%, ${T.bg} 22%)`,
        }}>
          {footer}
        </div>
      )}
    </div>
  );
}

// top padding so content clears the status bar / dynamic island
function TopPad({ h = 58 }) { return <div style={{ height: h }} />; }

// ── Type ─────────────────────────────────────────────────
function Display({ children, size = 38, style }) {
  return (
    <h1 style={{
      margin: 0, fontFamily: T.serif, fontWeight: 500, fontSize: size,
      lineHeight: 1.04, letterSpacing: '-0.015em', color: T.ink,
      ...style,
    }}>{children}</h1>
  );
}

function Eyebrow({ children, color = T.inkFaint, style }) {
  return (
    <div style={{
      fontFamily: T.sans, fontWeight: 600, fontSize: 11.5,
      letterSpacing: '0.12em', textTransform: 'uppercase', color, ...style,
    }}>{children}</div>
  );
}

function SectionLabel({ children, count }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 9, marginBottom: 4 }}>
      <span style={{ fontFamily: T.serif, fontStyle: 'italic', fontWeight: 500, fontSize: 21, color: T.ink, whiteSpace: 'nowrap' }}>{children}</span>
      {count !== undefined && (
        <span style={{ fontFamily: T.sans, fontSize: 13, fontWeight: 600, color: T.inkFaint }}>{count}</span>
      )}
    </div>
  );
}

// ── Buttons ──────────────────────────────────────────────
const BTN_VARIANTS = {
  ink:    { bg: T.ink,        fg: '#FFFFFF',     sh: BTN_SHADOW, bd: 'none' },
  gold:   { bg: T.gold,       fg: '#FFFFFF',     sh: '0 1px 2px rgba(120,90,20,0.18), 0 12px 24px -14px rgba(150,110,30,0.6)', bd: 'none' },
  sage:   { bg: T.sageTint,   fg: T.sageText,    sh: 'none', bd: 'none' },
  violet: { bg: T.violetTint, fg: T.violetText,  sh: 'none', bd: 'none' },
  ghost:  { bg: 'transparent',fg: T.ink,         sh: 'none', bd: `1.5px solid ${T.hairlineStrong}` },
  danger: { bg: T.danger,     fg: '#FFFFFF',     sh: '0 1px 2px rgba(120,40,25,0.18), 0 12px 24px -14px rgba(150,55,35,0.6)', bd: 'none' },
  disabled:{bg: '#ECE6DA',    fg: T.inkFaint,    sh: 'none', bd: 'none' },
};

function Btn({ label, icon, iconR, variant = 'ink', onClick, disabled, full = true, height = 56, fontSize = 16 }) {
  const v = BTN_VARIANTS[disabled ? 'disabled' : variant];
  return (
    <button
      onClick={disabled ? undefined : onClick}
      style={{
        width: full ? '100%' : 'auto', height,
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
        background: v.bg, color: v.fg, border: v.bd, boxShadow: v.sh,
        borderRadius: T.rBtn, padding: '0 22px',
        fontFamily: T.sans, fontWeight: 600, fontSize, letterSpacing: '0.005em',
        cursor: disabled ? 'default' : 'pointer',
        transition: 'transform .12s ease, box-shadow .12s ease, opacity .12s ease',
        WebkitTapHighlightColor: 'transparent',
      }}
      onMouseDown={e => !disabled && (e.currentTarget.style.transform = 'scale(0.985)')}
      onMouseUp={e => (e.currentTarget.style.transform = 'scale(1)')}
      onMouseLeave={e => (e.currentTarget.style.transform = 'scale(1)')}
    >
      {icon && <Icon name={icon} size={20} color={v.fg} stroke={2} />}
      <span style={{ whiteSpace: 'nowrap' }}>{label}</span>
      {iconR && <Icon name={iconR} size={20} color={v.fg} stroke={2} />}
    </button>
  );
}

// circular icon button (back, edit etc.)
function RoundBtn({ icon, onClick, size = 40, tone = 'neutral' }) {
  const map = {
    neutral: { bg: T.surface, fg: T.ink, bd: T.hairline },
    bare:    { bg: 'transparent', fg: T.ink, bd: 'transparent' },
  };
  const m = map[tone] || map.neutral;
  return (
    <button onClick={onClick} style={{
      width: size, height: size, borderRadius: 999, flexShrink: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: m.bg, border: `1px solid ${m.bd}`, cursor: 'pointer',
      boxShadow: tone === 'neutral' ? '0 1px 2px rgba(34,31,42,0.05)' : 'none',
      WebkitTapHighlightColor: 'transparent',
    }}>
      <Icon name={icon} size={20} color={m.fg} stroke={2} />
    </button>
  );
}

// ── Tinted icon tile ─────────────────────────────────────
const TILE_TONES = {
  sage:    { bg: T.sageTint,   fg: T.sage },
  violet:  { bg: T.violetTint, fg: T.violet },
  gold:    { bg: T.goldTint,   fg: T.gold },
  neutral: { bg: T.bgAlt,      fg: T.inkSoft },
  danger:  { bg: T.dangerTint, fg: T.danger },
  ink:     { bg: '#2A2632',    fg: '#F4EBD4' },
};
function Tile({ icon, tone = 'sage', size = 44, radius = T.rTile, stroke = 1.9 }) {
  const t = TILE_TONES[tone] || TILE_TONES.sage;
  return (
    <div style={{
      width: size, height: size, borderRadius: radius, flexShrink: 0,
      background: t.bg, display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <Icon name={icon} size={Math.round(size * 0.5)} color={t.fg} stroke={stroke} />
    </div>
  );
}

// ── Chips / tags ─────────────────────────────────────────
const CHIP_TONES = {
  soft:    { bg: T.bgAlt,      fg: T.inkSoft,   bd: 'transparent' },
  gold:    { bg: T.goldTint,   fg: T.goldText,  bd: 'transparent' },
  sage:    { bg: T.sageTint,   fg: T.sageText,  bd: 'transparent' },
  violet:  { bg: T.violetTint, fg: T.violetText,bd: 'transparent' },
  outline: { bg: T.surface,    fg: T.inkSoft,   bd: T.hairlineStrong },
};
function Chip({ children, tone = 'soft', icon, onClose, style }) {
  const c = CHIP_TONES[tone] || CHIP_TONES.soft;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      background: c.bg, color: c.fg, border: `1px solid ${c.bd}`,
      borderRadius: 999, padding: onClose ? '6px 8px 6px 12px' : '5px 11px',
      fontFamily: T.sans, fontWeight: 600, fontSize: 12.5, letterSpacing: '0.01em',
      whiteSpace: 'nowrap', ...style,
    }}>
      {icon && <Icon name={icon} size={13} color={c.fg} stroke={2.2} />}
      {children}
      {onClose && (
        <button onClick={onClose} style={{
          border: 'none', background: 'rgba(0,0,0,0.05)', borderRadius: 999,
          width: 18, height: 18, display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer', padding: 0,
        }}>
          <Icon name="x" size={11} color={c.fg} stroke={2.4} />
        </button>
      )}
    </span>
  );
}

// ── Small data visuals ───────────────────────────────────
// compact range: [min] ——— [max] with optional unit
function RangePips({ min, max, unit, step }) {
  const cap = (txt) => (
    <span style={{
      fontFamily: T.sans, fontWeight: 600, fontSize: 13, color: T.ink,
      background: T.surfaceSoft, border: `1px solid ${T.hairline}`,
      borderRadius: 8, padding: '2px 8px',
    }}>{txt}</span>
  );
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
      {cap(fmt(min))}
      <span style={{ flex: 1, minWidth: 18, height: 2, borderRadius: 2, background: T.hairlineStrong, position: 'relative' }}>
        <span style={{ position: 'absolute', left: 0, top: -2.5, width: 7, height: 7, borderRadius: 999, background: T.sage }} />
        <span style={{ position: 'absolute', right: 0, top: -2.5, width: 7, height: 7, borderRadius: 999, background: T.sage }} />
      </span>
      {cap(fmt(max))}
      {unit && <span style={{ fontFamily: T.sans, fontSize: 12.5, color: T.inkFaint, fontWeight: 500 }}>{unit}</span>}
      {step != null && step > 0 && (
        <span style={{ fontFamily: T.sans, fontSize: 12, color: T.inkFaint, fontWeight: 500, whiteSpace: 'nowrap' }}>· step {fmt(step)}</span>
      )}
    </div>
  );
}

// mini on/off switch graphic (illustrative)
function MiniSwitch({ on = true }) {
  return (
    <div style={{
      width: 40, height: 24, borderRadius: 999, padding: 3,
      background: on ? T.sage : T.hairlineStrong,
      display: 'flex', alignItems: 'center', justifyContent: on ? 'flex-end' : 'flex-start',
      transition: 'background .15s',
    }}>
      <div style={{ width: 18, height: 18, borderRadius: 999, background: '#fff', boxShadow: '0 1px 2px rgba(0,0,0,0.2)' }} />
    </div>
  );
}

// horizontal option chip row with overflow "+N"
function OptionPreview({ options = [], max = 3, tone = 'soft' }) {
  const shown = options.slice(0, max);
  const extra = options.length - shown.length;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
      {shown.map((o, i) => <Chip key={i} tone={tone}>{o}</Chip>)}
      {extra > 0 && <span style={{ fontFamily: T.sans, fontSize: 12.5, fontWeight: 600, color: T.inkFaint }}>+{extra}</span>}
    </div>
  );
}

// order sequence: a → b → c
function OrderPreview({ items = [] }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 5, flexWrap: 'wrap' }}>
      {items.map((it, i) => (
        <React.Fragment key={i}>
          <Chip tone="soft">{it}</Chip>
          {i < items.length - 1 && <Icon name="arrowR" size={13} color={T.inkFaint} stroke={2} />}
        </React.Fragment>
      ))}
    </div>
  );
}

// progress dots (rating screen)
function ProgressDots({ total, index }) {
  return (
    <div style={{ display: 'flex', gap: 6 }}>
      {Array.from({ length: total }).map((_, i) => (
        <div key={i} style={{
          height: 5, borderRadius: 999,
          width: i === index ? 22 : 5,
          background: i === index ? T.gold : (i < index ? T.sage : T.hairlineStrong),
          transition: 'all .2s',
        }} />
      ))}
    </div>
  );
}

Object.assign(window, {
  Screen, TopPad, Display, Eyebrow, SectionLabel,
  Btn, RoundBtn, Tile, Chip,
  RangePips, MiniSwitch, OptionPreview, OrderPreview, ProgressDots,
});
