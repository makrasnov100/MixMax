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
      <span style={{ fontFamily: T.sans, fontSize: 13, color: T.inkFaint, fontWeight: 500, whiteSpace: 'nowrap' }}>on / off</span>
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

function ParamRow({ p }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '15px 16px' }}>
      <Tile icon={PARAM_TYPES[p.type].icon} tone="sage" />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 16, color: T.ink, marginBottom: 6, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.name}</div>
        <ParamValue p={p} />
      </div>
    </div>
  );
}

function OutcomeRow({ o }) {
  const meta = [o.unit, (o.min != null && o.max != null) ? `${fmt(o.min)}–${fmt(o.max)}` : null, o.step ? `step ${fmt(o.step)}` : null].filter(Boolean).join('  ·  ');
  const maxi = o.goal === 'maximize';
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '15px 16px' }}>
      <Tile icon="target" tone="violet" />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 16, color: T.ink, marginBottom: 3 }}>{o.name}</div>
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft }}>{meta}</div>
      </div>
      <Chip tone={maxi ? 'gold' : 'violet'} icon={maxi ? 'up' : 'down'}>{maxi ? 'maximize' : 'minimize'}</Chip>
    </div>
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
  const runs = exp.runs || [];
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
        <MetaBit icon="play" text={`${runs.length} run${runs.length === 1 ? '' : 's'}`} />
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
function ExperimentDetailsScreen({ exp, onBack, onRename, onAddParam, onAddOutput, onRun }) {
  const params = exp.parameters || [];
  const outcomes = exp.outcomes || [];
  const runs = exp.runs || [];
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
        <Chip tone="soft" icon="flask">{runs.length} run{runs.length === 1 ? '' : 's'} logged</Chip>
      </div>

      <div style={{ padding: '18px 20px 0' }}>
        <button onClick={onRename} style={{ border: 'none', background: 'none', padding: 0, cursor: 'pointer', display: 'flex', alignItems: 'flex-start', gap: 10, textAlign: 'left' }}>
          <Display size={36}>{exp.name || 'Untitled experiment'}</Display>
          <span style={{ marginTop: 8 }}><Icon name="edit" size={19} color={T.inkFaint} stroke={1.9} /></span>
        </button>
      </div>

      {/* best so far */}
      {best && (
        <div style={{ margin: '18px 20px 0', background: T.goldTint, borderRadius: T.rCard, padding: '15px 16px', display: 'flex', alignItems: 'center', gap: 13 }}>
          <Tile icon="trophy" tone="gold" />
          <div style={{ flex: 1 }}>
            <Eyebrow color={T.goldText}>Best mix so far</Eyebrow>
            <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 15, color: T.ink, marginTop: 3 }}>{best}</div>
          </div>
        </div>
      )}

      {/* parameters */}
      <div style={{ padding: '26px 20px 0' }}>
        <SectionLabel count={params.length || undefined}>Parameters</SectionLabel>
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, marginBottom: 13 }}>The knobs Mix Max tunes for you.</div>
        {params.length === 0
          ? <EmptyHint icon="sparkle" title="No parameters yet" body="Add the knobs you want to tune." />
          : <GroupCard>{params.map((p, i) => <React.Fragment key={p.id}>{i > 0 && <Divider />}<ParamRow p={p} /></React.Fragment>)}</GroupCard>}
      </div>

      {/* outcomes */}
      <div style={{ padding: '24px 20px 0' }}>
        <SectionLabel count={outcomes.length || undefined}>Outcomes</SectionLabel>
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, marginBottom: 13 }}>What you measure to score each run.</div>
        {outcomes.length === 0
          ? <EmptyHint icon="target" title="No outcomes yet" body="Add a result to maximize or minimize." />
          : <GroupCard>{outcomes.map((o, i) => <React.Fragment key={o.id}>{i > 0 && <Divider />}<OutcomeRow o={o} /></React.Fragment>)}</GroupCard>}
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
  return min + Math.random() * (max - min);
}
function fmtSuggested(p, v) {
  if (p.type === 'toggle') return v ? 'On' : 'Off';
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
          Tuned from your past runs to learn the most this time.
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

function RatingScreen({ exp, index, value, onChange, onBack, onNext }) {
  const outcomes = exp.outcomes || [];
  const o = outcomes[index];
  const isLast = index === outcomes.length - 1;
  const maxi = o.goal === 'maximize';
  return (
    <Screen footer={<Btn label={isLast ? 'Save run' : 'Next outcome'} iconR={isLast ? 'check' : 'arrowR'} variant={isLast ? 'gold' : 'ink'} onClick={onNext} />}>
      <TopPad h={50} />
      <div style={{ padding: '4px 20px 0', display: 'flex', alignItems: 'center', gap: 14 }}>
        <RoundBtn icon="arrowL" onClick={onBack} />
        <ProgressDots total={outcomes.length} index={index} />
        <span style={{ fontFamily: T.sans, fontSize: 13.5, color: T.inkSoft, fontWeight: 500, marginLeft: 'auto', whiteSpace: 'nowrap' }}>Outcome {index + 1} of {outcomes.length}</span>
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

// ── helpers ──────────────────────────────────────────────
function bestOutcomeLabel(exp) {
  const runs = (exp.runs || []).filter(r => r.outcomeValues);
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
  suggestValue, bestOutcomeLabel,
});
