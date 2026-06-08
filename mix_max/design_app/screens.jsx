// screens.jsx — the four Mix Max screens

// ── shared value visual for a parameter ──────────────────
function ParamValue({ p }) {
  if (p.type === 'number' || p.type === 'duration') {
    if (p.min != null && p.max != null) return <RangePips min={p.min} max={p.max} unit={p.unit} />;
    const txt = [p.unit, p.min != null ? `≥ ${fmt(p.min)}` : (p.max != null ? `≤ ${fmt(p.max)}` : 'any value')].filter(Boolean).join('  ·  ');
    return <span style={{ fontFamily: T.sans, fontSize: 13.5, color: T.inkSoft }}>{txt}</span>;
  }
  if (p.type === 'toggle') return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
      <MiniSwitch on />
      <span style={{ fontFamily: T.sans, fontSize: 13, color: T.inkFaint, fontWeight: 500, whiteSpace: 'nowrap' }}>{onLabelOf(p)} / {offLabelOf(p)}</span>
    </div>
  );
  if (p.type === 'choice') return <OptionPreview options={p.options || []} />;
  if (p.type === 'order') return <OrderPreview items={p.items || []} />;
  return null;
}

function GroupCard({ children }) {
  return (
    <div style={{ background: T.surface, borderRadius: T.rCard, border: `1px solid ${T.hairline}`, boxShadow: CARD_SHADOW, overflow: 'hidden' }}>
      {children}
    </div>
  );
}
function Divider() { return <div style={{ height: 1, background: T.hairline, marginLeft: 70 }} />; }

function ParamRow({ p, onEdit }) {
  const [press, setPress] = React.useState(false);
  return (
    <button onClick={onEdit}
      onMouseDown={() => setPress(true)} onMouseUp={() => setPress(false)} onMouseLeave={() => setPress(false)}
      style={{ width: '100%', textAlign: 'left', border: 'none', cursor: 'pointer',
        background: press ? T.bgAlt : 'transparent', WebkitTapHighlightColor: 'transparent', transition: 'background .12s',
        display: 'flex', alignItems: 'center', gap: 14, padding: '15px 16px' }}>
      <Tile icon={PARAM_TYPES[p.type].icon} tone="sage" />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 16, color: T.ink, marginBottom: 6, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.name}</div>
        <ParamValue p={p} />
      </div>
    </button>
  );
}

function OutcomeRow({ o, onEdit }) {
  const [press, setPress] = React.useState(false);
  const meta = [o.unit, (o.min != null && o.max != null) ? `${fmt(o.min)}–${fmt(o.max)}` : null, o.step ? `interval ${fmt(o.step)}` : null].filter(Boolean).join('  ·  ');
  const maxi = o.goal === 'maximize';
  return (
    <button onClick={onEdit}
      onMouseDown={() => setPress(true)} onMouseUp={() => setPress(false)} onMouseLeave={() => setPress(false)}
      style={{ width: '100%', textAlign: 'left', border: 'none', cursor: 'pointer',
        background: press ? T.bgAlt : 'transparent', WebkitTapHighlightColor: 'transparent', transition: 'background .12s',
        display: 'flex', alignItems: 'center', gap: 14, padding: '15px 16px' }}>
      <Tile icon="target" tone="violet" />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 16, color: T.ink, marginBottom: 3 }}>{o.name}</div>
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft }}>{meta}</div>
      </div>
      <Chip tone={maxi ? 'gold' : 'violet'} icon={maxi ? 'up' : 'down'}>{maxi ? 'maximize' : 'minimize'}</Chip>
    </button>
  );
}

function EmptyHint({ icon, title, body }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 13, padding: '18px 16px', background: T.surface, borderRadius: T.rCard, border: `1px dashed ${T.hairlineStrong}` }}>
      <Tile icon={icon} tone="neutral" />
      <div>
        <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 14.5, color: T.ink }}>{title}</div>
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, marginTop: 1 }}>{body}</div>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════
// 1. EXPERIMENTS LIST
// ════════════════════════════════════════════════════════
function ExperimentCard({ exp, onOpen }) {
  const params = exp.parameters || [];
  const outcomes = exp.outcomes || [];
  const runs = recordedRuns(exp);
  const best = bestOutcomeLabel(exp);
  return (
    <button onClick={onOpen} style={{
      width: '100%', textAlign: 'left', cursor: 'pointer', display: 'block',
      background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.rCard,
      boxShadow: CARD_SHADOW, padding: '18px 18px 16px', WebkitTapHighlightColor: 'transparent',
      transition: 'transform .12s ease',
    }}
      onMouseDown={e => e.currentTarget.style.transform = 'scale(0.99)'}
      onMouseUp={e => e.currentTarget.style.transform = 'scale(1)'}
      onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
        <div style={{ fontFamily: T.serif, fontWeight: 500, fontSize: 24, color: T.ink, letterSpacing: '-0.01em', lineHeight: 1.1 }}>{exp.name || 'Untitled experiment'}</div>
        <div style={{ marginTop: 3 }}><Icon name="chevR" size={20} color={T.inkFaint} stroke={2} /></div>
      </div>
      {/* param type glyph strip */}
      {params.length > 0 && (
        <div style={{ display: 'flex', gap: 7, marginTop: 14 }}>
          {params.slice(0, 5).map((p, i) => <Tile key={i} icon={PARAM_TYPES[p.type].icon} tone="sage" size={32} radius={9} stroke={2} />)}
          {outcomes.slice(0, 2).map((o, i) => <Tile key={'o' + i} icon="target" tone="violet" size={32} radius={9} stroke={2} />)}
        </div>
      )}
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 14 }}>
        <MetaBit icon="hash" text={`${params.length} parameter${params.length === 1 ? '' : 's'}`} />
        <MetaBit icon="target" text={`${outcomes.length} outcome${outcomes.length === 1 ? '' : 's'}`} />
        <MetaBit icon="flask" text={`${runs.length} run${runs.length === 1 ? '' : 's'}`} />
      </div>
      {best && (
        <div style={{ marginTop: 14, paddingTop: 14, borderTop: `1px solid ${T.hairline}`, display: 'flex', alignItems: 'center', gap: 8 }}>
          <Icon name="trophy" size={15} color={T.gold} stroke={2} />
          <span style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, flexShrink: 0 }}>Best so far</span>
          <span style={{ fontFamily: T.sans, fontSize: 13, fontWeight: 600, color: T.goldText, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{best}</span>
        </div>
      )}
    </button>
  );
}
function MetaBit({ icon, text }) {
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5, flexShrink: 0, whiteSpace: 'nowrap' }}>
      <Icon name={icon} size={14} color={T.inkFaint} stroke={2} />
      <span style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, fontWeight: 500 }}>{text}</span>
    </span>
  );
}

function ExperimentsListScreen({ experiments, onOpen, onAdd }) {
  return (
    <Screen footer={<Btn label="New experiment" icon="plus" variant="ink" onClick={onAdd} />}>
      <TopPad />
      <div style={{ padding: '8px 20px 0' }}>
        <Eyebrow color={T.gold}>Mix Max</Eyebrow>
        <Display size={40} style={{ marginTop: 8 }}>Experiments</Display>
        <div style={{ fontFamily: T.sans, fontSize: 14.5, color: T.inkSoft, marginTop: 10 }}>Find the best version of anything.</div>
      </div>
      <div style={{ padding: '22px 20px 8px', display: 'flex', flexDirection: 'column', gap: 13 }}>
        {experiments.length === 0 ? (
          <div style={{ marginTop: 60, textAlign: 'center', padding: '0 20px' }}>
            <div style={{ display: 'inline-flex' }}><Tile icon="flask" tone="gold" size={64} radius={20} /></div>
            <div style={{ fontFamily: T.serif, fontSize: 22, color: T.ink, marginTop: 18 }}>Nothing brewing yet</div>
            <div style={{ fontFamily: T.sans, fontSize: 14, color: T.inkSoft, marginTop: 6, lineHeight: 1.5 }}>Start an experiment to let Mix Max find your best mix.</div>
          </div>
        ) : experiments.map(exp => <ExperimentCard key={exp.id} exp={exp} onOpen={() => onOpen(exp.id)} />)}
      </div>
    </Screen>
  );
}

// ════════════════════════════════════════════════════════
// 2. EXPERIMENT DETAILS
// ════════════════════════════════════════════════════════
function ExperimentDetailsScreen({ exp, onBack, onRename, onAddParam, onAddOutput, onRun, onMenu, onHistory, onOpenBest, onEditParam, onEditOutput }) {
  const params = exp.parameters || [];
  const outcomes = exp.outcomes || [];
  const runs = recordedRuns(exp);
  const canRun = params.length > 0 && outcomes.length > 0;
  const best = bestOutcomeLabel(exp);

  return (
    <Screen footer={
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        <Btn label="Run experiment" iconR="play" variant={canRun ? 'gold' : 'disabled'} disabled={!canRun} onClick={onRun} />
        <div style={{ display: 'flex', gap: 10 }}>
          <Btn label="Parameter" icon="plus" variant="sage" onClick={onAddParam} />
          <Btn label="Outcome" icon="plus" variant="violet" onClick={onAddOutput} />
        </div>
      </div>
    }>
      <TopPad h={50} />
      <div style={{ padding: '4px 20px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <RoundBtn icon="arrowL" onClick={onBack} />
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <RunsPill count={runs.length} onClick={onHistory} />
          <RoundBtn icon="more" onClick={onMenu} />
        </div>
      </div>

      <div style={{ padding: '18px 20px 0' }}>
        <button onClick={onRename} style={{ border: 'none', background: 'none', padding: 0, cursor: 'pointer', display: 'flex', alignItems: 'flex-start', gap: 10, textAlign: 'left' }}>
          <Display size={36}>{exp.name || 'Untitled experiment'}</Display>
        </button>
      </div>

      {/* best so far */}
      {best && (
        <button onClick={onOpenBest} style={{
          width: 'calc(100% - 40px)', margin: '18px 20px 0', background: T.goldTint, borderRadius: T.rCard,
          padding: '15px 16px', display: 'flex', alignItems: 'center', gap: 13, textAlign: 'left',
          border: 'none', cursor: 'pointer', WebkitTapHighlightColor: 'transparent',
          transition: 'transform .12s ease',
        }}
          onMouseDown={e => e.currentTarget.style.transform = 'scale(0.99)'}
          onMouseUp={e => e.currentTarget.style.transform = 'scale(1)'}
          onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}>
          <Tile icon="trophy" tone="gold" />
          <div style={{ flex: 1, minWidth: 0 }}>
            <Eyebrow color={T.goldText}>Best mix so far</Eyebrow>
            <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 15, color: T.ink, marginTop: 3, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{best}</div>
          </div>
          <Icon name="chevR" size={19} color={T.goldText} stroke={2} />
        </button>
      )}

      {/* parameters */}
      <div style={{ padding: '26px 20px 0' }}>
        <SectionLabel count={params.length || undefined}>Parameters</SectionLabel>
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, marginBottom: 13 }}>The knobs Mix Max tunes for you.</div>
        {params.length === 0
          ? <EmptyHint icon="sparkle" title="No parameters yet" body="Add the knobs you want to tune." />
          : <GroupCard>{params.map((p, i) => <React.Fragment key={p.id}>{i > 0 && <Divider />}<ParamRow p={p} onEdit={() => onEditParam(p.id)} /></React.Fragment>)}</GroupCard>}
      </div>

      {/* outcomes */}
      <div style={{ padding: '24px 20px 0' }}>
        <SectionLabel count={outcomes.length || undefined}>Outcomes</SectionLabel>
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, marginBottom: 13 }}>What you measure to score each run.</div>
        {outcomes.length === 0
          ? <EmptyHint icon="target" title="No outcomes yet" body="Add a result to maximize or minimize." />
          : <GroupCard>{outcomes.map((o, i) => <React.Fragment key={o.id}>{i > 0 && <Divider />}<OutcomeRow o={o} onEdit={() => onEditOutput(o.id)} /></React.Fragment>)}</GroupCard>}
      </div>
      <div style={{ height: 8 }} />
    </Screen>
  );
}

// ════════════════════════════════════════════════════════
// 3. RUN SUGGESTION
// ════════════════════════════════════════════════════════
function suggestValue(p) {
  if (p.type === 'toggle') return Math.random() > 0.5;
  if (p.type === 'choice') return (p.options || ['—'])[Math.floor(Math.random() * (p.options || ['—']).length)];
  if (p.type === 'order') return p.items || [];
  const min = p.min != null ? p.min : 0, max = p.max != null ? p.max : 10;
  const raw = min + Math.random() * (max - min);
  // snap to the increment grid (min + k×increment) when one is set, so the
  // suggestion respects the chosen granularity / integers-only.
  if (p.increment && p.increment > 0) {
    const snapped = min + Math.round((raw - min) / p.increment) * p.increment;
    return Math.min(Math.max(Number(snapped.toFixed(6)), min), max);
  }
  return raw;
}
function fmtSuggested(p, v) {
  if (p.type === 'toggle') return v ? onLabelOf(p) : offLabelOf(p);
  if (p.type === 'choice') return String(v);
  if (p.type === 'order') return (v || []).join('  →  ');
  const s = fmt(Number(v), 3);
  return p.unit ? `${s} ${p.unit}` : s;
}

function SuggestionCard({ p, value }) {
  return (
    <div style={{ background: T.surface, borderRadius: T.rCard, border: `1px solid ${T.hairline}`, boxShadow: CARD_SHADOW, padding: '16px 18px', display: 'flex', alignItems: 'center', gap: 15 }}>
      <Tile icon={PARAM_TYPES[p.type].icon} tone="sage" size={46} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, fontWeight: 500, marginBottom: 3 }}>{p.name}</div>
        <div style={{ fontFamily: T.serif, fontWeight: 500, fontSize: 24, color: T.ink, letterSpacing: '-0.01em', lineHeight: 1.1 }}>{fmtSuggested(p, value)}</div>
      </div>
    </div>
  );
}

function RunSuggestionScreen({ exp, suggestion, onBack, onRecord }) {
  const params = exp.parameters || [];
  const tuneN = tunableRuns(exp).length;
  return (
    <Screen footer={<Btn label="Record outcomes" iconR="arrowR" variant="ink" onClick={onRecord} />}>
      <TopPad h={50} />
      <div style={{ padding: '4px 20px 0' }}>
        <RoundBtn icon="arrowL" onClick={onBack} />
      </div>
      <div style={{ padding: '18px 20px 0' }}>
        <Eyebrow color={T.gold}>Next run · suggested</Eyebrow>
        <Display size={34} style={{ marginTop: 8 }}>{exp.name}</Display>
      </div>

      {/* subtle smart-pick explainer */}
      <div style={{ margin: '16px 20px 0', display: 'flex', alignItems: 'center', gap: 11, background: T.goldTint, borderRadius: 14, padding: '12px 14px' }}>
        <Icon name="spark2" size={19} color={T.gold} stroke={1.9} />
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.goldText, lineHeight: 1.4 }}>
          {tuneN >= 2
            ? `Tuned from your ${tuneN} most recent runs to learn the most this time.`
            : 'Exploring new ground — record a couple of runs and Mix Max starts tuning.'}
        </div>
      </div>

      <div style={{ padding: '22px 20px 0' }}>
        <SectionLabel>Try these</SectionLabel>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 11, marginTop: 13 }}>
          {params.map(p => <SuggestionCard key={p.id} p={p} value={suggestion[p.id]} />)}
        </div>
      </div>
      <div style={{ height: 8 }} />
    </Screen>
  );
}

// ════════════════════════════════════════════════════════
// 4. OUTCOME RATING
// ════════════════════════════════════════════════════════
function SliderRow({ o, value, onChange }) {
  const min = o.min != null ? o.min : 0;
  const max = o.max != null ? o.max : 10;
  const step = o.step && o.step > 0 ? o.step : 1;
  const pct = max > min ? ((value - min) / (max - min)) * 100 : 0;
  const tickCount = Math.min(Math.round((max - min) / step) + 1, 11);
  return (
    <div style={{ padding: '0 4px' }}>
      <div style={{ position: 'relative', height: 40, display: 'flex', alignItems: 'center' }}>
        {/* rail */}
        <div style={{ position: 'absolute', left: 0, right: 0, height: 6, borderRadius: 999, background: T.hairlineStrong }} />
        {/* fill */}
        <div style={{ position: 'absolute', left: 0, width: `${pct}%`, height: 6, borderRadius: 999, background: T.gold }} />
        {/* ticks */}
        <div style={{ position: 'absolute', left: 0, right: 0, display: 'flex', justifyContent: 'space-between', pointerEvents: 'none' }}>
          {Array.from({ length: tickCount }).map((_, i) => {
            const tp = (i / (tickCount - 1)) * 100;
            return <span key={i} style={{ width: 4, height: 4, borderRadius: 999, background: tp <= pct ? 'rgba(255,255,255,0.85)' : T.inkFaint, opacity: 0.7 }} />;
          })}
        </div>
        <input className="mm-range" type="range" min={min} max={max} step={step} value={value}
          onChange={e => onChange(Number(e.target.value))} style={{ position: 'relative', zIndex: 2 }} />
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
        <span style={{ fontFamily: T.sans, fontSize: 14, color: T.inkFaint, fontWeight: 500 }}>{fmt(min)}</span>
        <span style={{ fontFamily: T.sans, fontSize: 14, color: T.inkFaint, fontWeight: 500 }}>{fmt(max)}</span>
      </div>
    </div>
  );
}

function RatingScreen({ exp, index, value, onChange, onBack, onNext, outcomes: outcomesProp, rescore }) {
  const outcomes = outcomesProp || exp.outcomes || [];
  const o = outcomes[index];
  const isLast = index === outcomes.length - 1;
  const maxi = o.goal === 'maximize';
  const saveLabel = rescore ? 'Save changes' : 'Save run';
  return (
    <Screen footer={<Btn label={isLast ? saveLabel : 'Next outcome'} iconR={isLast ? 'check' : 'arrowR'} variant={isLast ? 'gold' : 'ink'} onClick={onNext} />}>
      <TopPad h={50} />
      <div style={{ padding: '4px 20px 0', display: 'flex', alignItems: 'center', gap: 14 }}>
        <RoundBtn icon="arrowL" onClick={onBack} />
        <ProgressDots total={outcomes.length} index={index} />
        <span style={{ fontFamily: T.sans, fontSize: 13.5, color: T.inkSoft, fontWeight: 500, marginLeft: 'auto', whiteSpace: 'nowrap' }}>{rescore ? 'Rescore · ' : ''}{index + 1} of {outcomes.length}</span>
      </div>

      <div style={{ padding: '30px 20px 0', textAlign: 'center' }}>
        <div style={{ display: 'inline-flex', marginBottom: 16 }}><Tile icon="target" tone="violet" size={52} radius={16} /></div>
        <Display size={40}>{o.name}</Display>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, marginTop: 12, background: maxi ? T.goldTint : T.violetTint, borderRadius: 999, padding: '6px 13px', whiteSpace: 'nowrap' }}>
          <Icon name={maxi ? 'up' : 'down'} size={15} color={maxi ? T.goldText : T.violetText} stroke={2.2} />
          <span style={{ fontFamily: T.sans, fontSize: 13, fontWeight: 600, color: maxi ? T.goldText : T.violetText, whiteSpace: 'nowrap' }}>{maxi ? 'higher is better' : 'lower is better'}</span>
        </div>
      </div>

      <div style={{ padding: '44px 24px 0', textAlign: 'center' }}>
        <div style={{ fontFamily: T.serif, fontWeight: 500, fontSize: 84, color: T.ink, lineHeight: 1, letterSpacing: '-0.02em' }}>
          {fmt(value)}{o.unit ? <span style={{ fontSize: 30, color: T.inkSoft, marginLeft: 8 }}>{o.unit}</span> : null}
        </div>
      </div>

      <div style={{ padding: '40px 24px 0' }}>
        <SliderRow o={o} value={value} onChange={onChange} />
      </div>
    </Screen>
  );
}

// ════════════════════════════════════════════════════════
// 5. RUN HISTORY
// ════════════════════════════════════════════════════════

// runs pill in the details header — styled to match the round back/menu buttons
function RunsPill({ count, onClick }) {
  return (
    <button onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 7, height: 40, padding: '0 12px',
      borderRadius: 999, cursor: 'pointer',
      background: T.surface, border: `1px solid ${T.hairline}`,
      boxShadow: '0 1px 2px rgba(34,31,42,0.05)',
      transition: 'transform .12s ease', WebkitTapHighlightColor: 'transparent',
    }}
      onMouseDown={e => e.currentTarget.style.transform = 'scale(0.97)'}
      onMouseUp={e => e.currentTarget.style.transform = 'scale(1)'}
      onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}>
      <Icon name="flask" size={17} color={T.gold} stroke={2} />
      <span style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 14, color: T.ink, whiteSpace: 'nowrap' }}>{count} run{count === 1 ? '' : 's'}</span>
      <Icon name="chevR" size={16} color={T.inkFaint} stroke={2.2} />
    </button>
  );
}

// score a single run, mirroring SchemaRun.finalRating (0..1, higher = better).
// scored against the run's own snapshot of outcomes so its rating reflects what
// was actually measured, even if outcomes were later changed or removed.
function runScore(exp, run) {
  const outcomes = runOutcomeDefs(exp, run);
  const vals = run.outcomeValues || {};
  let total = 0, count = 0;
  outcomes.forEach(o => {
    const v = vals[o.id];
    if (v == null) return;
    const lo = o.min != null ? o.min : 0, hi = o.max != null ? o.max : 10;
    let n = hi > lo ? Math.min(Math.max((v - lo) / (hi - lo), 0), 1) : v;
    if (o.goal === 'minimize') n = 1 - n;
    total += n; count++;
  });
  return count > 0 ? total / count : 0;
}
function bestRunId(exp) {
  // Best run is crowned across ALL recorded runs, so it never resets when the
  // parameters change — a leading mix recorded earlier stays the best until a
  // higher-scoring run beats it.
  const runs = recordedRuns(exp);
  if (!runs.length) return null;
  let best = null, bs = -Infinity;
  runs.forEach(r => { const s = runScore(exp, r); if (s > bs) { bs = s; best = r; } });
  return best ? best.id : null;
}
function relTime(sec) {
  if (!sec) return '';
  const d = Date.now() / 1000 - sec;
  if (d < 90) return 'just now';
  if (d < 3600) return Math.floor(d / 60) + ' min ago';
  if (d < 86400) { const h = Math.floor(d / 3600); return h + ' hr' + (h > 1 ? 's' : '') + ' ago'; }
  const days = Math.round(d / 86400);
  if (days < 7) return days + ' day' + (days > 1 ? 's' : '') + ' ago';
  if (days < 28) { const w = Math.round(days / 7); return w + ' week' + (w > 1 ? 's' : '') + ' ago'; }
  const mo = Math.round(days / 30); return mo + ' month' + (mo > 1 ? 's' : '') + ' ago';
}
function absStamp(sec) {
  if (!sec) return '';
  const dt = new Date(sec * 1000);
  return dt.toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) + ' · ' +
    dt.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' });
}

function OutcomeValueChip({ o, value, best }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'baseline', gap: 6,
      background: best ? 'rgba(255,255,255,0.7)' : T.violetTint, borderRadius: 999, padding: '6px 12px',
    }}>
      <span style={{ fontFamily: T.sans, fontSize: 12.5, fontWeight: 500, color: best ? T.goldText : T.violetText }}>{o.name}</span>
      <span style={{ fontFamily: T.sans, fontSize: 13.5, fontWeight: 700, color: best ? T.goldDeep : T.violetText }}>
        {fmt(value)}{o.unit ? <span style={{ fontWeight: 500, fontSize: 11.5 }}> {o.unit}</span> : null}
      </span>
    </span>
  );
}

function MixSummary({ exp, run }) {
  const params = runParamDefs(exp, run);
  const pv = run.parameterValues || {};
  const parts = params.map(p => pv[p.id] != null ? fmtSuggested(p, pv[p.id]) : null).filter(Boolean);
  if (!parts.length) return null;
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8, marginTop: 13, paddingTop: 13, borderTop: `1px solid ${T.hairline}` }}>
      <span style={{ marginTop: 1, flexShrink: 0 }}><Icon name="beaker" size={15} color={T.inkFaint} stroke={1.9} /></span>
      <span style={{ fontFamily: T.sans, fontSize: 12.5, color: T.inkSoft, lineHeight: 1.45 }}>{parts.join('   ·   ')}</span>
    </div>
  );
}

// segmented control to switch how the run list is ordered
function SortToggle({ value, onChange }) {
  const opts = [
    { key: 'recent', label: 'Most recent', icon: 'clock' },
    { key: 'rated', label: 'Highest rated', icon: 'trophy' },
  ];
  return (
    <div style={{ display: 'flex', gap: 4, background: T.bgAlt, borderRadius: 999, padding: 4 }}>
      {opts.map(o => {
        const active = value === o.key;
        return (
          <button key={o.key} onClick={() => onChange(o.key)} style={{
            flex: 1, height: 38, borderRadius: 999, border: 'none', cursor: 'pointer',
            background: active ? T.surface : 'transparent',
            boxShadow: active ? '0 1px 2px rgba(34,31,42,0.10)' : 'none',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7,
            fontFamily: T.sans, fontWeight: 600, fontSize: 13.5,
            color: active ? T.ink : T.inkSoft,
            transition: 'background .15s ease, color .15s ease, box-shadow .15s ease',
            WebkitTapHighlightColor: 'transparent',
          }}>
            <Icon name={o.icon} size={15} color={active ? T.gold : T.inkFaint} stroke={2} />
            {o.label}
          </button>
        );
      })}
    </div>
  );
}

function RunHistoryCard({ exp, run, num, isBest, onOpen }) {
  const outcomes = runOutcomeDefs(exp, run);
  const when = run.completedAt || run.createdAt;
  const score = runScore(exp, run);
  return (
    <button onClick={onOpen} style={{
      width: '100%', textAlign: 'left', cursor: 'pointer', display: 'block',
      background: isBest ? T.goldTint : T.surface, borderRadius: T.rCard,
      border: isBest ? `1.5px solid ${T.gold}` : `1px solid ${T.hairline}`,
      boxShadow: isBest ? '0 1px 2px rgba(120,90,20,0.12), 0 16px 32px -18px rgba(150,110,30,0.5)' : CARD_SHADOW,
      padding: '16px 17px', WebkitTapHighlightColor: 'transparent', transition: 'transform .12s ease',
    }}
      onMouseDown={e => e.currentTarget.style.transform = 'scale(0.99)'}
      onMouseUp={e => e.currentTarget.style.transform = 'scale(1)'}
      onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
        <div style={{ minWidth: 0 }}>
          {isBest ? (
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, background: T.gold, borderRadius: 999, padding: '4px 11px 4px 9px', marginBottom: 9 }}>
              <Icon name="trophy" size={13} color="#fff" stroke={2.2} />
              <span style={{ fontFamily: T.sans, fontWeight: 700, fontSize: 11, letterSpacing: '0.06em', color: '#fff', textTransform: 'uppercase' }}>Best run</span>
            </div>
          ) : (
            <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 11.5, letterSpacing: '0.08em', textTransform: 'uppercase', color: T.inkFaint, marginBottom: 6 }}>Run {num}</div>
          )}
          <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 15.5, color: T.ink }}>{relTime(when)}</div>
          <div style={{ fontFamily: T.sans, fontSize: 12.5, color: isBest ? T.goldText : T.inkFaint, opacity: isBest ? 0.85 : 1, marginTop: 2 }}>{absStamp(when)}</div>
        </div>
        <div style={{ textAlign: 'right', flexShrink: 0 }}>
          <div style={{ fontFamily: T.serif, fontWeight: 500, fontSize: 30, lineHeight: 1, color: isBest ? T.goldDeep : T.ink, letterSpacing: '-0.01em' }}>{fmt(score * 10, 1)}</div>
          <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 10, letterSpacing: '0.08em', textTransform: 'uppercase', color: isBest ? T.goldText : T.inkFaint, opacity: isBest ? 0.8 : 1, marginTop: 3 }}>rating</div>
        </div>
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 7, marginTop: 14 }}>
        {outcomes.map(o => <OutcomeValueChip key={o.id} o={o} value={run.outcomeValues[o.id]} best={isBest} />)}
      </div>
      <MixSummary exp={exp} run={run} />
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 4, marginTop: 12 }}>
        <span style={{ fontFamily: T.sans, fontSize: 12.5, fontWeight: 600, color: isBest ? T.goldText : T.inkSoft }}>View details</span>
        <Icon name="chevR" size={15} color={isBest ? T.goldText : T.inkFaint} stroke={2.2} />
      </div>
    </button>
  );
}

function RunHistoryScreen({ exp, onBack, onOpenRun }) {
  const [sort, setSort] = React.useState('recent');
  const runs = recordedRuns(exp);
  const chrono = [...runs].sort((a, b) => (a.completedAt || a.createdAt || 0) - (b.completedAt || b.createdAt || 0));
  const numberOf = {}; chrono.forEach((r, i) => { numberOf[r.id] = i + 1; });
  const bestId = bestRunId(exp);

  const ordered = [...runs].sort((a, b) => {
    if (sort === 'rated') {
      const d = runScore(exp, b) - runScore(exp, a);
      if (d !== 0) return d;
    }
    return (b.completedAt || b.createdAt || 0) - (a.completedAt || a.createdAt || 0);
  });

  return (
    <Screen>
      <TopPad h={50} />
      <div style={{ padding: '4px 20px 0' }}>
        <RoundBtn icon="arrowL" onClick={onBack} />
      </div>
      <div style={{ padding: '18px 20px 0' }}>
        <Eyebrow color={T.gold}>Run history</Eyebrow>
        <Display size={34} style={{ marginTop: 8 }}>{exp.name}</Display>
      </div>

      {runs.length === 0 ? (
        <div style={{ padding: '0 20px' }}>
          <div style={{ marginTop: 48, textAlign: 'center', padding: '0 14px' }}>
            <div style={{ display: 'inline-flex' }}><Tile icon="clock" tone="gold" size={64} radius={20} /></div>
            <div style={{ fontFamily: T.serif, fontSize: 22, color: T.ink, marginTop: 18 }}>No runs yet</div>
            <div style={{ fontFamily: T.sans, fontSize: 14, color: T.inkSoft, marginTop: 6, lineHeight: 1.5 }}>
              Run the experiment and record your outcomes — they'll show up here.
            </div>
          </div>
          <div style={{ height: 18 }} />
        </div>
      ) : (
        <React.Fragment>
          <div style={{ padding: '22px 20px 0' }}>
            <SortToggle value={sort} onChange={setSort} />
          </div>
          <div style={{ padding: '16px 20px 0', display: 'flex', flexDirection: 'column', gap: 12 }}>
            {ordered.map(r => <RunHistoryCard key={r.id} exp={exp} run={r} num={numberOf[r.id]} isBest={r.id === bestId} onOpen={() => onOpenRun(r.id)} />)}
          </div>
          <div style={{ height: 18 }} />
        </React.Fragment>
      )}
    </Screen>
  );
}

// ════════════════════════════════════════════════════════
// 6. RUN DETAILS
// ════════════════════════════════════════════════════════

// normalized contribution of every outcome → the final rating (weight-aware)
function ratingRows(exp, run) {
  const outcomes = runOutcomeDefs(exp, run);
  const ov = run.outcomeValues || {};
  const weights = outcomes.map(o => (o.weight != null ? o.weight : 1));
  const wsum = weights.reduce((a, b) => a + b, 0) || 1;
  const rows = outcomes.map((o, i) => {
    const v = ov[o.id];
    const min = o.min != null ? o.min : 0, max = o.max != null ? o.max : 10;
    let norm = (v != null && max > min) ? Math.min(Math.max((v - min) / (max - min), 0), 1) : 0;
    if (o.goal === 'minimize') norm = 1 - norm;
    const weight = weights[i] / wsum;
    return { o, v, norm, weight, points: weight * norm * 10 };
  });
  return { rows, rating: rows.reduce((a, r) => a + r.points, 0) };
}

// compact, self-explaining rating math: a weight-aware composition bar + rows that sum to the score
function RatingBreakdown({ exp, run }) {
  const { rows, rating } = ratingRows(exp, run);
  return (
    <div style={{ background: T.surface, borderRadius: T.rCard, border: `1px solid ${T.hairline}`, boxShadow: CARD_SHADOW, overflow: 'hidden' }}>
      {/* composition bar: segment width = weight, fill = score */}
      <div style={{ padding: '16px 16px 13px' }}>
        <div style={{ display: 'flex', gap: 3, height: 16 }}>
          {rows.map((r, i) => (
            <div key={i} style={{ flex: r.weight, minWidth: 5, background: T.violetTint, borderRadius: 4, overflow: 'hidden', position: 'relative' }}>
              <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: `${r.norm * 100}%`, background: T.violet }} />
            </div>
          ))}
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 10 }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontFamily: T.sans, fontSize: 11.5, color: T.inkFaint, fontWeight: 500 }}>
            <span style={{ width: 9, height: 9, borderRadius: 3, background: T.violet, display: 'inline-block' }} />score
            <span style={{ width: 9, height: 9, borderRadius: 3, background: T.violetTint, display: 'inline-block', marginLeft: 4 }} />weight
          </span>
          <span style={{ fontFamily: T.sans, fontSize: 11.5, color: T.inkFaint, fontWeight: 600 }}>width = weight</span>
        </div>
      </div>
      <Divider />
      {rows.map((r, i) => {
        const o = r.o, maxi = o.goal === 'maximize';
        return (
          <React.Fragment key={o.id}>
            {i > 0 && <div style={{ height: 1, background: T.hairline, marginLeft: 16 }} />}
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px' }}>
              <span style={{ width: 9, height: 9, borderRadius: 999, background: T.violet, flexShrink: 0 }} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 15, color: T.ink, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{o.name}</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginTop: 2 }}>
                  <Icon name={maxi ? 'up' : 'down'} size={12} color={T.inkFaint} stroke={2.4} />
                  <span style={{ fontFamily: T.sans, fontSize: 12, color: T.inkSoft }}>{Math.round(r.weight * 100)}% weight</span>
                </div>
              </div>
              <span style={{ fontFamily: T.sans, fontWeight: 700, fontSize: 13, color: T.violetText, background: T.violetTint, borderRadius: 999, padding: '5px 11px', whiteSpace: 'nowrap', flexShrink: 0 }}>
                {fmt(r.v)}{o.unit ? <span style={{ fontWeight: 500, fontSize: 11 }}> {o.unit}</span> : null}
              </span>
              <div style={{ width: 44, textAlign: 'right', flexShrink: 0, fontFamily: T.sans, fontWeight: 700, fontSize: 14.5, color: T.goldText }}>+{fmt(r.points, 1)}</div>
            </div>
          </React.Fragment>
        );
      })}
      {/* total */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 11, padding: '13px 16px', background: T.goldTint }}>
        <Icon name="trophy" size={16} color={T.gold} stroke={2} />
        <span style={{ flex: 1, fontFamily: T.sans, fontWeight: 600, fontSize: 14, color: T.goldText }}>Final rating</span>
        <span style={{ fontFamily: T.serif, fontWeight: 500, fontSize: 22, color: T.goldDeep, letterSpacing: '-0.01em' }}>{fmt(rating, 1)}</span>
      </div>
    </div>
  );
}

function RunDetailsScreen({ exp, run, num, isBest, onBack, onMenu }) {
  const params = runParamDefs(exp, run);
  const outcomes = runOutcomeDefs(exp, run);
  const pv = run.parameterValues || {};
  const ov = run.outcomeValues || {};
  const when = run.completedAt || run.createdAt;
  const score = runScore(exp, run);

  return (
    <Screen>
      <TopPad h={50} />
      <div style={{ padding: '4px 20px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 }}>
        <RoundBtn icon="arrowL" onClick={onBack} />
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          {isBest && <Chip tone="gold" icon="trophy">Best run</Chip>}
          {onMenu && <RoundBtn icon="more" onClick={onMenu} />}
        </div>
      </div>

      <div style={{ padding: '18px 20px 0' }}>
        <Eyebrow color={T.gold}>Run {num} · {relTime(when)}</Eyebrow>
        <Display size={34} style={{ marginTop: 8 }}>{exp.name}</Display>
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, marginTop: 8, display: 'flex', alignItems: 'center', gap: 6 }}>
          <Icon name="clock" size={14} color={T.inkFaint} stroke={2} />
          {absStamp(when)}
        </div>
      </div>

      {/* overall rating hero */}
      <div style={{
        margin: '20px 20px 0',
        background: T.surface,
        border: `1px solid ${T.hairline}`,
        boxShadow: CARD_SHADOW,
        borderRadius: T.rCard, padding: '18px 20px',
        display: 'flex', alignItems: 'center', gap: 18,
      }}>
        <div style={{ fontFamily: T.serif, fontWeight: 500, fontSize: 56, lineHeight: 1, letterSpacing: '-0.02em', color: T.ink }}>{fmt(score * 10, 1)}</div>
        <div style={{ minWidth: 0 }}>
          <Eyebrow color={T.inkFaint}>Overall rating</Eyebrow>
          <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, marginTop: 4, lineHeight: 1.4 }}>
            Averaged across {outcomes.length} outcome{outcomes.length === 1 ? '' : 's'}.
          </div>
        </div>
      </div>

      {/* rating breakdown */}
      <div style={{ padding: '28px 20px 0' }}>
        <SectionLabel count={outcomes.length || undefined}>Rating breakdown</SectionLabel>
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, marginBottom: 13 }}>Each outcome's score, by weight, adds up to the rating.</div>
        <RatingBreakdown exp={exp} run={run} />
      </div>

      {/* parameters used */}
      <div style={{ padding: '26px 20px 0' }}>
        <SectionLabel count={params.length || undefined}>Parameters used</SectionLabel>
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, marginBottom: 13 }}>The exact mix of values you tried.</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 11 }}>
          {params.map(p => <SuggestionCard key={p.id} p={p} value={pv[p.id]} />)}
        </div>
      </div>
      <div style={{ height: 8 }} />
    </Screen>
  );
}

// ── helpers ──────────────────────────────────────────────
// every recorded run (all are kept & shown — nothing is "outdated").
function recordedRuns(exp) { return (exp.runs || []).filter(r => r.outcomeValues); }

// the param / outcome definitions to render a run by — its own snapshot if it
// has one (so it renders correctly even after later edits / deletes), else the
// experiment's current setup.
function runParamDefs(exp, run) { return (run && run.params) || exp.parameters || []; }
function runOutcomeDefs(exp, run) { return (run && run.outcomes) || exp.outcomes || []; }

// a run only tunes the next suggested run when it was recorded AFTER the
// parameters were last changed — decided purely by timestamp, not a per-run
// parameter/outcome compatibility check. A null stamp means the parameters were
// never edited, so every run still tunes. (Every run is shown either way; this
// only governs what the optimizer learns from.)
function isRunTunable(exp, run) {
  const updated = exp.lastParametersUpdatedAt;
  if (updated == null) return true;
  const when = run.createdAt != null ? run.createdAt : (run.completedAt || 0);
  return when >= updated;
}
function tunableRuns(exp) { return recordedRuns(exp).filter(r => isRunTunable(exp, r)); }

function bestOutcomeLabel(exp) {
  const runs = recordedRuns(exp);
  const outcomes = exp.outcomes || [];
  if (runs.length === 0 || outcomes.length === 0) return null;
  // score = sum of normalized outcomes (respecting goal); pick best run
  let bestRun = null, bestScore = -Infinity;
  runs.forEach(r => {
    let s = 0;
    outcomes.forEach(o => {
      const v = r.outcomeValues[o.id];
      if (v == null) return;
      const min = o.min != null ? o.min : 0, max = o.max != null ? o.max : 10;
      const norm = max > min ? (v - min) / (max - min) : 0;
      s += o.goal === 'minimize' ? (1 - norm) : norm;
    });
    if (s > bestScore) { bestScore = s; bestRun = r; }
  });
  if (!bestRun) return null;
  return outcomes.slice(0, 3).map(o => `${o.name} ${fmt(bestRun.outcomeValues[o.id])}`).join('  ·  ');
}

Object.assign(window, {
  ExperimentsListScreen, ExperimentDetailsScreen, RunSuggestionScreen, RatingScreen,
  RunHistoryScreen, RunDetailsScreen, RunsPill, suggestValue, bestOutcomeLabel, runScore, bestRunId,
  recordedRuns, tunableRuns, isRunTunable, runParamDefs, runOutcomeDefs,
});
