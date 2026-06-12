// appstore.jsx — Mix Max App Store screenshots
// Five 1290×2796 marketing frames, each pairing a real app screen
// (pre-filled with seed data) with a headline that frames the story.

const _N = Math.floor(Date.now() / 1000);
const _DAY = 86400;

// ── seed data (same world as the prototype) ──────────────
const RAW = [
  {
    id: 'best-tea', name: 'Best Tea',
    parameters: [
      { id: 'p1', name: 'Ounces of water', type: 'number', unit: 'oz', min: 10, max: 12, increment: 0.5 },
      { id: 'p2', name: 'Steep time', type: 'duration', unit: 'minutes', min: 1, max: 10, increment: 0.5 },
      { id: 'p3', name: 'Squeeze bag after steeping', type: 'toggle', onLabel: 'Squeeze', offLabel: 'Leave' },
      { id: 'p4', name: 'Sweetener', type: 'choice', options: ['honey', 'sugar', 'none'] },
    ],
    outcomes: [
      { id: 'o1', name: 'taste', min: 1, max: 10, step: 1, goal: 'maximize' },
      { id: 'o2', name: 'smell', min: 1, max: 10, step: 1, goal: 'maximize' },
      { id: 'o3', name: 'appearance', min: 1, max: 10, step: 1, goal: 'maximize' },
    ],
    runs: [
      { id: 'r1', parameterValues: { p1: 11, p2: 3, p3: false, p4: 'honey' }, outcomeValues: { o1: 5, o2: 6, o3: 5 }, createdAt: _N - 12 * _DAY - 2400, completedAt: _N - 12 * _DAY },
      { id: 'r2', parameterValues: { p1: 10.5, p2: 5, p3: true, p4: 'honey' }, outcomeValues: { o1: 8, o2: 7, o3: 6 }, createdAt: _N - 5 * _DAY - 1800, completedAt: _N - 5 * _DAY },
      { id: 'r3', parameterValues: { p1: 12, p2: 4, p3: true, p4: 'sugar' }, outcomeValues: { o1: 6, o2: 6, o3: 7 }, createdAt: _N - 1 * _DAY - 3000, completedAt: _N - 1 * _DAY },
    ],
  },
  {
    id: 'cold-brew', name: 'House Cold Brew',
    parameters: [
      { id: 'cp1', name: 'Coffee grounds', type: 'number', unit: 'g', min: 60, max: 120, increment: 5 },
      { id: 'cp2', name: 'Brew time', type: 'duration', unit: 'hours', min: 8, max: 24, increment: 1 },
      { id: 'cp3', name: 'Grind', type: 'choice', options: ['coarse', 'medium', 'fine'] },
    ],
    outcomes: [
      { id: 'co1', name: 'strength', min: 1, max: 10, step: 1, goal: 'maximize' },
      { id: 'co2', name: 'bitterness', min: 1, max: 10, step: 1, goal: 'minimize' },
    ],
    runs: [
      { id: 'cr1', parameterValues: { cp1: 90, cp2: 16, cp3: 'medium' }, outcomeValues: { co1: 7, co2: 4 }, createdAt: _N - 8 * _DAY - 1200, completedAt: _N - 8 * _DAY },
      { id: 'cr2', parameterValues: { cp1: 100, cp2: 12, cp3: 'coarse' }, outcomeValues: { co1: 6, co2: 6 }, createdAt: _N - 3 * _DAY - 1200, completedAt: _N - 3 * _DAY },
    ],
  },
  {
    id: 'run-routine', name: 'Pre-Run Routine',
    parameters: [
      { id: 'rp1', name: 'Warm-up', type: 'duration', unit: 'minutes', min: 0, max: 20, increment: 1 },
      { id: 'rp2', name: 'Caffeine', type: 'toggle', onLabel: 'Yes', offLabel: 'No' },
    ],
    outcomes: [{ id: 'ro1', name: 'energy', min: 1, max: 10, step: 1, goal: 'maximize' }],
    runs: [{ id: 'rr1', parameterValues: { rp1: 8, rp2: true }, outcomeValues: { ro1: 7 }, createdAt: _N - 2 * _DAY, completedAt: _N - 2 * _DAY }],
  },
];

const DATA = RAW.map(e => ({
  ...e,
  runs: (e.runs || []).map(r => ({ params: e.parameters.map(p => ({ ...p })), outcomes: e.outcomes.map(o => ({ ...o })), ...r })),
}));
const byId = (id) => DATA.find(e => e.id === id);
const NOOP = () => {};

// ── device wrapper, scaled into a marketing frame ────────
function Phone({ scale = 2.3, children }) {
  const W = 402, H = 874;
  return (
    <div style={{ width: W * scale, height: H * scale, flexShrink: 0 }}>
      <div style={{ width: W, height: H, transform: `scale(${scale})`, transformOrigin: 'top left' }}>
        <IOSDevice statusBar={false}>
          <div style={{ position: 'absolute', inset: 0, overflow: 'hidden' }}>
            {/* status bar removed for store shots — pull screens up over the unused safe area */}
            <div style={{ position: 'absolute', left: 0, right: 0, top: -40, bottom: 0 }}>{children}</div>
          </div>
        </IOSDevice>
      </div>
    </div>
  );
}

// ── one App Store frame: one big headline + device on a warm field ─
const ACCENTS = {
  gold:   { tint: T.goldTint,   ring: 'rgba(181,135,43,0.38)',  dot: T.gold },
  sage:   { tint: T.sageTint,   ring: 'rgba(110,138,99,0.38)',  dot: T.sage },
  violet: { tint: T.violetTint, ring: 'rgba(126,113,154,0.38)', dot: T.violet },
};

function Frame({ title, accent = 'gold', flip = false, phoneScale = 2.85, phoneTop = 546, children }) {
  const a = ACCENTS[accent] || ACCENTS.gold;
  const x = (v) => (flip ? 1290 - v : v); // mirror shape positions for variety
  return (
    <div style={{
      width: 1290, height: 2796, position: 'relative', overflow: 'hidden',
      background: 'radial-gradient(125% 70% at 50% -8%, #F3EDE1 0%, #E9E2D4 58%, #DED5C5 100%)',
      fontFamily: T.sans,
    }}>
      {/* decorative shapes — big tinted circle, a thin ring, a small dot */}
      <div style={{
        position: 'absolute', width: 1760, height: 1760, borderRadius: '50%',
        left: x(flip ? 1290 - 980 : 980) - 880, top: 1180, background: a.tint, opacity: 0.85,
      }} />
      <div style={{
        position: 'absolute', width: 620, height: 620, borderRadius: '50%',
        left: x(190) - 310, top: 520, border: `3px solid ${a.ring}`,
      }} />
      <div style={{
        position: 'absolute', width: 56, height: 56, borderRadius: '50%',
        left: x(1140) - 28, top: 760, background: a.dot, opacity: 0.55,
      }} />
      {/* fine top rule */}
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 6, background: T.gold, opacity: 0.9 }} />

      {/* single headline — vertically centered in the band above the phone */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: phoneTop,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        padding: '30px 100px 0', boxSizing: 'border-box', textAlign: 'center',
      }}>
        <div style={{
          fontFamily: T.serif, fontWeight: 500, fontSize: 128, lineHeight: 1.04,
          letterSpacing: '-0.02em', color: T.ink, textWrap: 'balance',
        }}>{title}</div>
      </div>

      {/* device — large, bleeding off the bottom edge; fixed top so all frames align */}
      <div style={{ position: 'absolute', top: phoneTop, left: 0, right: 0, display: 'flex', justifyContent: 'center' }}>
        <Phone scale={phoneScale}>{children}</Phone>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════
// the five panels
// ════════════════════════════════════════════════════════
const tea = byId('best-tea');
const teaBestRun = (() => { const id = bestRunId(tea); return (tea.runs || []).find(r => r.id === id); })();
const teaBestNum = (() => {
  const chrono = (tea.runs || []).filter(r => r.outcomeValues).sort((a, b) => (a.completedAt || 0) - (b.completedAt || 0));
  return chrono.findIndex(r => r.id === teaBestRun.id) + 1;
})();
const teaSuggestion = { p1: 10.5, p2: 5.5, p3: true, p4: 'honey' };

const PANELS = [
  {
    id: 'experiments',
    label: 'Experiments',
    frame: (
      <Frame accent="gold" phoneTop={700}
        title={<span>Find the best version of <span style={{ fontStyle: 'italic' }}>anything.</span></span>}>
        <ExperimentsListScreen experiments={DATA} onOpen={NOOP} onAdd={NOOP} />
      </Frame>
    ),
  },
  {
    id: 'tune',
    label: 'Parameters & outcomes',
    frame: (
      <Frame accent="sage" flip
        title={<span>Tune the knobs.</span>}>
        <ExperimentDetailsScreen exp={tea} onBack={NOOP} onRename={NOOP} onAddParam={NOOP} onAddOutput={NOOP}
          onRun={NOOP} onMenu={NOOP} onHistory={NOOP} onOpenBest={NOOP} onEditParam={NOOP} onEditOutput={NOOP} />
      </Frame>
    ),
  },
  {
    id: 'suggest',
    label: 'Smart suggestion',
    frame: (
      <Frame accent="gold"
        title={<span>It picks your<br/>next move.</span>}>
        <RunSuggestionScreen exp={tea} suggestion={teaSuggestion} onBack={NOOP} onRecord={NOOP} />
      </Frame>
    ),
  },
  {
    id: 'best-run',
    label: 'Best run',
    frame: (
      <Frame accent="violet" flip
        title={<span>Your best mix, <span style={{ fontStyle: 'italic' }}>scored.</span></span>}>
        <RunDetailsScreen exp={tea} run={teaBestRun} num={teaBestNum} isBest={true} onBack={NOOP} onMenu={NOOP} />
      </Frame>
    ),
  },
];

// ════════════════════════════════════════════════════════
// gallery presentation
// ════════════════════════════════════════════════════════
function PreviewCard({ panel, index, scale }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18 }}>
      <div style={{
        width: 1290 * scale, height: 2796 * scale, borderRadius: 30, overflow: 'hidden',
        boxShadow: '0 30px 70px -30px rgba(34,31,42,0.45), 0 2px 10px rgba(34,31,42,0.12)',
        background: '#000',
      }}>
        <div style={{ width: 1290, height: 2796, transform: `scale(${scale})`, transformOrigin: 'top left' }}>
          {panel.frame}
        </div>
      </div>
      <div style={{ textAlign: 'center' }}>
        <div style={{ fontFamily: T.sans, fontWeight: 700, fontSize: 13, letterSpacing: '0.14em', textTransform: 'uppercase', color: T.gold }}>
          {String(index + 1).padStart(2, '0')}
        </div>
        <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 16, color: T.ink, marginTop: 4 }}>{panel.label}</div>
      </div>
    </div>
  );
}

function Gallery() {
  const PREVIEW_W = 300; // on-screen width of each card
  const scale = PREVIEW_W / 1290;
  return (
    <div style={{ minHeight: '100vh', padding: '64px 48px 90px', boxSizing: 'border-box' }}>
      <div style={{ maxWidth: 1480, margin: '0 auto' }}>
        <div style={{ fontFamily: T.sans, fontWeight: 700, fontSize: 13, letterSpacing: '0.22em', textTransform: 'uppercase', color: T.gold }}>Mix Max</div>
        <h1 style={{ margin: '12px 0 0', fontFamily: T.serif, fontWeight: 500, fontSize: 52, letterSpacing: '-0.02em', color: T.ink }}>App Store screenshots</h1>
        <p style={{ margin: '14px 0 0', fontFamily: T.sans, fontSize: 17, color: T.inkSoft, maxWidth: 680, lineHeight: 1.5 }}>
          Four portrait frames at <strong style={{ color: T.ink }}>1290 × 2796</strong> — the iPhone 6.7&Prime;/6.9&Prime; size App Store Connect expects. Each is pre-filled with real data and tells one beat of the story.
        </p>
        <div style={{
          marginTop: 48, display: 'grid',
          gridTemplateColumns: `repeat(auto-fit, minmax(${PREVIEW_W}px, ${PREVIEW_W}px))`,
          gap: 56, justifyContent: 'center',
        }}>
          {PANELS.map((p, i) => <PreviewCard key={p.id} panel={p} index={i} scale={scale} />)}
        </div>
      </div>
    </div>
  );
}

window.__PANELS = PANELS;
ReactDOM.createRoot(document.getElementById('stage')).render(<Gallery />);
