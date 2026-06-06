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
  { title: 'Amount', hint: 'grams', icon: 'bag', tone: 'sage', set: { name: 'Amount', type: 'number', unit: 'g', min: 0, max: 100 } },
  { title: 'Time', hint: 'minutes', icon: 'timer', tone: 'sage', set: { name: 'Time', type: 'duration', unit: 'minutes', min: 1, max: 10 } },
  { title: 'Temperature', hint: '°C', icon: 'ruler', tone: 'sage', set: { name: 'Temperature', type: 'number', unit: '°C', min: 0, max: 100 } },
  { title: 'On / Off', hint: 'a yes-no knob', icon: 'toggle', tone: 'sage', set: { name: '', type: 'toggle' } },
  { title: 'Pick one', hint: 'from a list', icon: 'list', tone: 'sage', set: { name: '', type: 'choice' } },
];

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

function AddParameterDrawer({ onSave, onClose }) {
  const [name, setName] = useState('');
  const [type, setType] = useState('number');
  const [unit, setUnit] = useState('');
  const [min, setMin] = useState('');
  const [max, setMax] = useState('');
  const [options, setOptions] = useState([]);
  const [items, setItems] = useState([]);

  const applyPreset = (p) => {
    const s = p.set;
    setType(s.type);
    if (s.name !== undefined) setName(s.name);
    setUnit(s.unit || '');
    setMin(s.min !== undefined ? String(s.min) : '');
    setMax(s.max !== undefined ? String(s.max) : '');
  };

  const ranged = type === 'number' || type === 'duration';
  const valid = name.trim() && (type !== 'choice' || options.length > 0) && (type !== 'order' || items.length > 1);

  const save = () => onSave({
    id: 'p' + Date.now(), name: name.trim(), type,
    unit: ranged && unit.trim() ? unit.trim() : undefined,
    min: ranged && min !== '' ? Number(min) : undefined,
    max: ranged && max !== '' ? Number(max) : undefined,
    options: type === 'choice' ? options : undefined,
    items: type === 'order' ? items : undefined,
  });

  return (
    <DrawerShell title="Add a parameter" subtitle="A knob Mix Max will learn to tune" onClose={onClose}
      footer={<Btn label="Save parameter" iconR="check" variant={valid ? 'ink' : 'disabled'} disabled={!valid} onClick={save} />}>

      <SubHead>Quick add</SubHead>
      <PresetRow presets={PARAM_PRESETS} onPick={applyPreset} />

      <SubHead>Name</SubHead>
      <TextInput value={name} onChange={setName} placeholder="e.g. Ounces of water" maxLength={50} />

      <SubHead>What kind of value?</SubHead>
      <TypePicker value={type} onChange={setType} />
      <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.inkFaint, marginTop: 8 }}>{PARAM_TYPES[type].blurb}</div>

      {/* progressive disclosure */}
      {ranged && (
        <div style={{ marginTop: 6 }}>
          <SubHead>Unit & range</SubHead>
          <TextInput value={unit} onChange={setUnit} placeholder="Unit — e.g. g, °C, ml" />
          <div style={{ height: 10 }} />
          <TwoCol>
            <TextInput value={min} onChange={setMin} placeholder="Min" type="number" align="left" />
            <TextInput value={max} onChange={setMax} placeholder="Max" type="number" align="left" />
          </TwoCol>
        </div>
      )}
      {type === 'toggle' && (
        <div style={{ marginTop: 16, display: 'flex', alignItems: 'center', gap: 12, background: T.surface, border: `1px solid ${T.hairline}`, borderRadius: T.rField, padding: '14px 16px' }}>
          <MiniSwitch on />
          <div style={{ fontFamily: T.sans, fontSize: 13.5, color: T.inkSoft }}>No range needed — it's simply on or off.</div>
        </div>
      )}
      {type === 'choice' && (<div style={{ marginTop: 6 }}><SubHead>Options</SubHead><ChipEditor items={options} setItems={setOptions} placeholder="Add an option" /></div>)}
      {type === 'order' && (<div style={{ marginTop: 6 }}><SubHead>Steps to sequence</SubHead><ChipEditor items={items} setItems={setItems} placeholder="Add a step" /></div>)}
      <div style={{ height: 6 }} />
    </DrawerShell>
  );
}

// ── 3. Add output ────────────────────────────────────────
const OUTPUT_PRESETS = [
  { title: 'Taste', hint: '1–10, higher', icon: 'spark2', tone: 'violet', set: { name: 'taste', min: 1, max: 10, step: 1, goal: 'maximize' } },
  { title: 'Quality', hint: '1–5, higher', icon: 'trophy', tone: 'violet', set: { name: 'quality', min: 1, max: 5, step: 1, goal: 'maximize' } },
  { title: 'Yield', hint: '%, higher', icon: 'up', tone: 'violet', set: { name: 'yield', unit: '%', min: 0, max: 100, step: 1, goal: 'maximize' } },
  { title: 'Time', hint: 'min, lower', icon: 'clock', tone: 'violet', set: { name: 'time', unit: 'min', min: 0, max: 60, step: 1, goal: 'minimize' } },
];

function AddOutputDrawer({ onSave, onClose }) {
  const [name, setName] = useState('');
  const [unit, setUnit] = useState('');
  const [goal, setGoal] = useState('maximize');
  const [min, setMin] = useState('1');
  const [max, setMax] = useState('10');
  const [step, setStep] = useState('1');

  const applyPreset = (p) => {
    const s = p.set;
    setName(s.name || ''); setUnit(s.unit || '');
    setGoal(s.goal); setMin(String(s.min)); setMax(String(s.max)); setStep(String(s.step));
  };
  const valid = name.trim();
  const save = () => onSave({
    id: 'o' + Date.now(), name: name.trim(),
    unit: unit.trim() || undefined,
    min: min !== '' ? Number(min) : undefined,
    max: max !== '' ? Number(max) : undefined,
    step: step !== '' ? Number(step) : 1,
    goal,
  });

  return (
    <DrawerShell title="Add an outcome" subtitle="What you'll measure after each run" onClose={onClose}
      footer={<Btn label="Save outcome" iconR="check" variant={valid ? 'ink' : 'disabled'} disabled={!valid} onClick={save} />}>
      <SubHead>Quick add</SubHead>
      <PresetRow presets={OUTPUT_PRESETS} onPick={applyPreset} />

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
        <div style={{ flex: 1 }}><TextInput value={step} onChange={setStep} placeholder="Step" type="number" /></div>
      </div>
      <div style={{ height: 6 }} />
    </DrawerShell>
  );
}

Object.assign(window, { DrawerShell, NameDrawer, AddParameterDrawer, AddOutputDrawer, Segmented, TextInput });
