// drawers.jsx — bottom-sheet drawers (Name / Add Parameter / Add Output)
const { useState, useRef, useEffect } = React;

// ── Shell ────────────────────────────────────────────────
function DrawerShell({ title, subtitle, onClose, children, footer }) {
  return (
    <div onClick={onClose} style={{ position: 'absolute', inset: 0, zIndex: 100, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end', background: T.scrim }}>
      <div onClick={e => e.stopPropagation()} style={{
        position: 'relative', background: T.bg,
        borderTopLeftRadius: T.rDrawer, borderTopRightRadius: T.rDrawer,
        maxHeight: '90%', display: 'flex', flexDirection: 'column',
        boxShadow: '0 -12px 40px rgba(28,24,20,0.22)',
        animation: 'mmDrawerUp .32s cubic-bezier(0.22,1,0.36,1)',
      }}>
        <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 10 }}>
          <div style={{ width: 40, height: 5, borderRadius: 999, background: T.hairlineStrong }} />
        </div>
        <div style={{ padding: '14px 24px 4px', textAlign: 'center' }}>
          <div style={{ fontFamily: T.serif, fontWeight: 500, fontSize: 25, color: T.ink, letterSpacing: '-0.01em' }}>{title}</div>
          {subtitle && <div style={{ fontFamily: T.sans, fontSize: 13.5, color: T.inkSoft, marginTop: 3 }}>{subtitle}</div>}
        </div>
        <div className="mm-scroll" style={{ overflowY: 'auto', padding: '12px 24px 8px' }}>{children}</div>
        {footer && <div style={{ padding: '10px 24px 26px', background: T.bg }}>{footer}</div>}
      </div>
    </div>
  );
}

// ── Shared fields ────────────────────────────────────────
function FieldLabel({ children, optional }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 7, marginBottom: 7 }}>
      <Eyebrow color={T.inkSoft}>{children}</Eyebrow>
      {optional && <span style={{ fontFamily: T.sans, fontSize: 11.5, color: T.inkFaint, fontWeight: 500, textTransform: 'none', letterSpacing: 0 }}>optional</span>}
    </div>
  );
}

function TextInput({ value, onChange, placeholder, maxLength, autoFocus, type = 'text', big, align }) {
  const [focus, setFocus] = useState(false);
  return (
    <input
      value={value} onChange={e => onChange(e.target.value)}
      placeholder={placeholder} maxLength={maxLength} autoFocus={autoFocus}
      type={type} inputMode={type === 'number' ? 'decimal' : undefined}
      onFocus={() => setFocus(true)} onBlur={() => setFocus(false)}
      style={{
        width: '100%', height: big ? 56 : 50, boxSizing: 'border-box',
        background: T.surface, color: T.ink,
        border: `1.5px solid ${focus ? T.gold : T.hairline}`,
        borderRadius: T.rField, padding: '0 16px',
        fontFamily: T.sans, fontSize: big ? 19 : 16, fontWeight: 500,
        textAlign: align || 'left', outline: 'none',
        transition: 'border-color .15s',
      }}
    />
  );
}

function Counter({ value, max }) {
  return <div style={{ textAlign: 'right', fontFamily: T.sans, fontSize: 12, color: T.inkFaint, marginTop: 6 }}>{(value || '').length}/{max}</div>;
}

// segmented control (goal / generic)
function Segmented({ options, value, onChange }) {
  return (
    <div style={{ display: 'flex', gap: 8 }}>
      {options.map(o => {
        const active = o.value === value;
        return (
          <button key={o.value} onClick={() => onChange(o.value)} style={{
            flex: 1, height: 50, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            background: active ? T.ink : T.surface, color: active ? '#fff' : T.inkSoft,
            border: `1.5px solid ${active ? T.ink : T.hairline}`, borderRadius: T.rField,
            fontFamily: T.sans, fontWeight: 600, fontSize: 15, cursor: 'pointer',
            transition: 'all .14s', WebkitTapHighlightColor: 'transparent',
          }}>
            {o.icon && <Icon name={o.icon} size={18} color={active ? '#fff' : T.inkSoft} stroke={2} />}
            {o.label}
          </button>
        );
      })}
    </div>
  );
}

// type picker grid
function TypePicker({ value, onChange }) {
  return (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
      {Object.entries(PARAM_TYPES).map(([key, meta]) => {
        const active = value === key;
        return (
          <button key={key} onClick={() => onChange(key)} style={{
            display: 'flex', alignItems: 'center', gap: 8, padding: '11px 15px 11px 12px',
            background: active ? T.ink : T.surface, color: active ? '#fff' : T.ink,
            border: `1.5px solid ${active ? T.ink : T.hairline}`, borderRadius: 13,
            fontFamily: T.sans, fontWeight: 600, fontSize: 14.5, cursor: 'pointer',
            transition: 'all .14s', WebkitTapHighlightColor: 'transparent',
          }}>
            <Icon name={meta.icon} size={17} color={active ? T.goldTint : T.sage} stroke={2} />
            {meta.label}
          </button>
        );
      })}
    </div>
  );
}

// preset card row
function PresetRow({ presets, onPick }) {
  return (
    <div className="mm-scroll" style={{ display: 'flex', gap: 9, overflowX: 'auto', paddingBottom: 4, margin: '0 -24px', padding: '0 24px 4px' }}>
      {presets.map((p, i) => (
        <button key={i} onClick={() => onPick(p)} style={{
          flexShrink: 0, display: 'flex', flexDirection: 'column', gap: 9, width: 116,
          background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: 15,
          padding: '13px 13px 14px', textAlign: 'left', cursor: 'pointer',
          boxShadow: '0 1px 2px rgba(34,31,42,0.03)', WebkitTapHighlightColor: 'transparent',
        }}>
          <Tile icon={p.icon} tone={p.tone || 'sage'} size={34} radius={10} />
          <div>
            <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 13.5, color: T.ink, lineHeight: 1.15 }}>{p.title}</div>
            <div style={{ fontFamily: T.sans, fontSize: 11.5, color: T.inkFaint, marginTop: 2 }}>{p.hint}</div>
          </div>
        </button>
      ))}
    </div>
  );
}

function SubHead({ children }) {
  return <Eyebrow color={T.inkFaint} style={{ margin: '18px 0 9px' }}>{children}</Eyebrow>;
}

// ── 1. Name experiment ───────────────────────────────────
const NAME_PRESETS = ['Best Cup of Tea', 'Perfect Pancakes', 'House Cold Brew', 'Sourdough Loaf', 'Pre-Run Routine'];
function NameDrawer({ initial = '', title = 'Name your experiment', onSave, onClose }) {
  const [name, setName] = useState(initial);
  return (
    <DrawerShell title={title} subtitle="What are you trying to perfect?" onClose={onClose}
      footer={<Btn label="Save" iconR="check" variant={name.trim() ? 'ink' : 'disabled'} disabled={!name.trim()} onClick={() => onSave(name.trim())} />}>
      <TextInput value={name} onChange={setName} placeholder="e.g. Best Cup of Tea" maxLength={50} autoFocus big />
      <Counter value={name} max={50} />
      <SubHead>Need inspiration</SubHead>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
        {NAME_PRESETS.map(n => (
          <button key={n} onClick={() => setName(n)} style={{ border: 'none', background: 'none', padding: 0, cursor: 'pointer' }}>
            <Chip tone="outline" icon="flask">{n}</Chip>
          </button>
        ))}
      </div>
      <div style={{ height: 4 }} />
    </DrawerShell>
  );
}

// ── 2. Add parameter ─────────────────────────────────────
const PARAM_PRESETS = [
  { title: 'Amount', hint: 'grams', icon: 'bag', tone: 'sage', set: { name: 'Amount', type: 'number', unit: 'g', min: 0, max: 100, increment: 1 } },
  { title: 'Time', hint: 'minutes', icon: 'timer', tone: 'sage', set: { name: 'Time', type: 'duration', unit: 'minutes', min: 1, max: 10, increment: 0.5 } },
  { title: 'Temperature', hint: '°C', icon: 'ruler', tone: 'sage', set: { name: 'Temperature', type: 'number', unit: '°C', min: 0, max: 100, increment: 1 } },
  { title: 'On / Off', hint: 'a yes-no knob', icon: 'toggle', tone: 'sage', set: { name: '', type: 'toggle' } },
  { title: 'Pick one', hint: 'from a list', icon: 'list', tone: 'sage', set: { name: '', type: 'choice' } },
];

// Optional granularity for number / duration parameters. Mix Max only ever
// suggests values that land on this grid (min + k×increment), so a whole-number
// increment effectively makes the parameter integers-only. Left blank = smooth
// (any value within range).
const INCREMENT_PRESETS = [
  { value: 1, label: '1', note: 'whole' },
  { value: 0.5, label: '0.5' },
  { value: 0.1, label: '0.1' },
  { value: 0.01, label: '0.01' },
];

function IncrementField({ value, onChange }) {
  const num = value !== '' && !isNaN(Number(value)) ? Number(value) : null;
  const valid = num != null && num > 0;
  const pill = (active) => ({
    height: 42, padding: '0 15px', borderRadius: T.rField, cursor: 'pointer',
    display: 'inline-flex', alignItems: 'center', gap: 6,
    background: active ? T.ink : T.surface, color: active ? '#fff' : T.ink,
    border: `1.5px solid ${active ? T.ink : T.hairline}`,
    fontFamily: T.sans, fontWeight: 600, fontSize: 15,
    transition: 'all .14s', WebkitTapHighlightColor: 'transparent',
  });
  return (
    <div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
        {INCREMENT_PRESETS.map(opt => {
          const active = valid && num === opt.value;
          return (
            <button key={opt.value} onClick={() => onChange(active ? '' : String(opt.value))} style={pill(active)}>
              {opt.label}
              {opt.note && <span style={{ fontWeight: 500, fontSize: 12, opacity: active ? 0.8 : 0.6 }}>{opt.note}</span>}
            </button>
          );
        })}
      </div>
      <div style={{ height: 10 }} />
      <TextInput value={value} onChange={onChange} placeholder="Or type a custom step" type="number" />
    </div>
  );
}

function ChipEditor({ items, setItems, placeholder }) {
  const [draft, setDraft] = useState('');
  const add = () => { const v = draft.trim(); if (!v) return; setItems([...items, v]); setDraft(''); };
  return (
    <div>
      {items.length > 0 && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 10 }}>
          {items.map((it, i) => <Chip key={i} tone="soft" onClose={() => setItems(items.filter((_, j) => j !== i))}>{it}</Chip>)}
        </div>
      )}
      <div style={{ display: 'flex', gap: 8 }}>
        <div style={{ flex: 1 }}>
          <input value={draft} onChange={e => setDraft(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && add()} placeholder={placeholder}
            style={{ width: '100%', height: 48, boxSizing: 'border-box', background: T.surface, color: T.ink,
              border: `1.5px solid ${T.hairline}`, borderRadius: T.rField, padding: '0 14px',
              fontFamily: T.sans, fontSize: 15, fontWeight: 500, outline: 'none' }} />
        </div>
        <button onClick={add} style={{ width: 48, height: 48, flexShrink: 0, borderRadius: T.rField, border: 'none',
          background: T.ink, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="plus" size={20} color="#fff" stroke={2.2} />
        </button>
      </div>
    </div>
  );
}

function TwoCol({ children }) { return <div style={{ display: 'flex', gap: 10 }}>{children.map((c, i) => <div key={i} style={{ flex: 1 }}>{c}</div>)}</div>; }

function ParameterDrawer({ initial, onSave, onDelete, onClose }) {
  const isEdit = !!initial;
  const [name, setName] = useState(initial?.name || '');
  const [type, setType] = useState(initial?.type || 'number');
  const [unit, setUnit] = useState(initial?.unit || '');
  const [min, setMin] = useState(initial?.min != null ? String(initial.min) : '');
  const [max, setMax] = useState(initial?.max != null ? String(initial.max) : '');
  const [increment, setIncrement] = useState(initial?.increment != null ? String(initial.increment) : '');
  const [options, setOptions] = useState(initial?.options || []);
  const [items, setItems] = useState(initial?.items || []);
  // toggle: custom on/off state labels + a default-state preview
  const [onLabel, setOnLabel] = useState(initial?.onLabel || '');
  const [offLabel, setOffLabel] = useState(initial?.offLabel || '');
  const [toggleOn, setToggleOn] = useState(true);

  const applyPreset = (p) => {
    const s = p.set;
    setType(s.type);
    if (s.name !== undefined) setName(s.name);
    setUnit(s.unit || '');
    setMin(s.min !== undefined ? String(s.min) : '');
    setMax(s.max !== undefined ? String(s.max) : '');
    setIncrement(s.increment !== undefined ? String(s.increment) : '');
  };

  const ranged = type === 'number' || type === 'duration';
  const valid = name.trim() && (type !== 'choice' || options.length > 0) && (type !== 'order' || items.length > 1);

  const save = () => onSave({
    id: isEdit ? initial.id : 'p' + Date.now(), name: name.trim(), type,
    unit: ranged && unit.trim() ? unit.trim() : undefined,
    min: ranged && min !== '' ? Number(min) : undefined,
    max: ranged && max !== '' ? Number(max) : undefined,
    increment: ranged && increment !== '' && Number(increment) > 0 ? Number(increment) : undefined,
    options: type === 'choice' ? options : undefined,
    items: type === 'order' ? items : undefined,
    onLabel: type === 'toggle' && onLabel.trim() ? onLabel.trim() : undefined,
    offLabel: type === 'toggle' && offLabel.trim() ? offLabel.trim() : undefined,
  });

  return (
    <DrawerShell title={isEdit ? 'Edit parameter' : 'Add a parameter'} subtitle="A knob Mix Max will learn to tune" onClose={onClose}
      footer={isEdit ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Btn label="Save changes" iconR="check" variant={valid ? 'ink' : 'disabled'} disabled={!valid} onClick={save} />
          <Btn label="Delete parameter" icon="trash" variant="ghost" onClick={onDelete} />
        </div>
      ) : <Btn label="Save parameter" iconR="check" variant={valid ? 'ink' : 'disabled'} disabled={!valid} onClick={save} />}>

      {!isEdit && <SubHead>Quick add</SubHead>}
      {!isEdit && <PresetRow presets={PARAM_PRESETS} onPick={applyPreset} />}

      <SubHead>Name</SubHead>
      <TextInput value={name} onChange={setName} placeholder="e.g. Ounces of water" maxLength={50} />

      <SubHead>What kind of value?</SubHead>
      {isEdit ? (
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, background: T.surfaceSoft, border: `1px solid ${T.hairline}`, borderRadius: T.rField, padding: '12px 14px' }}>
          <Tile icon={PARAM_TYPES[type].icon} tone="sage" size={40} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 15, color: T.ink }}>{PARAM_TYPES[type].label}</div>
            <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.inkFaint, marginTop: 1 }}>Type stays fixed once created</div>
          </div>
          <Chip tone="soft" icon="lock">Fixed</Chip>
        </div>
      ) : (
        <React.Fragment>
          <TypePicker value={type} onChange={setType} />
          <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.inkFaint, marginTop: 8 }}>{PARAM_TYPES[type].blurb}</div>
        </React.Fragment>
      )}

      {ranged && (
        <div style={{ marginTop: 6 }}>
          <SubHead>Unit & range</SubHead>
          <TextInput value={unit} onChange={setUnit} placeholder="Unit — e.g. g, °C, ml" />
          <div style={{ height: 10 }} />
          <TwoCol>
            <TextInput value={min} onChange={setMin} placeholder="Min" type="number" align="left" />
            <TextInput value={max} onChange={setMax} placeholder="Max" type="number" align="left" />
          </TwoCol>
          <SubHead>Increment</SubHead>
          <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.inkFaint, margin: '-3px 0 11px' }}>How finely it's tuned. Set a whole number for integers only.</div>
          <IncrementField value={increment} onChange={setIncrement} min={min} />
        </div>
      )}
      {type === 'toggle' && (
        <div style={{ marginTop: 16 }}>
          <button onClick={() => setToggleOn(v => !v)} style={{
            width: '100%', textAlign: 'left', cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 12,
            background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.rField, padding: '14px 16px',
            WebkitTapHighlightColor: 'transparent',
          }}>
            <MiniSwitch on={toggleOn} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 15, color: T.ink }}>{toggleOn ? (onLabel.trim() || 'On') : (offLabel.trim() || 'Off')}</div>
              <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, marginTop: 2 }}>No range needed — it's simply on or off.</div>
            </div>
          </button>
          <SubHead>State labels (optional)</SubHead>
          <TwoCol>
            <TextInput value={onLabel} onChange={setOnLabel} placeholder="On" maxLength={24} />
            <TextInput value={offLabel} onChange={setOffLabel} placeholder="Off" maxLength={24} />
          </TwoCol>
        </div>
      )}
      {type === 'choice' && (<div style={{ marginTop: 6 }}><SubHead>Options</SubHead><ChipEditor items={options} setItems={setOptions} placeholder="Add an option" /></div>)}
      {type === 'order' && (<div style={{ marginTop: 6 }}><SubHead>Steps to sequence</SubHead><ChipEditor items={items} setItems={setItems} placeholder="Add a step" /></div>)}
      <div style={{ height: 6 }} />
    </DrawerShell>
  );
}

// create-mode wrapper (kept for the existing "Add parameter" entry point)
function AddParameterDrawer({ onSave, onClose }) {
  return <ParameterDrawer onSave={onSave} onClose={onClose} />;
}

// ── 3. Add output ────────────────────────────────────────
const OUTPUT_PRESETS = [
  { title: 'Taste', hint: '1–10, higher', icon: 'spark2', tone: 'violet', set: { name: 'taste', min: 1, max: 10, step: 1, goal: 'maximize' } },
  { title: 'Quality', hint: '1–5, higher', icon: 'trophy', tone: 'violet', set: { name: 'quality', min: 1, max: 5, step: 1, goal: 'maximize' } },
  { title: 'Yield', hint: '%, higher', icon: 'up', tone: 'violet', set: { name: 'yield', unit: '%', min: 0, max: 100, step: 1, goal: 'maximize' } },
  { title: 'Time', hint: 'min, lower', icon: 'clock', tone: 'violet', set: { name: 'time', unit: 'min', min: 0, max: 60, step: 1, goal: 'minimize' } },
];

function OutcomeDrawer({ initial, onSave, onDelete, onClose }) {
  const isEdit = !!initial;
  const [name, setName] = useState(initial?.name || '');
  const [unit, setUnit] = useState(initial?.unit || '');
  const [goal, setGoal] = useState(initial?.goal || 'maximize');
  const [min, setMin] = useState(initial?.min != null ? String(initial.min) : '1');
  const [max, setMax] = useState(initial?.max != null ? String(initial.max) : '10');
  const [step, setStep] = useState(initial?.step != null ? String(initial.step) : '1');

  const applyPreset = (p) => {
    const s = p.set;
    setName(s.name || ''); setUnit(s.unit || '');
    setGoal(s.goal); setMin(String(s.min)); setMax(String(s.max)); setStep(String(s.step));
  };
  const valid = name.trim();

  const save = () => onSave({
    id: isEdit ? initial.id : 'o' + Date.now(), name: name.trim(),
    unit: unit.trim() || undefined,
    min: min !== '' ? Number(min) : undefined,
    max: max !== '' ? Number(max) : undefined,
    step: step !== '' ? Number(step) : 1,
    goal,
  });

  return (
    <DrawerShell title={isEdit ? 'Edit outcome' : 'Add an outcome'} subtitle="What you'll measure after each run" onClose={onClose}
      footer={isEdit ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Btn label="Save changes" iconR="check" variant={valid ? 'ink' : 'disabled'} disabled={!valid} onClick={save} />
          <Btn label="Delete outcome" icon="trash" variant="ghost" onClick={onDelete} />
        </div>
      ) : <Btn label="Save outcome" iconR="check" variant={valid ? 'ink' : 'disabled'} disabled={!valid} onClick={save} />}>
      {!isEdit && <SubHead>Quick add</SubHead>}
      {!isEdit && <PresetRow presets={OUTPUT_PRESETS} onPick={applyPreset} />}

      <SubHead>Name</SubHead>
      <TextInput value={name} onChange={setName} placeholder="e.g. taste" maxLength={50} />

      <SubHead>Goal</SubHead>
      <Segmented value={goal} onChange={setGoal} options={[
        { value: 'minimize', label: 'Minimize', icon: 'down' },
        { value: 'maximize', label: 'Maximize', icon: 'up' },
      ]} />

      <SubHead>Scale</SubHead>
      <TwoCol>
        <TextInput value={min} onChange={setMin} placeholder="Min" type="number" />
        <TextInput value={max} onChange={setMax} placeholder="Max" type="number" />
      </TwoCol>
      <div style={{ height: 10 }} />
      <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
        <div style={{ flex: 1 }}><TextInput value={unit} onChange={setUnit} placeholder="Unit (optional)" /></div>
        <div style={{ flex: 1 }}><TextInput value={step} onChange={setStep} placeholder="Interval" type="number" /></div>
      </div>
      <div style={{ height: 6 }} />
    </DrawerShell>
  );
}

// create-mode wrapper (kept for the existing "Add outcome" entry point)
function AddOutputDrawer({ onSave, onClose }) {
  return <OutcomeDrawer onSave={onSave} onClose={onClose} />;
}

// ── 4. Experiment actions sheet ──────────────────────────
function ActionRow({ icon, tone = 'neutral', label, sublabel, danger, onClick }) {
  const [press, setPress] = useState(false);
  return (
    <button onClick={onClick}
      onMouseDown={() => setPress(true)} onMouseUp={() => setPress(false)} onMouseLeave={() => setPress(false)}
      style={{
        width: '100%', display: 'flex', alignItems: 'center', gap: 14, textAlign: 'left',
        background: press ? T.bgAlt : T.surface, border: `1px solid ${T.hairline}`,
        borderRadius: T.rField, padding: '14px 15px', cursor: 'pointer',
        WebkitTapHighlightColor: 'transparent', transition: 'background .12s',
      }}>
      <Tile icon={icon} tone={tone} size={42} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: T.sans, fontWeight: 600, fontSize: 16, color: danger ? T.danger : T.ink }}>{label}</div>
        {sublabel && <div style={{ fontFamily: T.sans, fontSize: 13, color: T.inkSoft, marginTop: 2 }}>{sublabel}</div>}
      </div>
      <Icon name="chevR" size={19} color={danger ? T.danger : T.inkFaint} stroke={2} />
    </button>
  );
}

function ExperimentActionsDrawer({ exp, onRename, onShareBest, onDelete, onClose }) {
  const hasRuns = (exp.runs || []).filter(r => r.outcomeValues).length > 0;
  return (
    <DrawerShell title={exp.name || 'Untitled experiment'} subtitle="Manage this experiment" onClose={onClose}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10, paddingBottom: 18 }}>
        {hasRuns && <ActionRow icon="share" tone="gold" label="Share best run" sublabel="Save its mix & ratings as an image" onClick={onShareBest} />}
        <ActionRow icon="edit" tone="neutral" label="Rename experiment" sublabel="Change its title" onClick={onRename} />
        <ActionRow icon="trash" tone="danger" danger label="Delete experiment" sublabel="Remove it and all its data" onClick={onDelete} />
      </div>
    </DrawerShell>
  );
}

// ── 5. Confirm delete (destructive) ──────────────────────
function ConfirmDeleteDrawer({ exp, onConfirm, onClose }) {
  const pc = (exp.parameters || []).length;
  const oc = (exp.outcomes || []).length;
  const rc = (exp.runs || []).length;
  const bits = [
    `${pc} parameter${pc === 1 ? '' : 's'}`,
    `${oc} outcome${oc === 1 ? '' : 's'}`,
    `${rc} run${rc === 1 ? '' : 's'}`,
  ];
  return (
    <DrawerShell onClose={onClose}
      title={<span>Delete <span style={{ fontStyle: 'italic' }}>“{exp.name || 'Untitled experiment'}”</span>?</span>}
      footer={
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Btn label="Delete experiment" icon="trash" variant="danger" onClick={onConfirm} />
          <Btn label="Keep it" variant="ghost" onClick={onClose} />
        </div>
      }>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', paddingTop: 4 }}>
        <Tile icon="alert" tone="danger" size={56} radius={18} stroke={2} />
        <div style={{ fontFamily: T.sans, fontSize: 14.5, color: T.inkSoft, lineHeight: 1.5, marginTop: 16, maxWidth: 300 }}>
          This permanently removes the experiment and everything in it. This can’t be undone.
        </div>
        <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'center', gap: 8, marginTop: 18 }}>
          {bits.map((b, i) => <Chip key={i} tone="soft">{b}</Chip>)}
        </div>
      </div>
      <div style={{ height: 8 }} />
    </DrawerShell>
  );
}

// ── 5b. Run actions sheet ────────────────────────────────
function RunActionsDrawer({ num, isBest, onShare, onRescore, onDelete, onClose }) {
  return (
    <DrawerShell title={`Run ${num}`} subtitle="Manage this run" onClose={onClose}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10, paddingBottom: 18 }}>
        <ActionRow icon="share" tone="gold" label="Share run" sublabel="Save its mix & ratings as an image" onClick={onShare} />
        <ActionRow icon="target" tone="violet" label="Rescore run" sublabel="Adjust the outcome ratings" onClick={onRescore} />
        <ActionRow icon="trash" tone="danger" danger label="Delete run" sublabel="Remove it from your history" onClick={onDelete} />
      </div>
    </DrawerShell>
  );
}

// ── 5c. Confirm delete of a run (destructive) ────────────
function ConfirmDeleteRunDrawer({ exp, run, num, isBest, onConfirm, onClose }) {
  const outcomes = runOutcomeDefs(exp, run);
  const ov = run.outcomeValues || {};
  const bits = outcomes
    .filter(o => ov[o.id] != null)
    .map(o => `${o.name} ${fmt(ov[o.id])}${o.unit ? ' ' + o.unit : ''}`);
  return (
    <DrawerShell onClose={onClose}
      title={<span>Delete <span style={{ fontStyle: 'italic' }}>Run {num}</span>?</span>}
      footer={
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Btn label="Delete run" icon="trash" variant="danger" onClick={onConfirm} />
          <Btn label="Keep it" variant="ghost" onClick={onClose} />
        </div>
      }>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', paddingTop: 4 }}>
        <Tile icon="trash" tone="danger" size={56} radius={18} stroke={2} />
        <div style={{ fontFamily: T.sans, fontSize: 14.5, color: T.inkSoft, lineHeight: 1.5, marginTop: 16, maxWidth: 312 }}>
          {isBest
            ? <span>This run is your current best. Deleting it removes it for good, and Mix Max will crown the next-highest run as best. This can’t be undone.</span>
            : <span>This permanently removes this run from your history. This can’t be undone.</span>}
        </div>
        {bits.length > 0 && (
          <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'center', gap: 8, marginTop: 18 }}>
            {bits.map((b, i) => <Chip key={i} tone="soft">{b}</Chip>)}
          </div>
        )}
      </div>
      <div style={{ height: 8 }} />
    </DrawerShell>
  );
}

// ── 6. Confirm delete of a parameter / outcome ───────────
// No "outdated" concept anymore: every past run keeps its own snapshot, so
// deleting just removes the item going forward. Incompatible runs stay in
// history, fully viewable — they simply stop tuning future runs.
function ConfirmDeleteItemDrawer({ target = 'parameter', runCount = 0, onConfirm, onClose }) {
  const hasRuns = runCount > 0;
  return (
    <DrawerShell onClose={onClose}
      title={<span>Delete this {target}?</span>}
      footer={
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Btn label={`Delete ${target}`} icon="trash" variant="danger" onClick={onConfirm} />
          <Btn label="Keep it" variant="ghost" onClick={onClose} />
        </div>
      }>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', paddingTop: 4 }}>
        <Tile icon="trash" tone="danger" size={56} radius={18} stroke={2} />
        <div style={{ fontFamily: T.sans, fontSize: 14.5, color: T.inkSoft, lineHeight: 1.5, marginTop: 16, maxWidth: 312 }}>
          {hasRuns
            ? <span>Nothing in your run history will change, but some or all past runs may stop being used to tune your next run.</span>
            : <span>This {target} will be removed from the experiment. There are no recorded runs, so nothing else is affected.</span>}
        </div>
      </div>
      <div style={{ height: 8 }} />
    </DrawerShell>
  );
}

Object.assign(window, { DrawerShell, NameDrawer, ParameterDrawer, OutcomeDrawer, AddParameterDrawer, AddOutputDrawer, ConfirmDeleteItemDrawer, Segmented, TextInput, ExperimentActionsDrawer, ConfirmDeleteDrawer, RunActionsDrawer, ConfirmDeleteRunDrawer });
